---
name: tdd
description: Guide Test-Driven Development using Kent Beck's Red-Green-Refactor cycle. Use when writing tests, implementing features via TDD, or following plan.md test instructions.
---

# INSTRUCTIONS

Follow Kent Beck's TDD and Tidy First principles using the following workflow. None of the phases can be skipped.

1. **RED** - `/tdd:red` - Write ONE small failing test
2. **GREEN** - `/tdd:green` - Make minimal behavioral change, then commit
3. **REFACTOR** - `/tdd:refactor` - Improve structure without changing behavior, commit each step

## Workflow Pattern

```
RED → GREEN → commit → REFACTOR (commit each) → satisfied? ──yes──→ done
 ↑                                                  │
 └───── no (more behavior needed OR triangulate) ───┘
```
