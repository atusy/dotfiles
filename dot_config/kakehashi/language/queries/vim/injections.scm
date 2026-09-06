;; extends
; fish's `program` rule requires every statement to end in a terminator
; (";", "&", or a newline: https://github.com/ram02z/tree-sitter-fish
; grammar.js `_terminator`). vim's `command` node never includes one (the
; trailing newline is consumed by a hidden `_cmd_separator`), so without
; `#offset!` fish's top-level `command` node fails to close and most of its
; highlights.scm patterns (e.g. `name: (word) @function.call`) never match —
; only self-delimiting tokens like quoted strings survive. `command` also has
; named children (filter_command/command_argument), so capturing the whole
; node needs `injection.include-children` or kakehashi otherwise injects only
; the gaps between them.
((bang_filter_statement
   (command) @injection.content)
  (#set! injection.language "fish")
  (#set! injection.include-children)
  (#offset! @injection.content 0 0 0 1))

; kakehashi and its fish_lsp child start with DDCVIM set, so config.fish maps
; these Vim commands to their native commands. Inject the complete command so
; fish can resolve the aliases and provide native argument completion. Keep
; commands with arguments unmodified so cmdline completion stays at the real
; caret. A command ending in whitespace needs a separate one-column offset:
; Vim excludes trailing whitespace from user_command, otherwise the caret after
; `Gin ` or `Gin commit ` falls outside the injected range and never reaches
; fish completion.
((user_command
   (command_name) @_command
   (arguments)) @injection.content
  (#any-of? @_command "Gin" "GinBuffer")
  (#set! injection.language "fish")
  (#set! injection.include-children))

((script_file
   (user_command
     (command_name) @_command) @injection.content) @_cmdline
  (#match? @_cmdline "^(Gin|GinBuffer).*[[:blank:]][[:space:]]$")
  (#set! injection.language "fish")
  (#set! injection.include-children)
  (#offset! @injection.content 0 0 0 1))

((unknown_builtin_statement
   (unknown_command_name) @_command) @injection.content
  (#eq? @_command "lmake")
  (#set! injection.language "fish")
  (#set! injection.include-children))
