---
description: Tidy Later - Document a tidying opportunity for future work
---

## Tidy Later: Save for the Future

You are using **Tidy Later** mode. You've spotted a tidying opportunity but now isn't the right time to address it.

### When to Use This

The tidying:
- Would take too long (more than 15 minutes)
- Would disrupt your current flow
- Isn't blocking your current work
- Is valuable but not urgent

### The Process

```
1. Document the tidying opportunity (see formats below)
2. Continue with your current work
3. Address the tidying when appropriate (or never)
```

### Documentation Formats

Choose based on your project's conventions:

#### Option 1: TODO Comment (In-Code)
```
// TODO: Extract authentication logic to separate module
// TODO: Rename 'data' to 'userProfile' for clarity
```

#### Option 2: Issue/Ticket
Create a backlog item with:
- **Title**: What to tidy (e.g., "Extract auth logic from UserController")
- **Context**: Why it would help
- **Scope**: Estimated size (small/medium/large)

#### Option 3: Tech Debt Log
Add to a `TECH_DEBT.md` or similar file:
```markdown
## Tidying Backlog

- [ ] Extract authentication logic from UserController
- [ ] Rename ambiguous variables in PaymentService
- [ ] Remove dead code in legacy/utils.ts
```

### What to Document

Include enough context for future-you (or teammates):
- **Location**: Where is the messy code?
- **Problem**: What makes it hard to work with?
- **Opportunity**: What tidying would help?
- **Trigger**: When would be a good time to do it?

### Example Entry

```markdown
### Extract Order Validation

**Location**: src/services/OrderService.ts:45-120
**Problem**: 75 lines of validation logic mixed with business logic
**Opportunity**: Extract to OrderValidator class
**Trigger**: Next time we modify order validation rules
```

### When to Actually Tidy

Good triggers to revisit "Tidy Later" items:
- You need to modify that code anyway
- You have slack time between tasks
- The area is causing bugs
- A teammate asks about the code

### Anti-Patterns

| Don't | Do Instead |
|-------|------------|
| Create vague TODOs | Include specific location and opportunity |
| Let the list grow forever | Periodically review and prune |
| Feel guilty about deferring | Tidy Later is a valid choice |
| Tidy everything before shipping | Ship working code, tidy incrementally |

---

**Remember**: "Never" is a valid answer for some tidyings. Code doesn't have to be perfect—it has to work and be maintainable enough.
