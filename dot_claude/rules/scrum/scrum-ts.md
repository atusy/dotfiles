---
paths: "scrum.ts"
---

## Scrum Guidelines

* **SSoT**: Treat the `scrum.ts` file as the single source of truth for scrum development
* **Schema safety**: Run `deno check scrum.ts` after modifications to validate types
* **Version control**: Git commit every time making meaningful changes to `scrum.ts` unless gitignore rules apply. The commit should involve only changes to `scrum.ts`
* **Data queries**: Use `deno run scrum.ts | jq '<query>'` to extract data
