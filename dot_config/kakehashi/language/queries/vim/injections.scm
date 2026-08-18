; Based on tree-sitter-grammars/tree-sitter-vim's queries/vim/injections.scm
; (as vendored by kakehashi's autoInstall), extended with a fish injection
; for `:h filter` shell commands introduced by `!`, optionally preceded by a
; range (`!cmd`, `.!cmd`, `%!cmd`, `1,10!cmd`, `1!!cmd`, ...).
;
; This file fully shadows the auto-installed queries/vim/injections.scm, so
; it must stay a superset of it.

(lua_statement
  (script
    (body) @injection.content
    (#set! injection.language "lua")))

(lua_statement
  (chunk) @injection.content
  (#set! injection.language "lua"))

(ruby_statement
  (script
    (body) @injection.content
    (#set! injection.language "ruby")))

(ruby_statement
  (chunk) @injection.content
  (#set! injection.language "ruby"))

(python_statement
  (script
    (body) @injection.content
    (#set! injection.language "python")))

(python_statement
  (chunk) @injection.content
  (#set! injection.language "python"))

; If we support perl at some point...
; (perl_statement (script (body) @perl))
; (perl_statement (chunk) @perl)
(autocmd_statement
  (pattern) @injection.content
  (#set! injection.language "regex"))

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

((set_item
  option: (option_name) @_option
  value: (set_value) @injection.content)
  (#any-of? @_option
    "includeexpr" "inex" "printexpr" "pexpr" "formatexpr" "fex" "indentexpr" "inde" "foldtext" "fdt"
    "foldexpr" "fde" "diffexpr" "dex" "patchexpr" "pex" "charconvert" "ccv")
  (#set! injection.language "vim"))

((comment) @injection.content
  (#set! injection.language "comment"))
