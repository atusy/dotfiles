; nvim-treesitter's queries/nix/injections.scm, with each comment pattern
; limited to its own comment style. Both used to match every comment, and the
; `/* … */` pattern's #gsub! leaves `# bash` as is, so a `# bash` comment
; injected a bogus `# bash` language over the same string as `bash`. Neovim
; drops an injection without a parser; kakehashi bridges it (tsudoi takes
; every language), which shadowed bashls when formatting.
; Not `;; extends`: this replaces the downloaded query, so it must come
; before ${KAKEHASHI_DATA_DIR} in searchPaths.

((comment) @injection.content
  (#set! injection.language "comment"))

((comment) @injection.language
  . ; this is to make sure only adjacent comments are accounted for the injections
  [
    (string_expression
      (string_fragment) @injection.content)
    (indented_string_expression
      (string_fragment) @injection.content)
  ]
  (#lua-match? @injection.language "^/%*")
  (#gsub! @injection.language "/%*%s*([%w%p]+)%s*%*/" "%1")
  (#set! injection.combined))

; #-style Comments
((comment) @injection.language
  . ; this is to make sure only adjacent comments are accounted for the injections
  [
    (string_expression
      (string_fragment) @injection.content)
    (indented_string_expression
      (string_fragment) @injection.content)
  ]
  (#lua-match? @injection.language "^#")
  (#gsub! @injection.language "#%s*([%w%p]+)%s*" "%1")
  (#set! injection.combined))

(apply_expression
  function: (_) @_func
  argument: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "regex")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "regex")))
  ]
  (#lua-match? @_func "^%a*%.*match$")
  (#set! injection.combined))

(binding
  attrpath: (attrpath
    (identifier) @_path)
  expression: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "bash")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "bash")))
  ]
  (#lua-match? @_path "^%a+Phase$")
  (#set! injection.combined))

(binding
  attrpath: (attrpath
    (identifier) @_path)
  expression: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "bash")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "bash")))
  ]
  (#lua-match? @_path "^pre%a+$")
  (#set! injection.combined))

(binding
  attrpath: (attrpath
    (identifier) @_path)
  expression: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "bash")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "bash")))
  ]
  (#lua-match? @_path "^post%a+$")
  (#set! injection.combined))

(binding
  attrpath: (attrpath
    (identifier) @_path)
  expression: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "bash")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "bash")))
  ]
  (#lua-match? @_path "^script$")
  (#set! injection.combined))

(apply_expression
  function: (_) @_func
  argument: (_
    (_)*
    (_
      (_)*
      (binding
        attrpath: (attrpath
          (identifier) @_path)
        expression: [
          (string_expression
            ((string_fragment) @injection.content
              (#set! injection.language "bash")))
          (indented_string_expression
            ((string_fragment) @injection.content
              (#set! injection.language "bash")))
        ])))
  (#lua-match? @_func "^%a*%.*writeShellApplication$")
  (#lua-match? @_path "^text$")
  (#set! injection.combined))

(apply_expression
  function: (apply_expression
    function: (apply_expression
      function: (_) @_func))
  argument: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "bash")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "bash")))
  ]
  (#lua-match? @_func "^%a*%.*runCommand%a*$")
  (#set! injection.combined))

((apply_expression
  function: (apply_expression
    function: (_) @_func)
  argument: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "bash")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "bash")))
  ])
  (#lua-match? @_func "^%a*%.*writeBash%a*$")
  (#set! injection.combined))

((apply_expression
  function: (apply_expression
    function: (_) @_func)
  argument: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "bash")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "bash")))
  ])
  (#lua-match? @_func "^%a*%.*writeDash%a*$")
  (#set! injection.combined))

((apply_expression
  function: (apply_expression
    function: (_) @_func)
  argument: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "bash")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "bash")))
  ])
  (#lua-match? @_func "^%a*%.*writeShellScript%a*$")
  (#set! injection.combined))

((apply_expression
  function: (apply_expression
    function: (_) @_func)
  argument: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "fish")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "fish")))
  ])
  (#lua-match? @_func "^%a*%.*writeFish%a*$")
  (#set! injection.combined))

((apply_expression
  function: (apply_expression
    function: (apply_expression
      function: (_) @_func))
  argument: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "haskell")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "haskell")))
  ])
  (#lua-match? @_func "^%a*%.*writeHaskell%a*$")
  (#set! injection.combined))

((apply_expression
  function: (apply_expression
    function: (_) @_func)
  argument: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "javascript")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "javascript")))
  ])
  (#lua-match? @_func "^%a*%.*writeJS%a*$")
  (#set! injection.combined))

((apply_expression
  function: (apply_expression
    function: (_) @_func)
  argument: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "perl")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "perl")))
  ])
  (#lua-match? @_func "^%a*%.*writePerl%a*$")
  (#set! injection.combined))

((apply_expression
  function: (apply_expression
    function: (_) @_func)
  argument: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "python")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "python")))
  ])
  (#lua-match? @_func "^%a*%.*writePy%a*%d*%a*$")
  (#set! injection.combined))

((apply_expression
  function: (_) @_func
  argument: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "rust")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "rust")))
  ])
  (#lua-match? @_func "^%a*%.*writeRust%a*$")
  (#set! injection.combined))

; (runTest) testScript
(apply_expression
  function: (_) @_func
  argument: (_
    (_)*
    (_
      (binding
        attrpath: (attrpath) @_func_name
        expression: (_
          (string_fragment) @injection.content
          (#set! injection.language "python")))
      (#eq? @_func_name "testScript")
      (#lua-match? @_func "^.*%.*runTest$")
      (#set! injection.combined))))

; (nixosTest) testScript
(apply_expression
  function: (_) @_func
  argument: (_
    (_)*
    (_
      (binding
        attrpath: (attrpath) @_func_name
        expression: (_
          (string_fragment) @injection.content
          (#set! injection.language "python")))
      (#eq? @_func_name "testScript")
      (#lua-match? @_func "^.*%.*nixosTest$")
      (#set! injection.combined))))

; home-manager Neovim plugin config
(attrset_expression
  (binding_set
    (binding
      attrpath: (attrpath) @_ty_attr
      (_
        (string_fragment) @_ty)
      (#eq? @_ty_attr "type")
      (#eq? @_ty "lua"))
    (binding
      attrpath: (attrpath) @_cfg_attr
      (_
        (string_fragment) @injection.content
        (#set! injection.language "lua"))
      (#eq? @_cfg_attr "config")))
  (#set! injection.combined))
