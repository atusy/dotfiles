;; extends
(fenced_code_block
 (info_string
   (language) @lang)
 (code_fence_content) @content
 (#vim-match? @lang "^(py|python)(:.*)?$")
 (#set! language "python")
)
(fenced_code_block
 (info_string
   (language) @lang)
 (code_fence_content) @content
 (#vim-match? @lang "^r,$")
 (#set! language "r")
)
((html_block) @injection
  (#set! "lang" "html"))
