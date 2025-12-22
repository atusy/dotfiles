---
name: tdd
description: Guide Test-Driven Development using Kent Beck's Red-Green-Refactor cycle. Use when writing tests, implementing features via TDD, or following plan.md test instructions.
---

# INSTRUCTIONS

Follow Kent Beck's TDD and Tidy First principles using the three-phase workflow:

1. **RED** - `/tdd:red` - Write ONE small failing test
2. **GREEN** - `/tdd:green` - Make it pass with minimal code, then commit
3. **REFACTOR** - `/tdd:refactor` - Improve structure without changing behavior, commit each step

## Workflow Pattern

```
RED → GREEN → commit → REFACTOR (commit each) → satisfied? ──yes──→ done
 ↑                                                  │
 └───── no (more behavior needed OR triangulate) ───┘
```

## Core Principles

- **Never skip REFACTOR**: Every TDD cycle must complete all three phases

## Strategy Selection (GREEN Phase)

| Confidence | Strategy | Use When |
|------------|----------|----------|
| Low | **Fake It** | Return constant, generalize later |
| High | **Obvious Implementation** | Solution is clear |
| Generalizing | **Triangulation** | Add test to break a fake |

