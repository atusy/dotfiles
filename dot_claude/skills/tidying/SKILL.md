---
name: tidying
description: Guide structural code improvements using Kent Beck's Tidy First methodology. Use when seeing messy code, before making behavioral changes, after completing features, documenting deferred cleanup, or discussing when to clean up code.
---

# INSTRUCTIONS

Apply Kent Beck's "Tidy First?" philosophy: small, safe structural changes that improve code without changing behavior. Tidying is separate from feature work and gets its own commits.

- **Behavior Contract**: See `behavior-contract.md` for complete definition of "behavior" (inputs, validation, outputs, side effects, errors) and structural vs behavioral change examples
- **Context Boundaries**: See `context-boundaries.md` for what's safe to tidy in frontend/backend/CLI/library contexts (behavior boundary differs by context!)

## Core Principle

> "Tidying is a special kind of refactoring... tidying is small, and you never need to tidy."

Tidyings are:
- **Small**: Minutes, not hours
- **Safe**: Structure only, no behavior change
- **Optional**: You choose when (or if) to tidy
- **Separate**: Own commits, distinct from behavioral changes

## The Three Timings

| Timing | Trigger | Flow |
|--------|---------|------|
| **Tidy First** | Code is hard to change | `/tidy:first` → `refactor:` commit → behavioral change → `feat:/fix:` commit |
| **Tidy After** | Feature revealed better structure | behavioral change → `feat:/fix:` commit → `/tidy:after` → `refactor:` commit |
| **Tidy Later** | Tidying too big or off-focus | Note opportunity → backlog/TODO → continue current work |

## Decision Framework

```
1. Does this code need to change for my current task?
   No  → Tidy Later (or never)
   Yes ↓
2. Would tidying make my change easier/safer?
   No  → Make behavioral change, consider Tidy After
   Yes ↓
3. Is the tidying small (< 15 minutes)?
   No  → Tidy Later, make behavioral change anyway
   Yes → Tidy First, then make behavioral change
```

## When NOT to DRY

> "Duplication is far cheaper than the wrong abstraction." — Sandi Metz

Keep code inline when:
- Pattern is simple and self-explanatory (`vec![]`, `None`, error returns)
- Abstraction adds indirection without clarity
- Repetitions might evolve differently
- grep/search is easier with inline code

## Reference

Based on: *Tidy First?* by Kent Beck (2023)

## Tidy First

Use before a behavioral change when the code you need to touch is hard to
understand, tightly coupled, poorly named, duplicated, or otherwise messy.

1. Identify one small tidying
2. Make the structural change without changing behavior
3. Run tests to confirm nothing broke
4. Commit with `refactor:`
5. Repeat only while the next behavioral change is still easier or safer

Good small tidyings include guard clauses, dead code removal, normalizing
symmetries, extracting a helper, inlining an obscuring abstraction, renaming,
reordering related code, and introducing explaining variables or constants.

## Tidy After

Use after a committed behavioral change when implementation revealed clearer
structure.

1. Ensure the behavior change is already committed as `feat:` or `fix:`
2. Identify one small cleanup opportunity
3. Make only the structural change
4. Run tests
5. Commit with `refactor:`
6. Repeat only while value remains high

Favor cleanup that removes copy-paste from getting green, improves names after
learning the domain, simplifies conditionals, removes scaffolding, or improves
cohesion.

## Tidy Later

Use when a tidying is valuable but too large, disruptive, or not blocking the
current work.

Document enough context for future work:

- Location: where the messy code is
- Problem: what makes it hard to work with
- Opportunity: what tidying would help
- Trigger: when to revisit it

Prefer the project's existing convention: an in-code TODO, an issue or ticket,
or a tech-debt log. Keep entries specific enough to act on later.
