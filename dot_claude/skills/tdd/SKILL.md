---
name: tdd
description: Guide Test-Driven Development using Kent Beck's Red-Green-Refactor cycle. Use when writing tests, implementing features via TDD, entering RED/GREEN/REFACTOR phase, or following plan.md test instructions.
---

# INSTRUCTIONS

Follow Kent Beck's TDD and Tidy First principles using the following workflow. None of the phases can be skipped.

1. **RED** - Write ONE small failing test
2. **GREEN** - Make minimal behavioral change, then commit
3. **REFACTOR** - Improve structure without changing behavior, commit each step

## Workflow Pattern

```
RED → GREEN → commit → REFACTOR (commit each) → satisfied? ──yes──→ done
 ↑                                                  │
 └───── no (more behavior needed OR triangulate) ───┘
```

## RED Phase

Write ONE small, focused failing test or add ONE failing assertion to an
existing test. Do not commit in RED.

- Use a behavior-describing name such as `shouldAuthenticateValidUser` or
  `test_empty_input_returns_error`
- Test one specific behavior; if the thought includes "and also", split it
- Verify the test fails for the right reason, not because of syntax errors,
  typos, or broken setup
- Create a separate test when behavior, setup, or failure clarity differs

Proceed only after the failure is informative.

## GREEN Phase

Make the failing test pass with the smallest behavioral change. Do not refactor
yet.

Choose the implementation strategy deliberately:

- **Fake It**: return the expected constant when the real implementation is not
  yet clear
- **Obvious Implementation**: type the direct implementation when a single
  expression or established pattern is enough
- **Triangulation**: add another failing example after a fake to force the real
  abstraction

Run all non-long-running tests. Commit the behavioral change once green.

## REFACTOR Phase

Improve structure only after all tests pass. Use the `refactoring` skill for
pattern selection and workflow mechanics.

- Remove duplication between test and production code
- Improve clarity through better names and smaller structure
- Simplify expressions or logic without changing behavior
- Run tests after every small refactoring
- Commit each successful structural change separately

Start another RED phase when more behavior is needed.
