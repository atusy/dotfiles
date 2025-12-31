---
description: Execute the REFACTOR phase - Improve code quality while keeping tests green
---

## TDD REFACTOR Phase: Improve the Code

You are entering the **REFACTOR** phase. Your goal is to improve code quality while keeping all tests passing.

Use the `refactoring` skill for pattern selection and workflow mechanics.

### Phase Rules

- **ONLY refactor when all tests pass** (you should be GREEN)
- **Run tests after EVERY small change** (not just at the end)
- This phase is **REPEATABLE** - do multiple refactors as needed
- **Commit after EACH successful refactor** using `/git:commit`

### Primary Goals

Improve code quality while keeping tests green:

- **Remove duplication** between test and production code
- **Improve clarity** through better naming and structure
- **Simplify** complex expressions or logic

### Structural Changes Only

**NO behavior changes in REFACTOR phase!**

Allowed:
- Renaming for clarity
- Extracting functions/methods
- Removing duplication
- Simplifying expressions

**NOT allowed** (save for next RED phase):
- Adding new functionality
- Fixing bugs (write a failing test first)
- Changing behavior in any way

### Keep Steps Small

Each refactor commit should be small and focused:
- **Scope**: One rename, one extraction, or one move at a time
- **Revertability**: If tests fail, you should be able to easily undo
- **Size**: Diff < 20 lines, ideally touching 1 file

### Next Step

When duplication is removed and the code is clean:

1. **More TDD?** → Start next cycle with `/tdd:red`
2. **Broader cleanup?** → Use `/tidy:after` for structural improvements beyond test-code duplication

---

**Remember**: REFACTOR focuses on removing duplication from RED→GREEN. For broader tidying, use the `tidying` skill.
