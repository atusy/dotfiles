---
description: Execute the REFACTOR phase - Improve code quality while keeping tests green
---

## TDD REFACTOR Phase: Improve the Code

You are entering the **REFACTOR** phase. Your goal is to improve code quality while keeping all tests passing.

### Phase Rules

- **ONLY refactor when all tests pass** (you should be GREEN)
- **Run tests after EVERY small change** (not just at the end)
- This phase is **REPEATABLE** - do multiple refactors as needed
- **Commit after EACH successful refactor**

### Primary Goal: Remove Duplication

The main purpose of refactoring is to **remove duplication** between test and production code.

Look for:
- Duplicated logic
- Magic numbers/strings that appear in multiple places
- Similar code patterns that could be extracted
- Unclear naming that hides intent

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

### Refactoring Workflow

```
1. Identify ONE small improvement
2. Make the change (keep diff small - see limits below)
3. Run ALL tests
4. Tests pass? -> /git:commit with type "refactor:"
5. Tests fail? -> Revert immediately and take smaller step
6. More improvements needed? -> Repeat from step 1
7. Satisfied? -> Start next TDD cycle with /tdd:red
```

### Refactor Step Size Limits

Each refactor commit should be small and focused:
- **Lines changed**: < 20 lines per commit
- **Files touched**: 1 file per commit (ideally)
- **Scope**: One rename, one extraction, or one move at a time

### Common Refactoring Patterns

| Pattern | When to Use |
|---------|-------------|
| Extract Method | Code block does one identifiable thing |
| Rename | Name does not reveal intent |
| Inline | Abstraction adds no value |
| Extract Variable | Expression is complex or repeated |
| Move Method | Method uses more of another class |

### Checklist Per Refactor Step

- [ ] Change is purely structural (no behavior change)
- [ ] Tests still pass after the change
- [ ] Diff is < 20 lines and touches ideally 1 file
- [ ] Ready to commit this improvement

### Commit Each Refactor

After each successful refactoring step, run `/git:commit` to save your progress.

The commit will be typed as `refactor:` - structural improvement without behavior change.

### Safety Net

- GREEN = Safe. You can always revert to the last commit
- If a refactor breaks tests, revert immediately (`git checkout -- .`)
- Small diffs are easier to review and revert if needed

### Next Step

When duplication is removed and the code is clean:

1. **More TDD?** → Start next cycle with `/tdd:red`
2. **Broader cleanup?** → Use `/tidy:after` for structural improvements beyond test-code duplication

---

**Remember**: REFACTOR focuses on removing duplication from RED→GREEN. For broader tidying, use the `tidying` skill.
