# PR-stage blind spots — what local review keeps missing

Evidence base: 1,648 bot review findings on atusy/kakehashi PRs (2026-06 →
2026-08) that were **accepted and fixed** after passing the local pipeline
(/review + codex MCP), plus 307 findings the author **refuted**. Goal: brief
stage-1 reviewers with these passes so the same classes die locally and the
PR stage converges in one round.

Share of the 1,648 misses by theme (approximate):

| Theme | Share |
|---|---|
| Doc/comment/prose drift & overstated guarantees | ~25% |
| Hot-path allocations, clones, redundant work | ~18% |
| Test quality (weak assertions, flakiness, hermeticity) | ~12% |
| Concurrency (lock scope, check-then-act, lifecycle races, cancellation) | ~12% |
| Error handling & reporting fidelity | ~8% |
| Untrusted input (traversal, log/ANSI injection, archive/TOCTOU) | ~6% |
| Filesystem/subprocess robustness | ~5% |
| Protocol (LSP) conformance, null-vs-empty | ~4% |
| Cross-platform portability | ~3% |
| UTF-8/coordinate boundary safety | ~2% |
| Unbounded growth & resource leaks | ~2% |
| Long tail (config semantics, naming, API hygiene…) | ~3% |

Key meta-lesson: the bots' edge was **breadth, not depth** — they swept every
changed line for mechanical classes (every comment, every log line, every
`clone()`), while holistic local review sampled. Assign the passes below as
*dedicated* single-perspective reviewers, each instructed to sweep the ENTIRE
diff for their class. When one instance of a pattern is found, sweep for all
siblings — near-identical findings repeatedly fanned out across files.

## Pass 1 — Doc/comment truth (largest class, ~25%)

Re-read every doc comment, inline comment, module header, ADR paragraph, test
name, README section, and the PR description that the diff touches OR sits
adjacent to. For each factual claim, verify against the current code:

- Named functions/fields/variables still exist (rustdoc intra-doc links
  resolve; `#[cfg(test)]`-gating a target breaks non-test doc builds).
- Described mechanism is the one used (which API/lock/CAS/shutdown variant).
- Return-type and error-semantics descriptions match (None vs Err; tuple
  shapes).
- Guarantee claims are not overstated: "zero-allocation", "lock-free",
  "always canonical", "client can't bypass X", "bounded by X not wall time" —
  state the actual condition and its exceptions.
- Comments justifying a strategy the diff just replaced; rationale whose
  premise changed.
- Referenced issue numbers and follow-up pointers still correct.
- PR description vs implementation contradictions (these repeatedly hid real
  ordering bugs — decide which is the source of truth and fix that side).
- Inclusive vs half-open range wording matches the code (tree-sitter spans
  are half-open).

Prose quality sub-pass (docs/ADRs): grammar, spelling-locale consistency,
terminology/casing consistency for domain terms, hard-wraps splitting
hyphenated words or bold spans across lines, fence language tags, bare ADR
slugs in prose (repo convention: markdown links only in Related Decisions),
stale time-relative wording, AI-generation leaks ("the prompt's …"),
copy-pasteable commands that actually parse.

ADR design completeness: every message named in a protocol sketch exists in
the contract with ack/failure semantics; failure budgets aren't consumable by
expected recovery paths; ordering rules stated; diagrams include
error-recovery transitions.

## Pass 2 — Hot-path performance (~18%)

Grep the diff for `clone(`, `to_string(`, `to_owned(`, `entry(`, `Vec::new`,
`HashMap::new`, `format!` on per-request / per-keystroke / per-region /
per-capture paths and justify each:

- `entry(key.clone())` where the entry usually exists → `get_mut(borrowed)`
  first, clone only on the miss/insert path. (Flagged across ≥6 modules.)
- Deep clones of `Arc<Vec<_>>` / cached `Value`s before knowing they'll be
  used; accessors returning cloned structs where `Arc<T>` works.
- `serde_json::from_value(v.clone())` → `Deserialize::deserialize(&v)`;
  string-formatted map keys when the typed key is already `Hash+Eq`.
- Allocations inside per-line/per-token loops → hoist + `clear()`;
  `with_capacity` when size is known; dense `Vec` indexed by absolute offsets
  explodes on sparse data — use local offsets.
- Repeated lookups/recompute: double map hits, loop-invariant lookups inside
  loops, the same expensive probe (capability check, root-marker walk) twice
  on one path, expensive logging not gated behind `log_enabled!`.
- Accidental O(n²): rebuilding a line index / `PositionMapper` per region
  instead of per document; linear scans the docs claim are binary search;
  whole-map `retain` to evict one key; JSON serialization inside sort
  comparators; loops bounded by malformed `u32::MAX` positions (`break`, not
  `continue`, when monotone).
