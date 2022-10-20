;; extends
(fenced_code_block
 (info_string
   (language) @lang)
 (code_fence_content) @content
 (#vim-match? @lang "^(py|python)(:.*)?$")
 (#set! language "python")
)
