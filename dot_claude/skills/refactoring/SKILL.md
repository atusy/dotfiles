---
name: refactoring
description: Guide code refactoring using Martin Fowler's catalog of behavior-preserving transformations. Use during TDD REFACTOR phase, when code smells are detected (duplication, long methods, feature envy), when discussing structural improvements, or before behavioral changes (Tidy First).
---

# Refactoring Skill

Apply behavior-preserving transformations to improve quality of any codes, including tests.

## Core Principle

> "Refactoring is a disciplined technique for restructuring an existing body of code, altering its internal structure without changing its external behavior." — Martin Fowler

## Structural Changes Only

**Allowed:**
- Renaming for clarity
- Extracting functions/methods
- Removing duplication
- Simplifying expressions
- Moving files/modules between directories
- Reorganizing module boundaries

**NOT allowed:**
- Adding new functionality
- Fixing bugs (if you find one, write a failing test first)
- Changing observable behavior in any way
- Changing public API of libraries (exported symbols, function signatures)

## Refactoring Workflow

1. **Ensure tests pass** (you need a safety net)
2. **Identify ONE smell** to address
3. **Choose appropriate pattern** from `patterns.md`
4. **Apply mechanically** in small steps
5. **Run tests after each step**
6. **Commit when green**

## Safety Rules

- **Never refactor with failing tests**
- **One pattern at a time**
- **Commit after each successful refactor**
- **Revert immediately if tests fail**