- Independent downstream awaits run sequentially → `join_all` (with a cap).
- Cheap checks ordered after expensive ones.

Scope discipline: only flag paths that are actually hot (per-request or
hotter). Micro-optimizations on cold paths were a top *false-positive*
class — see triage section.

## Pass 3 — Concurrency interleavings (~12%, highest severity density)

For every async handler, lock, and stateful task in the diff, walk the
interleavings explicitly:

- **Lock scope**: no guard (`MutexGuard`, `StdoutLock`, pool/connections
  map) held across `.await` or blocking/CPU work; snapshot needed fields,
  drop, then await. `std::sync::Mutex` (not tokio) when nothing awaits under
  it. Watch `if let` temporaries extending guard lifetimes. Hoist lock
  acquisition out of await-free loops. Recover poisoning via the project's
  `recover_poison` with an accurate label.
- **Check-then-act**: any check separated from its act by an await or lock
  boundary → fold the check into the write's critical section (re-check
  inside the claim; double-check the cache inside the `Vacant` arm).
  Subscribe to `watch` channels *before* reading the latest value or a
  publish in the gap is lost forever. Verify atomic orderings actually give
  the claimed happens-before; prefer `fetch_update` over raw
  `compare_exchange` retries; DashMap get-then-insert loses updates — use
  `entry().or_insert_with`.
- **Lifecycle races**: for every task keyed by a document/connection, ask
  what happens if didChange / didClose / respawn / shutdown interleaves.
  Re-validate after each await (document still open, handle still live via
  `Arc::ptr_eq` under the lock, incarnation/generation checked at *read*
  time). No resurrection of per-URI state after `remove()`. Every early-exit
  path (shutdown, panic guard, timeout) clears scheduler/registry entries so
  a later schedule can respawn — a stale `parsing: true` flag is a permanent
  wedge. First-writer-wins registries must survive respawn under a new key.
- **Cancellation**: dropping a timed-out future is NOT cancellation — the
  downstream keeps computing; send `$/cancelRequest` explicitly, and
  remember `spawn_blocking` ignores dropped JoinHandles. Cancel must map to
  `-32800 RequestCancelled`, never `Ok(None)` or `-32603`. Cancel
  subscriptions set up before the first await; select-on-cancel arms must
  unregister what the dropped future registered (or use an RAII sweep
  guard). Per-iteration cancel checkpoints inside expensive loops. Fan-out
  sharing one upstream id: cancel must hit the right subset.
- **Progress/token lifecycles**: create-before-progress, exactly one
  Begin/End per token, tokens removed on connection death or the admission
  set leaks.

## Pass 4 — Error-path audit (~8%)

Audit every discarded or coarsened `Result` in the diff:

- `let _ =`, `.ok()`, `unwrap_or(false)`, `.is_ok()`, `entries.flatten()`,
  `Path::exists()` (false on PermissionDenied!) — tolerate only the specific
  benign `ErrorKind`, propagate or log the rest.
- Nested `Result<Result<_>>`: match explicitly; a timeout wrapper that only
  checks the outer layer treats inner panics/JoinErrors as success.
- Real errors mapped into "not found"/no-op/success (URL-conversion failure
  reported as "unchanged"); conversely benign cases (`AlreadyExists`)
  reported as hard failure.
- Half-applied effects: never send a half-translated message (URI translation
  failed but ranges translated); don't mutate shared state before the
  fallible operation succeeds.
- Messages actionable: include the failing path/entry/server; preserve the
  underlying error and the *primary* error's `ErrorKind` (not the
  rollback's); no fabricated cause attribution ("editor did not answer" when
  the request was never sent); right level; bounded (one warn per event, not
  per item); consistent singular/plural and no duplicated prefixes.

## Pass 5 — Test quality (~12%; the pipeline reviewed code, not tests)

For every new/changed test, ask: **what breakage still passes this test?**

- Substring assertions with prefix ambiguity (`matched=1` matches
  `matched=10`); assertions that cannot fail (single-variant
  `mem::discriminant`, emptiness that holds for the wrong reason); `Option`
  paths that no-op the assertion; asserting one half of a two-part contract;
  missing `status.success()` + stderr checks on subprocesses; JSON-RPC
  `error` not checked before indexing `result`; polling loops that silently
  retry on error responses.
- Fixtures must exercise the claimed distinction: ASCII fixtures can't pin
  UTF-16-vs-byte bugs; append-only fixtures can't pin index/pairing bugs
  (interleave); cover the co-fixed variant (CRLF, cleanup path, error case).
- Determinism: no fixed sleeps or spin windows — use handshake channels,
  observable state, `start_paused = true` + virtual time, `yield_now` only
  on current-thread runtimes; bound every blocking read with a timeout;
  await aborted JoinHandles so panics surface.
