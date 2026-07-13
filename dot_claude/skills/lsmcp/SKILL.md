---
name: lsmcp
description: Query code semantics (symbols, hover, definitions, references, diagnostics) across any language via the lsmcp MCP server, which bridges through kakehashi to real language servers (lua_ls, basedpyright, rust_analyzer, r_language_server, nixd, …). Use when exploring or analyzing a codebase, finding/understanding symbols, or when the first project-wide search misses a language. Prefer these tools over Grep/Read for code analysis.
---

# lsmcp (via kakehashi)

`lsmcp` is an MCP server (`mcp__lsmcp__*`). It is an LSP *client* pointed at `kakehashi`, which routes each file to the real language server. So any language configured there (Lua, Python, Rust, R, Nix, Bash, TS, …) is queryable through one server.

## Core workflow

1. `mcp__lsmcp__get_project_overview` — structure + symbol statistics (build the index first; see below).
2. `mcp__lsmcp__search_symbols` — find a symbol by `name`/`query` (auto-creates the index on first use).
3. `mcp__lsmcp__get_symbol_details` — hover + definition + references for one symbol in a single call.

Per-position LSP tools also work through the bridge: `lsp_get_hover`, `lsp_get_definitions` (`includeBody: true` for the body), `lsp_find_references`, `lsp_get_document_symbols`, `lsp_get_diagnostics`, `lsp_rename_symbol`.

## ⚠️ Cold-start miss — the one gotcha to know

`search_symbols` / `get_project_overview` build the index in a **single fast pass**: they open every file once and ask its language server for symbols. A slow-to-start server (basedpyright, r_language_server) can miss that ~1s window and return nothing, so **its language is silently absent from the index** — even though the file is fine. This is a startup race, not a config error, and it is intermittent (only when the server is genuinely cold).

**Symptom:** a language you know is present shows 0 symbols in `get_project_overview`, or `search_symbols <known-name>` returns nothing, while `Read` shows the code is there.

**Fix — warm the server, then re-search:**
1. Open one file of the missing language directly: `mcp__lsmcp__lsp_get_document_symbols --relativePath <that-file>`. This forces the server to start; retry once or twice if it first returns empty (it warms within a few seconds).
2. Once that returns real symbols, run `search_symbols` again — the now-warm server answers and the symbols land in the index.

**If it still won't appear** (the empty result got cached), force a full rebuild — the published lsmcp exposes no `noCache` tool param, so clear the on-disk index and re-search:
```bash
rm -f <project>/.lsmcp/cache/symbols.db*
```
then call `search_symbols` again (with the server already warmed from step 1).

**Prevention (best):** in a known multi-language project, warm each language up front — call `lsp_get_document_symbols` on one representative file per language — *before* relying on `get_project_overview` / `search_symbols`. The first index is then built with every server warm and nothing is missed.

## Mid-session stalls on large single-language codebases

The cold-start miss above is about a server that never got its ~1s window at index-build time. A related but distinct failure shows up on a *large* codebase in one language (a 200+ file crate/project): a `documentSymbol`/`hover` call that worked a minute ago suddenly returns empty for several calls in a row.

**Cause:** the language server is running a heavy background full-workspace analysis (e.g. rust-analyzer's flycheck/`cargo check` across a big dependency graph) and answers empty rather than erroring while it's busy.

**Diagnose, don't just retry blindly:**
```bash
ps aux | grep -E '<language-server-binary>|kakehashi' | grep -v grep
```
Dev machines often have several kakehashi/language-server instances running at once (one per editor session) — find the child actually spawned by *this* session's kakehashi/lsmcp process before trusting its CPU state:
```bash
pgrep -P <this-session's-kakehashi-pid>
```
If that server child is alive and running (and, for compiled languages, its build subprocesses — `rustc`, `clang`, etc. — are still active), it's just busy: wait for the busy signal to clear, then retry once, rather than re-firing the same call repeatedly. Bare `sleep` is blocked in this harness — wait on a real condition instead, e.g.:
```bash
until ! pgrep -f "rustc --crate-name" >/dev/null 2>&1; do sleep 3; done
```
If the server process is simply gone, that's a real crash/restart, not a busy-wait — re-warm from scratch per the cold-start steps above.

## Bulk overview doesn't scale to large codebases

`get_symbols_overview` on a whole directory, and the initial `search_symbols`/`get_project_overview` indexing pass, do one rapid pass opening every matched file. Past roughly a couple hundred files (or one big single-crate/module codebase) this pass can time out per-file and come back **empty for most files** — and `get_project_overview`'s diagnostic counts become meaningless (e.g. reporting hundreds of spurious errors from a workspace that hasn't finished building).

**Prefer targeted calls for large codebases:** skip the directory-wide overview and call `lsp_get_document_symbols` on the handful of files that actually matter (entry points, core structs/coordinators) one at a time. Slower per file, but far more reliable than one bulk call that silently degrades.

## Other notes

- **`files` glob is required.** lsmcp only indexes files matched by its `files` pattern; the global config uses `**/*`. If you scope a project with `.lsmcp/config.json`, include every language's extension (or `**/*`) or those files are never indexed.
- **`lsp_get_workspace_symbols` is unsupported** through kakehashi (no `workspace/symbol`). Use `search_symbols` (own index) instead.
- **`get_project_overview` does not auto-index** in the published build — call `search_symbols` once (or warm as above) first, then the overview reflects the index.
