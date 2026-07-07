---
name: revise
description: Run the full multi-stage review pipeline on the current branch — /review (multi-perspective subagents) → codex MCP → PR → Copilot/Gemini bots — fixing findings at each stage until convergence. Use when the user asks to "revise", run the review pipeline, or prepare a branch/PR for merge review.
---

# Revise: staged review pipeline until convergence

Goal: converge each stage BEFORE advancing, so the expensive/noisy late stages
(Copilot/Gemini PR bots) see an already-hardened diff and produce minimal
rounds. The local stages are where problems must die.

## Pipeline

1. **`/review`** (subagent-orchestrated multi-perspective review + fact-check).
   Repeat until no actionable findings.
2. **codex MCP server** review. Repeat (reply-to-continue on the SAME thread)
   until it answers "no comments to provide" — then request one FRESH review
   in a NEW session (no thread carryover) and converge that too.
3. **Create the PR** (or push to the existing one).
4. **Copilot** PR review. Fix/refute, re-request until a round produces zero
   new actionable comments.
5. **Gemini** (`/gemini review`). Same convergence rule. Run if repo is under
   https://github.com/atusy (Steps 4–5 can run as combined rounds: request
   both, wait for both, handle the union.)

## Universal rules (every stage)

- **One commit per fix item**, each passing the project's quality gate.
  Reference the finding (e.g. "Review finding M1") in the commit body.
- When a finding is fixed, **sweep for siblings**: the same bug class usually
  exists at the other call sites / the twin handler / the delta path when the
  full path was flagged.
- **Prefer the perf-optimal fix** over the correctness-minimal one when the
  finding touches performance.
- **Refute false positives with evidence, once** — "this compiles: CI green +
  clippy -D warnings + test X exercises this exact line" beats arguing theory.
  Then resolve/minimize the thread; do not rework correct code to appease a
  bot. If you keep something a reviewer wants removed (a backstop, a guard),
  say why in a code comment so the next round doesn't re-flag it.
- Report outcomes faithfully in thread replies: name the commit hash.

## Stage 1 — /review (kill everything here)

Invoke the `/review` command (orchestrator subagent + ~10 parallel
single-perspective reviewers + a fact-check pass that reads the actual code
before reporting). Give the orchestrator the branch, base, changed files, and
per-file perspective assignments.

Beyond the change-specific perspectives (concurrency, cancellation, caching,
protocol conformance…), ALWAYS include one reviewer running the
**bot-anticipation checklist** below — these are the classes Copilot/Gemini
reliably flag, and catching them locally is the whole point:

### Bot-anticipation checklist

- **Doc/comment drift**: any comment, doc-comment, ADR sentence, or test name
  that describes the OLD behavior after this diff changed it. Also claims that
  overstate ("never", "always", "bounded by X not wall time") vs what the code
  enforces (a `timeout_at` IS wall-clock; a "synchronous" forward that is a
  detached spawn).
- **Hot-path allocations**: key/`Url`/`String` clones on steady-state paths —
  `get`/`get_mut` before the `entry()` API (entry needs an owned key); clone
  only on the miss/insert path.
- **Hard-coded platform constants**: signal numbers, error codes, magic sizes.
  Use the platform/library constant, or extract a named const with a
  derivation comment.
- **Unreachable/forward-looking guards**: a check no current code path can
  trigger reads as a live safety net — either delete it or comment that it is
  deliberately forward-looking and why.
- **Double-check races in lock-free loops**: any check-then-claim sequence
  over two maps (memo check → in-flight claim) has a window where the other
  side completes in between; re-check inside the claim.
- **Split lock operations**: mutate-then-conditionally-remove on a concurrent
  map should be one atomic op (`remove_if_mut`-style) when the API offers it.
- **Cancellation granularity**: a cancel checkpoint "per phase" when the loop
  body inside the phase is the expensive unit → per-iteration checkpoint.
- **Test-contract mismatches**: tests that bypass the real key/fold/contract
  (raw hash where the API means a folded hash) — fix the test AND add the
  discriminating assertion (the wrong key must MISS).
- **Order-insensitive test fixtures**: if the bug being pinned is an
  index/pairing bug, the fixture must interleave, not append, or the old bug
  passes the test.

Fact-check discipline: every finding must be verified against the code at the
cited line before it reaches you; the orchestrator lists refuted findings so
you don't re-investigate them.

## Stage 2 — codex MCP

Call the codex tool with: branch + base, instruction to run `git diff
base...HEAD` AND read the actual files at HEAD, a summary of the change set,
and a note of what stage-1 already found/fixed ("you are the second
independent reviewer — look for what they missed"). Use `sandbox:
"read-only"`, `approval-policy: "never"`.

- Continue on the same thread with `codex-reply`: after fixing, reply with the
  commit hash + what changed + ask it to re-review and continue.
- When the thread answers **"no comments to provide"**, start a **fresh
  session** (a new `codex` call, no thread carryover): a continued thread is
  anchored to its own earlier findings and verifies your fixes rather than
  re-sweeping, so blind spots survive it. Prompt the fresh session as a
  first-time reviewer of the full diff (do NOT enumerate what earlier rounds
  found — that would re-anchor it; at most note the branch has been through
  local review so it hunts for what was missed).
- If the fresh session finds something: fix on that thread via reply-to-
  continue until clean, then fresh-session again. Converged when a FRESH
  session answers "no comments to provide" on its first response.
- codex findings are usually real (it reads code paths, not patterns) — expect
  design-level items like "this wait isn't observable by supersession" or
  "this policy leaks into the wrong request class".

## Stages 4–5 — PR bots

Mechanics (GitHub CLI):

- Copilot: `gh api repos/{owner}/{repo}/pulls/{n}/requested_reviewers -X POST
  -f 'reviewers[]=copilot-pull-request-reviewer[bot]'` (ignore misleading
  `gh pr edit` errors).
- Gemini: comment `/gemini review` on the PR.
- Wait by **polling reviews filtered to the HEAD commit SHA and bot logins**
  (a background `until` loop, ~30s interval). Your own replies also create
  reviews — filter authors, or you'll wake on yourself.
- Reply to every inline comment (`gh api .../comments/{id}/replies`), then
  resolve threads via GraphQL `resolveReviewThread` — unresolved threads get
  re-anchored onto every new commit and re-listed forever.
- Re-request both bots after each fix commit; converged when a round yields
  zero NEW actionable comments (re-anchored old threads don't count).

Bot triage priors (from experience):

- Gemini "critical/high" claims of **compile errors are usually
  hallucinations** (match ergonomics, `!Unpin` in `select!`) — refute with CI
  evidence, resolve, move on. But Gemini's concurrency-window findings on
  code you wrote in this session can be real — check before dismissing.
- Copilot is strongest on doc-vs-code mismatches and platform assumptions;
  its perf claims about serialization ("this deep-clones") often miss that
  one materialization is inherent to the wire format — refute with the
  before/after clone count.
- Never weaken a deterministic test to satisfy a bot's style preference
  (e.g. paused-clock `sleep` → `yield_now` makes park tests racy, not
  cleaner).

## Done

Converged = all stages passed with zero unresolved threads and CI green.
Report: rounds per stage, findings fixed (with commits), findings refuted and
why, and anything deliberately kept over a reviewer's objection.