- Hermeticity: per-spawn (not per-process) state dirs — Rust tests share one
  process; `env_remove` feature flags in the "disabled" branch; no fixed
  shared temp paths with stale contents; one `log::set_logger` per process;
  skip-guards for environment-dependent tools, probing the exact capability
  used; `#[cfg(unix)]` on tests spawning `sh`/`sleep`.
- Shared test helpers: merge capability objects, don't overwrite; keep
  helper predicates in sync with production via the shared helper.
- A stated contract change with no regression test at all is a finding.

## Pass 6 — Untrusted input & injection (~6%)

- Any externally influenced name used as a path or URL segment: validate
  against the safe charset at **every public entry point** (not just one
  inner helper, not just one of clone/archive paths); `../../x` in a
  language name escapes the data dir.
- Archives/cloned repos are adversarial: reject absolute / `Prefix` /
  `RootDir` entry paths (`PathBuf::join` drops the base — checking only
  `..` is not enough), Windows reserved names, symlink swaps between
  `symlink_metadata` and open (use `O_NOFOLLOW`); per-entry byte caps;
  bounded recursion.
- Self-generated on-disk names are untrusted on re-read: parse them back
  with exactly the generator's value range (PID 1..=i32::MAX) so lookalike
  user files are never deleted; `symlink_metadata`, not `metadata`, when
  inspecting managed trees; re-validate after any prompt/lock gap (TOCTOU).
- Terminal/log injection: any config-, client-, or server-controlled string
  interpolated with `{}` into logs/errors can inject ANSI/control chars —
  use `{:?}`/`escape_debug`, covering U+007F too.
- Client-supplied round-tripped data (`action.data` envelopes) must not
  bypass validation gates; enforce documented preconditions in the function
  itself.

## Pass 7 — Filesystem & subprocess robustness (~5%)

- Best-effort cleanup/scan paths tolerate races: `NotFound` between
  read_dir/stat/read/remove is benign; one broken entry must not abort the
  sweep; strict-vs-best-effort is a deliberate, consistent choice.
- Validate before side effects: input validation precedes lock-file/dir
  creation; recovery sweeps run before "already exists" early returns; an
  invalid invocation leaves the filesystem untouched.
- Multi-step transactions: reason about the end state of every failure
  branch — never fail when the desired end state is already achieved; never
  roll back a successful publish because ancillary cleanup failed; fsync
  the parent dir if you claim atomic durability; unique temp names within a
  process (PID alone is constant).
- Subprocess lifecycle: failed compiles must not leave a partial artifact
  that existence-checks treat as valid; `killpg(0)` after a failed `setpgid`
  kills your own group; bound post-kill waits; every pipe read/`wait()`
  needs a timeout with kill-on-expiry; cleanup in `try/finally`; catch
  `OSError`, not just `BrokenPipeError`; non-daemon reader threads joined
  without timeout hang when a descendant inherits the fd.
- Losing a pooled permit on an error path is an eventual deadlock.

## Pass 8 — Protocol conformance (LSP) (~4%)

- Null vs empty vs absent, per method: for formatting, `null` and `[]` both
  mean "no edits" and stop fallback; empty-but-shaped results
  (`CompletionList{items:[]}`) must NOT win preferred dispatch and mask real
  results; normalize `documentChanges: Some([])` to `None` or
  version-differing clients no-op; explicit `null` differs from omitted.
- UTF-16 is the mandatory assumed position encoding — don't reject clients
  omitting it, don't announce it without checking the offered list.
- Header parsing: any order, extra headers, case-insensitive names.
- `didSave` includes `text` iff `includeText: true`; dynamic registration
  overrides static; full enum ranges (`MessageType.Debug = 5`); `"range":
  null` = full-text change; non-object `params` must not panic (`get`, not
  `Index`); advertise every capability a new handler depends on
  (`applyEdit`), or it's unreachable with conforming servers.
- Don't overwrite server-provided fields on resolve (title,
  `disabled.reason`); translate every coordinate-bearing field back to host
  space, including diagnostics on disabled actions.

## Pass 9 — Boundaries, encoding, coordinates (~2%, high severity)

- Never slice `&text[a..b]` with arithmetic-derived offsets: snap with
  `floor/ceil_char_boundary` (inward: ceil start, floor end), or `str::get`;
  handle start>end; keep derived `Point`s consistent with adjusted bytes.
- LSP `character` is UTF-16 code units; overlap filters need full-range
  checks, not `range.start` only; `<` vs `<=` at zero-width cursor
  positions; `checked_add`/`saturating_sub` where stale metadata can wrap —
  release-mode wraparound defeats "degrade, don't panic".
