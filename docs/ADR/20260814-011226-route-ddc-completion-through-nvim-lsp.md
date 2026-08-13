# Route DDC Completion Through Neovim LSP Clients

| | |
|---|---|
| **Status** | proposed |
| **Date** | 2026-08-14 |
| **Decision-makers** | atusy |
| **Consulted** | Codex |
| **Informed** | Neovim configuration maintainers and ddc-source-nvim-lsp users |

## Context and Problem Statement

The Neovim configuration currently combines `ddc-source-lsp` with separate
ddc sources for command-line language completion, built-in command completion,
expression input, and command-line history. This duplicates client integration
and completion-item handling across plugins and prevents source-level selection
of the Neovim LSP clients that should contribute candidates.

## Decision Drivers

* Completion sources should use Neovim's built-in LSP client as their single
  client boundary.
* Users must be able to allow or deny exact Neovim LSP client names, with deny
  taking precedence.
* Normal-buffer completion must retain resolve, snippet, additional-edit,
  preview, and command behavior.
* Command-line completion must retain its one-line editing and completion
  position contracts without corrupting the command line, with synchronous
  requests bounded by the configured timeout until async delivery is validated
  for ddc's command-line gather lifecycle.
* CMD, INPUT, and HIST candidates must retain independent marks, filters,
  ordering, caches, and replacement ranges during migration.
* The migration must be independently reversible at each source boundary.

## Considered Options

1. Fork `ddc-source-lsp`, specialize it for nvim-lsp, and provide separate
   normal and command-line adapters backed by shared primitives.
2. Keep the existing independent ddc sources and add allow/deny filtering only
   to `ddc-source-lsp`.
3. Return language-aware, command, input, and history candidates from one
   command-line LSP response and distinguish them only by completion item data.

## Decision Outcome

**Chosen option**: "Use a specialized fork with separate normal and
command-line adapters", because it provides one Neovim client boundary while
preserving the materially different item-application and completion-position
contracts of buffers and command lines.

The fork is named `atusy/ddc-source-nvim-lsp`. Its public ddc sources are
`nvim-lsp` and `nvim-lsp-cmdline`. The latter is aliased for CMD, INPUT, and
HIST presentation so each alias retains independent ddc options and cache
identity.

The chezmoi-managed configuration supplies an in-process Lua LSP transport for
each of `nvim-cmdline`, `nvim-input`, and `nvim-cmdline-history`. Each ddc alias
uses a distinct language ID and scratch URI, so Neovim attaches and reuses the
matching client independently. Language-aware command-line clients use the
same scratch-buffer mechanism with their own language IDs. Completion requests
carry immutable command-line type metadata and use the synchronized scratch
document snapshot.

`allowedServers` and `deniedServers` match exact, case-sensitive
`vim.lsp.Client.name` values. Both default to `null`. An empty allow list
selects no clients, an empty deny list denies none, and deny wins on overlap.
These parameters cannot name language servers hidden below kakehashi's single
Neovim client; downstream routing remains kakehashi's responsibility.

### Consequences

**Positive:**
* Normal and command-line completion share nvim-lsp client discovery, encoding,
  and server-filtering contracts.
* Users can isolate local command, input, and history providers with the same
  server-selection contract used for ordinary LSP clients.
* Each legacy source can be replaced and rolled back independently.
* The local providers can call Neovim state directly without an external
  process or a second editor protocol.

**Negative:**
* The fork intentionally drops vim-lsp and lspoints support.
* The command-line adapter and scratch controller retain lifecycle complexity
  that does not exist for ordinary buffers.
* Three logical local clients are required to preserve ddc source identity.
* Command-line completion uses `Client:request_sync()` and can block Neovim for
  up to the configured source timeout. Normal-buffer completion remains async
  and propagates ddc cancellation to `Client:cancel_request()`.

**Neutral:**
* Neovim client filters see `kakehashi`, not its downstream server names.
* TypeScript remains responsible for ddc item conversion, while Lua owns
  Neovim RPC and state-backed completion providers.

### Confirmation

The decision is confirmed when:

* Deno tests cover normal and command-line item conversion, UTF-8/16/32
  positions, server filtering, deny precedence, resolve, normal-request
  cancellation, and immutable command-line request metadata.
* MiniTest runs the Lua RPC and scratch-buffer lifecycle in headless Neovim,
  including attach, reuse, unload, wipe, local RPC cancellation, at-most-once
  reply notification, and the synchronous command-line timeout boundary.
* A Deno configuration test locks the source order for every configured
  command type, while headless integration proves the three local client
  identities attach, reuse, and return isolated results.
* Normal-buffer and skkeleton completion use `nvim-lsp` without references to
  the old source.
* The live chezmoi-applied configuration contains none of the six superseded
  completion plugins.
* Both repository branches pass the revise review pipeline and their public PR
  checks have no unresolved actionable findings.

## Pros and Cons of the Options

### Specialized fork with separate adapters

* Good, because nvim-lsp is the only client implementation this configuration
  needs.
* Good, because shared request primitives do not require shared insertion
  semantics.
* Good, because source aliases preserve user-visible completion boundaries.
* Bad, because the fork must track selected upstream completion-item changes.
* Bad, because scratch-buffer ownership and the synchronous command-line
  request boundary need dedicated tests.

### Keep independent ddc sources

* Good, because each existing source already implements its narrow contract.
* Good, because it minimizes immediate migration work.
* Bad, because it preserves duplicated integration and separate maintenance.
* Bad, because built-in sources do not exercise the desired LSP boundary.

### One mixed command-line response

* Good, because it uses one LSP client and one completion request.
* Good, because it minimizes the number of aliases in configuration.
* Bad, because ddc selects completion position and applies filters per source,
  before candidates can be separated by completion item data.
* Bad, because CMD, INPUT, and HIST marks, ordering, caches, and replacement
  semantics would become coupled.

## More Information

The implementation is tracked by `__ignored/plan.md` in the primary chezmoi
worktree. The ADR will become accepted only after the legacy dependencies are
removed, the live configuration is applied, and the revise pipeline converges.
