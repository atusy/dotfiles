# Anchor Git Commit Buffers to Their Repositories

| | |
|---|---|
| **Status** | proposed |
| **Date** | 2026-08-13 |
| **Decision-makers** | atusy |
| **Consulted** | Codex |
| **Informed** | Neovim configuration maintainers |

## Context and Problem Statement

The custom commit UI opens a `gitcommit` buffer under the system temporary directory. Tsudoi therefore cannot infer the repository from the document URI and falls back to the language-server process working directory, while commit and history commands separately depend on Neovim's mutable working directory.

## Decision Drivers

* Completion, history, and commit execution must target the repository that opened the UI.
* Changing Neovim's working directory while the UI is open must not change the target repository.
* Linked worktrees must not depend on `.git` being a directory.
* The commit message remains an unsaved transient buffer.

## Considered Options

1. Capture the repository root once, use a root-local transient buffer name, and pass the root explicitly to Git commands.
2. Open Git's actual `COMMIT_EDITMSG` path.
3. Keep the system temporary file and let tsudoi choose a workspace or process working directory.

## Decision Outcome

**Chosen option**: "Capture and propagate the repository root", because the buffer URI then carries repository identity to LSP while one immutable root also removes ambient working-directory state from Git commands.

### Consequences

**Positive:**
* Tsudoi can resolve the repository from the document location.
* Completion and commit execution keep targeting the same repository after cwd changes.
* The design works when a linked worktree uses a `.git` file.

**Negative:**
* The Lua commit helpers must accept and propagate an additional root value.
* Tsudoi performs one `git rev-parse` when completing a root-local commit buffer.

**Neutral:**
* The buffer has a repository-local name but is still never written as a file.

### Confirmation

Automated tests must show that a root-local `gitcommit` URI resolves repository history, that the generated buffer name is under the captured root, and that commit/history commands receive that root as `cwd`.

## Pros and Cons of the Options

### Capture and propagate the repository root

* Good, because repository identity is explicit and stable for the lifetime of the UI.
* Good, because it supports ordinary repositories and linked worktrees uniformly.
* Bad, because both Lua and TypeScript need small coordination changes.

### Open Git's actual `COMMIT_EDITMSG` path

* Good, because Git already defines the path.
* Bad, because editing Git's real metadata file can collide with other Git operations.
* Bad, because the git-dir path alone does not reliably identify a linked worktree root.

### Use workspace or process cwd fallback

* Good, because it requires little code.
* Bad, because multi-root sessions and cwd changes can silently select the wrong repository.

## More Information

Implementation spans `dot_config/nvim/lua/plugins/git/commit.lua` and `dot_config/tsudoi-language-server/gitcommit.ts`.