- Virtual-document fidelity: per-line column offsets for every line, not
  just line 0; masking vs stripping changes indentation semantics;
  same-range multi-language layers need deterministic selection or edits
  overlap.

## Pass 10 — Portability, growth, config, hygiene (long tail)

- **Portability**: `#[cfg]`-split features verified on the *other* platform
  (Windows exit code 259 = STILL_ACTIVE; `rename` onto existing fails;
  no-op lock inheritance breaking a documented invariant); tests spawning
  Unix tools gated; TOML basic strings corrupt `C:\` paths (literal
  strings); `.exe`/quoted-path handling; `encoding="utf-8"` in Python
  `open()`; platform/library constants instead of magic numbers
  (`libc::SIGTERM`, not 15); no `AtomicU64` where 32-bit matters; quote
  interpolated paths in shell (`pkill -f` with unescaped metachars).
- **Unbounded growth**: every insert-only map/vec/buffer needs a removal
  path, bound, or startup sweep (per-URI generation maps retaining closed
  documents; `created_tokens` shrinking only on End; unbounded channels fed
  by noisy notifications with a slow consumer; `strong_count`-conditional
  removal with no retry = permanent leak).
- **Config semantics**: every documented knob honored on every path
  (`maxFanOut = 0` truly disables); deterministic, specificity-aware
  selection (exact beats wildcard, no HashMap-order dependence); enumerate
  real client payload shapes (wrapped/flat/whole-editor-config/null) —
  unknown-key warnings fire on exactly the dropped keys; empty env var ≠
  set; canonical-form comparison before dedup (paths, URIs); `None` vs
  `Some(vec![])` distinction preserved.
- **Nondeterminism**: never iterate a HashMap into client-visible output.
- **API/naming hygiene**: names that contradict their role (`_`-prefixed
  but used; narrower name than the value); `&T` over `&Arc<T>`; parameters
  every caller passes identically; preconditions encoded in signatures, not
  comments; duplicated predicates/comparators that will drift → shared
  helper; hand-rolled parsers: enumerate malformed inputs (unclosed braces,
  fields with spaces, scientific notation, overlapping edits, 0/1-element
  statistics).

## Triage: bot false positives at the PR stage (307 refuted)

When the PR stage does run, ~16% of bot findings were noise. Fast triage by
class (all rebutted once, with evidence, then resolved — never reworked):

- **Phantom compile errors** (Gemini/Copilot): "this won't compile" against
  code CI already built — disjoint partial moves, temporary lifetime
  extension, autoref. Green `clippy -D warnings` on the exact commit is a
  decisive rebuttal.
- **Stale dependency API knowledge**: hallucinated crate signatures
  (tower-lsp, windows-sys `HANDLE`, dashmap). Rebut with crate source
  file:line at the locked version.
- **Stability/MSRV fear**: let-chains "unstable", "raises MSRV" — repo
  tracks latest stable, edition 2024 floor; cite stabilization version +
  existing usage count.
- **Blocking-IO-in-async dogma**: sync fs/stdio in the one-shot CLI batch
  paths is deliberate; critical path is the LSP round-trip.
- **Lock-across-await speculation**: pattern-matched without tracing that
  the awaits are non-yielding `try_send`s or that the hold IS the
  correctness mechanism; answer with the traced path + lock-order invariant.
- **Guard exists at another layer**: name the exact function/Drop
  impl/pinning test that provides the guarantee.
- **Repo-convention inversion**: bots demand ADR slug links, Superseded
  stubs, `log::` over `eprintln!` — all inverted by documented repo
  conventions; cite `docs/architecture-decisions/template.md` or the ADR.
  Gemini's "memory" re-cites its own wrong convention as authority.
- **Documented-tradeoff relitigated** (largest FP class): deliberate,
  ADR-recorded decisions flagged as bugs. Point at the ADR/issue; often the
  right fix is *adding* a code comment so the next round doesn't re-flag.
- **Out-of-scope in a stacked PR** (mostly Qodo): cite the stack plan/issue.
- **Spec misreading**: quote the LSP spec text directly.
- **Misread code/arithmetic**: byte-exact recount or a mini-test.
- **Cold-path micro-optimizations**: quantify path temperature; name what
  the "redundant" op is semantically doing.
- **Prose-truth mismatch**: code is the source of truth — fix the PR
  description, not the implementation (when that's the deliberate side).
- **Test-design second-guessing**: flakiness predictions ignoring the
  actual runtime model (current-thread runtime makes `yield_now`
  deterministic).
- **Timing artifacts** (~17% of refuted): finding anchored to a pre-fix
  commit. Reply "Already addressed in `<sha>` (review raced the push)" and
  resolve. If the same bot re-reports a refuted claim, resolve by reference
  to the prior refutation.
