# PBI Anti-Patterns

## 1. Empty Explanation
**Bad**: "We need X because we don't have X"

The reason for building something is never "because it doesn't exist" - there's always an underlying problem to solve.

```
❌ "We need a notification system because we don't have notifications"
✅ "Users miss important updates because they don't check the app daily,
   leading to 40% of time-sensitive actions being missed"
```

## 2. Screen-Based PBI
**Bad**: Organizing work by screens/pages

```
❌ "Build the dashboard screen"
❌ "Build the settings page"
✅ "User can see their booking summary at a glance"
✅ "User can update notification preferences"
```

Problems:
- Screens contain too many features for one sprint
- Mix of essential and optional elements
- Multiple screens may be needed to complete one user journey
- **Solution**: Split by use case completion, not UI structure

## 3. Solution-Focused PBI
**Bad**: Specifying the solution instead of the problem

```
❌ "Automate deployment"
✅ "Reduce deployment time from 2 hours to 15 minutes"
✅ "Eliminate manual deployment errors (currently 1 in 5 deploys fail)"
```

The conversation should reveal whether full automation is needed or if simpler solutions suffice.

## 4. Missing Verification
Every acceptance criterion MUST have an executable command.

```
❌ "User can log in"
✅ "User can log in"
   - Verification: `npm test -- --grep "login flow"`
   - Verification: `curl -X POST /api/login -d '{"user":"test"}' | jq .token`
```

## 5. Mini-Waterfall in Sprint
**Bad**: Working on all items in parallel, integrating/testing at end

```
❌ Day 1-5: Design all → Day 6-8: Build all → Day 9-10: Test all
✅ Day 1-2: Complete Item 1 → Day 3-4: Complete Item 2 → ...
```

Complete items one by one to reduce WIP and ensure Sprint Goal achievement.

## 6. Login-First Syndrome
**Bad**: Building authentication before core features

```
❌ Sprint 1: Login system → Sprint 2: Start actual features
✅ Sprint 1-N: Core features with hardcoded user → Later: Add real auth
```

Ask: What risk does login reduce? What value does it deliver? What feedback can we get?
