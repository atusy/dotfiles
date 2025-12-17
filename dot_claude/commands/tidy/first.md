---
description: Tidy First - Make structural improvements before a behavioral change
---

## Tidy First: Prepare the Code

You are entering **Tidy First** mode. Your goal is to make small structural improvements that will make your upcoming behavioral change easier and safer.

### When to Use This

You've identified code you need to change, but it's:
- Hard to understand
- Tightly coupled
- Poorly named
- Duplicated
- Otherwise messy

### The Process

```
1. Identify ONE small tidying (see catalog below)
2. Make the structural change (NO behavior change!)
3. Run tests to confirm nothing broke
4. /git:commit with type "refactor:"
5. More tidying needed? Repeat from step 1
6. Ready for behavioral change? Exit and make your feat:/fix: change
```

### Tidying Catalog

Choose one small improvement:

| Tidying | When to Use |
|---------|-------------|
| **Guard Clauses** | Deeply nested conditionals |
| **Dead Code Removal** | Unused code cluttering the file |
| **Normalize Symmetries** | Similar code that looks different |
| **Extract Helper** | A chunk that does one identifiable thing |
| **Inline** | Abstraction that obscures rather than helps |
| **Rename** | Name doesn't reveal intent |
| **Reorder** | Related code is scattered |
| **Explaining Variable** | Complex expression hard to understand |
| **Explaining Constant** | Magic number/string with no context |

### Size Limits

Each tidying commit should be:
- **Small**: < 20 lines changed
- **Focused**: One tidying per commit
- **Fast**: Minutes, not hours

If the tidying would take too long, consider `/tidy:later` instead.

### Checklist Per Tidying

- [ ] Change is purely structural (no behavior change)
- [ ] Tests still pass
- [ ] Diff is small and focused
- [ ] Ready to commit as `refactor:`

### Commit Each Tidying

After each successful tidying, run `/git:commit` to save your progress.

### Next Step

When the code is ready for your behavioral change:
1. Exit tidying mode
2. Make your feature/fix change
3. Commit with `feat:` or `fix:`
4. Optionally use `/tidy:after` for any cleanup you notice

---

**Remember**: Tidy First is about making the upcoming change easier. Don't over-tidy—just enough to reduce friction.
