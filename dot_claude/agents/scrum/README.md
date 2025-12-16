# Scrum Agents

AI-Agentic Scrum framework agents for Claude Code.

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
                                       │
          ┌────────────────┬───────────┼───────────┬────────────────┐
          ▼                ▼           ▼           ▼                ▼
    ┌──────────┐    ┌──────────┐ ┌──────────┐ ┌──────────┐   ┌──────────┐
    │ Backlog  │    │  Sprint  │ │  Daily   │ │  Sprint  │   │  Sprint  │
    │Refinement│    │ Planning │ │  Scrum   │ │  Review  │   │  Retro   │
    └──────────┘    └──────────┘ └──────────┘ └──────────┘   └──────────┘
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

| Agent | Accountability | Key Artifacts |
|-------|----------------|---------------|
| **Product Owner** | Maximizing product value | Product Backlog, PBI ordering |
| **Scrum Master** | Scrum effectiveness | Impediment resolution, event facilitation |
| **Developer** | Creating Done Increment | Code, tests, subtask completion |

## Event Agents

| Agent | Purpose | Timing |
|-------|---------|--------|
| **Backlog Refinement** | Break down and clarify PBIs | Before Sprint Planning |
| **Sprint Planning** | Define Sprint Goal and plan | Sprint start |
| **Sprint Review** | Inspect Increment, adapt Backlog | Sprint end |
| **Sprint Retrospective** | Improve team effectiveness | After Sprint Review |

## AI-Agentic Scrum Model

This framework adapts Scrum for AI agent execution:

- **1 Sprint = 1 PBI** - Maximize feedback loops
- **No fixed duration** - Sprint ends when PBI is Done
- **Instant events** - No time overhead for ceremonies
- **Single source of truth** - `plan.md` or scrum dashboard

## Integration with TDD

All development follows Kent Beck's TDD methodology:

1. **Red** - Write failing test (`/tdd:red`)
2. **Green** - Make test pass (`/tdd:green`)
3. **Refactor** - Improve structure (`/tdd:refactor`)

Commits are separated into:
- **Behavioral** (feat/fix) - Changes what code does
- **Structural** (refactor) - Changes how code is organized

## Usage

Invoke agents via Task tool:
```
subagent_type: scrum-team-developer
subagent_type: scrum-event-sprint-planning
```

Or use slash commands (when available):
```
/scrum:init    - Initialize scrum dashboard
/scrum:plan    - Sprint Planning
/scrum:review  - Sprint Review
/scrum:retro   - Sprint Retrospective
/scrum:refine  - Backlog Refinement
```
