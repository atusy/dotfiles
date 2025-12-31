---
name: refactoring
description: Guide code refactoring using Martin Fowler's catalog of behavior-preserving transformations. Use when improving code structure, removing duplication, addressing code smells, or during TDD REFACTOR phase.
---

# Refactoring Skill

Apply behavior-preserving transformations to improve code quality.

## When This Skill Activates

- During TDD REFACTOR phase (`/tdd:refactor`)
- When code smells are detected (duplication, long methods, feature envy)
- When discussing structural improvements
- Before making behavioral changes (Tidy First)

## Core Principle

> "Refactoring is a disciplined technique for restructuring an existing body of code, altering its internal structure without changing its external behavior." — Martin Fowler

## Refactoring Workflow

1. **Ensure tests pass** (you need a safety net)
2. **Identify ONE smell** to address
3. **Choose appropriate pattern** from `patterns.md`
4. **Apply mechanically** in small steps
5. **Run tests after each step**
6. **Commit when green**

## Quick Pattern Selection

| Code Smell | Start With |
|------------|------------|
| Duplicate code | Extract Method/Variable |
| Long method | Extract Method |
| Long parameter list | Introduce Parameter Object |
| Unclear name | Rename |
| Complex conditional | Decompose Conditional |
| Primitive obsession | Replace Data Value with Object |
| Feature envy | Move Method |
| Magic numbers | Replace with Symbolic Constant |

For comprehensive patterns, see `patterns.md`.

## Safety Rules

- **Never refactor with failing tests**
- **One pattern at a time**
- **Commit after each successful refactor**
- **Revert immediately if tests fail**

## Integration with TDD

This skill complements `/tdd:refactor`:
- TDD REFACTOR focuses on removing RED→GREEN duplication
- This skill provides the full pattern catalog for deeper improvements
