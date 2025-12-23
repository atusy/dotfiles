# Scrum Agents

AI-Agentic Scrum framework agents for Claude Code.

## Core Principles

| Principle | Description |
|-----------|-------------|
| Single Source of Truth | All artifacts in `scrum.ts` |
| Git is History | No timestamps - Git tracks changes |
| Order is Priority | Higher in list = higher priority |

## Agent Relationship Diagram

```
                    ┌─────────────────────────────────────────┐
                    │           SCRUM FRAMEWORK               │
                    └─────────────────────────────────────────┘
                                       │
          ┌────────────────────────────┼────────────────────────────┐
          │                            │                            │
          ▼                            ▼                            ▼
    ┌───────────┐              ┌──────────────┐              ┌───────────┐
    │  Product  │◄────────────►│    Scrum     │◄────────────►│ Developer │
    │   Owner   │              │    Master    │              │           │
    └───────────┘              └──────────────┘              └───────────┘
          │                            │                            │
          │ Manages                    │ Facilitates                │ Executes
          ▼                            ▼                            ▼
    ┌───────────┐              ┌──────────────┐              ┌───────────┐
    │  Product  │              │    Scrum     │              │  Sprint   │
    │  Backlog  │              │    Events    │              │ Increment │
    └───────────┘              └──────────────┘              └───────────┘
```

## Directory Structure

```
scrum/
├── README.md           # This file
├── team/               # Accountable roles (persistent)
│   ├── developer.md
│   ├── product-owner.md
│   └── scrum-master.md
└── events/             # Event facilitators (triggered)
    ├── backlog-refinement.md
    ├── sprint-planning.md
    ├── sprint-retrospective.md
    └── sprint-review.md
```

## Team Agents

| Agent | Accountability | Read | Write |
|-------|----------------|------|-------|
| **Product Owner** | Maximizing product value | Full dashboard | Product Backlog, Product Goal, Sprint acceptance |
| **Scrum Master** | Scrum effectiveness | Full dashboard | Sprint config, Retrospective, Metrics |
| **Developer** | Creating Done Increment | Sprint Backlog, DoD | Subtask status, Progress, Notes |

## Event Agents

| Agent | Purpose | Timing |
|-------|---------|--------|
| **Backlog Refinement** | Make PBIs `ready` | Before Sprint Planning |
| **Sprint Planning** | Select PBI, define subtasks | Sprint start |
| **Sprint Review** | Verify DoD, acceptance | Sprint end |
| **Sprint Retrospective** | Identify improvements | After Review |

## Sprint Cycle

```
Refinement → Planning → Execution → Review → Retro → Compaction → (next cycle)
```

| Event | Purpose | Completion Criteria |
|-------|---------|---------------------|
| Retrospective | Inspect previous actions, identify new improvements | `immediate` actions done, others documented |
| Refinement | Make PBIs `ready` | Next PBI is `ready` |
| Planning | Define Sprint Goal, break into subtasks | Subtasks defined |
| Execution | TDD implementation | All subtasks `completed` |
| Review | Verify Definition of Done | All verification commands pass |
| Compaction | Prune dashboard | ≤300 lines |

## AI-Agentic Scrum Model

- **1 Sprint = 1 PBI** - Each Sprint delivers exactly one PBI
- **No fixed duration** - Sprint ends when PBI is Done
- **Instant events** - No time overhead for ceremonies
- **Single source of truth** - `scrum.ts` in project root

## Integration with TDD

Subtask status follows TDD phases:
```
pending → red → green → refactoring → completed
            │      │          │
         (commit)(commit)  (commit × N)
```

| Phase | Commit Type | Description |
|-------|-------------|-------------|
| red | `test:` | Write failing test |
| green | `feat:`/`fix:` | Make test pass |
| refactoring | `refactor:` | Improve structure (multiple commits OK) |

## Agent Decision Tree

| Situation | Agent to Call |
|-----------|---------------|
| PBI creation, priority changes, acceptance | `@scrum-team-product-owner` |
| Framework compliance, impediment reports | `@scrum-team-scrum-master` |
| Subtask implementation, TDD execution | `@scrum-team-developer` |
| Unsure if PBI is `ready` | `@scrum-team-product-owner` |
| Process questions | `@scrum-team-scrum-master` |
| Technical implementation questions | `@scrum-team-developer` |

## Usage

Invoke agents via Task tool:
```
subagent_type: scrum-team-developer
subagent_type: scrum-event-sprint-planning
```

Or use slash commands and skills:
```
/scrum:init          - Initialize scrum.ts dashboard
scrum-dashboard      - Skill for ongoing dashboard maintenance
```
