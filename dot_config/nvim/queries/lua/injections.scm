;; extends
(
  string
  (string_content) @injection.content
  (#lua-match? @injection.content "^https?://%S+$")
  (#set! injection.language "uri")
)
