---
paths: "**/*.rs"
---

# Use `pub` only when necessary in Rust

* Apply You Aren’t Gonna Need It (YAGNI) principle to visibility, and reduce API surface area
    * private by default
    * `pub(crate)` / `pub(super)` for internal sharing
    * `pub` only for external API surface
* Keep in mind that applications and libraries have different visibility needs
* Review existing `pub` usages during refactoring to ensure they are still needed

