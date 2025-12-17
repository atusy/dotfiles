---
description: Tidy After - Clean up code after completing a behavioral change
---

## Tidy After: Clean Up Your Work

You are entering **Tidy After** mode. You've just completed a behavioral change (feat/fix) and now see opportunities to improve the code structure.

### When to Use This

You just:
- Completed a feature and see duplication
- Fixed a bug and noticed messy surrounding code
- Finished TDD GREEN phase and want broader cleanup (beyond `/tdd:refactor`)
- Understand the domain better now and see clearer abstractions

### The Process

```
1. Ensure your behavioral change is committed (feat:/fix:)
2. Identify ONE small tidying opportunity
3. Make the structural change (NO behavior change!)
4. Run tests to confirm nothing broke
5. /git:commit with type "refactor:"
6. More tidying? Repeat from step 2
7. Satisfied? Move on to next work
```

### What to Look For

After a behavioral change, common tidying opportunities:

| Opportunity | Sign |
|-------------|------|
| **Extract Common Code** | You copy-pasted to make tests pass |
| **Better Names** | You understand the domain better now |
| **Simplify Conditionals** | The logic became clearer through implementation |
| **Remove Scaffolding** | Temporary code that helped during development |
| **Improve Cohesion** | Related code ended up scattered |

### Size Limits

Each tidying commit should be:
- **Small**: < 20 lines changed
- **Focused**: One tidying per commit
- **Fast**: Minutes, not hours

### Time-Boxing

Tidy After should be brief:
- Set a limit (e.g., 10-15 minutes)
- Do the most valuable tidyings first
- Stop when time's up or value diminishes
- Use `/tidy:later` for remaining opportunities

### Checklist Per Tidying

- [ ] Behavioral change is already committed
- [ ] This change is purely structural
- [ ] Tests still pass
- [ ] Ready to commit as `refactor:`

### Commit Each Tidying

After each successful tidying, run `/git:commit` to save your progress.

### Next Step

When satisfied with the cleanup:
1. Move on to your next task
2. Start next TDD cycle with `/tdd:red` if applicable

---

**Remember**: Tidy After is optional but valuable. Don't let it become procrastination—time-box it and ship.
