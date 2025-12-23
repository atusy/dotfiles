---
name: scrum-dashboard
description: Maintain scrum.ts dashboard following Agentic Scrum principles. Use when editing scrum.ts, updating sprint status, or managing Product Backlog.
---

# Scrum Dashboard Maintenance

Guide for maintaining the `scrum.ts` dashboard - the single source of truth for AI-Agentic Scrum.

## When This Skill Applies

- Editing `scrum.ts` in any project
- Updating sprint or subtask status
- Managing Product Backlog items
- Running sprint events (planning, review, retrospective)

## Dashboard Structure

The `scrum.ts` file has two sections:

```
┌─────────────────────────────────────────┐
│  Type Definitions (DO NOT MODIFY)       │  ← Fixed schema
│  - Request human review for changes     │
├─────────────────────────────────────────┤
│  Dashboard Data (AI edits here)         │  ← Your workspace
│  - const scrum: ScrumDashboard = {...}  │
└─────────────────────────────────────────┘
```

## Core Principles

| Principle | Practice |
|-----------|----------|
| **Single Source of Truth** | All Scrum artifacts live in `scrum.ts` |
| **Git is History** | No timestamps needed - Git tracks changes |
| **Order is Priority** | Higher in `product_backlog` array = higher priority |
| **Validate Before Commit** | Always run `deno check scrum.ts` after edits |

## Validation

After every edit to `scrum.ts`:

```bash
deno check scrum.ts
```

This catches type errors before they cause runtime issues.

## Useful Queries

```bash
# Current sprint info
deno run scrum.ts | jq '.sprint'

# Ready PBIs (can start immediately)
deno run scrum.ts | jq '.product_backlog[] | select(.status == "ready")'

# Subtasks in RED phase (tests written, need implementation)
deno run scrum.ts | jq '.sprint.subtasks[] | select(.status == "red")'

# Active improvement actions
deno run scrum.ts | jq '.retrospectives[].improvements[] | select(.status == "active")'

# Dashboard line count (target: ≤300)
wc -l scrum.ts
```

## Status Transitions

### PBI Status
```
draft → refining → ready → (selected for sprint) → done
```

### Subtask Status (TDD Phases)
```
pending → red → green → refactoring → completed
            │      │          │
         (test) (impl)    (cleanup × N)
```

### Sprint Status
```
planning → in_progress → review → done
                              ↘ cancelled
```

## Common Operations

### Start New Sprint
1. Select top `ready` PBI from `product_backlog`
2. Set `sprint.pbi_id` and `sprint.goal`
3. Break into subtasks with `test` and `implementation` fields
4. Set `sprint.status = "in_progress"`

### Update Subtask Progress
1. Change `status` following TDD phases
2. Add commit info to `commits` array after GREEN/REFACTOR
3. Add notes for important decisions

### Complete Sprint
1. Verify all subtasks are `completed`
2. Run Definition of Done checks
3. Set `sprint.status = "done"`
4. Move sprint to `completed` array

### Dashboard Compaction
After retrospective, if `wc -l scrum.ts` > 300:
- Keep only 2-3 sprints in `completed`
- Remove `completed`/`abandoned` improvements from old retrospectives
- Remove `done` PBIs from `product_backlog`
- **Hard limit**: Never exceed 600 lines

## Integration

For deeper guidance on specific events:
- `/scrum:init` - Create new dashboard
- `@scrum-event-sprint-planning` - Sprint planning facilitation
- `@scrum-event-sprint-review` - Sprint review and DoD verification
- `@scrum-event-sprint-retrospective` - Retrospective facilitation
- `@scrum-event-backlog-refinement` - PBI refinement to `ready`

## Commit Discipline

When committing `scrum.ts` changes:
- Commit dashboard updates separately from code changes
- Use descriptive messages: `chore(scrum): update sprint 3 subtask status`
- Validate with `deno check` before committing
