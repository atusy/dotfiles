;; extends
(
  string
  (string_content) @injection.content
  (#vim-match? @injection.content "^https://github\\.com/[^/]+/[^/]+$")
  (#set! injection.language "uri")
)
