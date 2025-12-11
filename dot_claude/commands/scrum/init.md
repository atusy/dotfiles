---
allowed-tools: Read, Write, Bash(cat:*), Bash(ls:*)
description: Initialize a plan.md file based on AI-Agentic Scrum Dashboard template
---

## Initialize AI-Agentic Scrum Dashboard

You are setting up a new project with the AI-Agentic Scrum methodology. This command will create a `plan.md` file in the project root that serves as the single source of truth for all Scrum artifacts.

### Step 0: Ensure Project Initialization

First, run `/init` to ensure CLAUDE.md is up to date.

### Step 1: Gather Project Information

Ask the user the following questions interactively. Wait for answers before proceeding to file generation.

**Required Information:**

1. **Product Name**: What is the name of this product/project?

2. **Product Goal**: What is the core user value this product delivers?
   - Example: "Enable developers to write tests more efficiently"
   - This becomes the Product Goal statement

3. **Tech Stack**: What technologies is this project using?
   - Language(s): e.g., Python, TypeScript, Rust, Go
   - Test framework: e.g., pytest, jest, vitest, cargo test
   - Linter/formatter: e.g., ruff, eslint, prettier, rustfmt
   - Type checker: e.g., mypy, tsc, none
   - This determines the Definition of Done verification commands

4. **Initial PBI Ideas**: What are the first 2-3 features or user stories you want to build?
   - For each, ask:
     - Who is the user role?
     - What capability do they need?
     - What benefit does it provide?
   - These become the initial Product Backlog Items

5. **Success Metrics** (optional): How will you measure product success?
   - Default metrics will be provided if none specified

### Step 2: Generate plan.md

After gathering information, generate the `plan.md` file with this structure:

``````````markdown
# AI-Agentic Scrum Dashboard

## Rules

### General Principles

1. **Single Source of Truth**: This dashboard is the only place for Scrum artifacts. All agents read from and write to this file.
2. **Git as History**: Do not add timestamps. Git tracks when changes were made.
3. **Order is Priority**: Items higher in lists have higher priority. No separate priority field needed.

### Product Backlog Management

1. **User Story Format**: Every PBI must have a `story` block with `role`, `capability`, and `benefit`.
2. **Ordering**: Product Owner reorders by moving items up/down in the YAML array.
3. **Refinement**: Change status from `draft` -> `refining` -> `ready` as stories mature.

### Definition of Ready (AI-Agentic)

**Ready = AI can complete it without asking humans.**

| Status | Meaning |
|--------|---------|
| `draft` | Initial idea. Needs elaboration. |
| `refining` | Being refined. AI may be able to make it `ready`. |
| `ready` | All information available. AI can execute autonomously. |

**Refinement process**:
1. AI attempts to refine `draft`/`refining` items autonomously (explore codebase, propose acceptance criteria, identify dependencies)
2. If AI can fill in all gaps -> change status to `ready`
3. If story is too big or unclear -> try to split it
4. If unsplittable item still needs human help -> keep as `refining` and document the question

**Prioritization**: Prefer `ready` items. Work on refinement when no `ready` items exist or while waiting for human input.

### Sprint Structure (AI-Agentic)

**1 Sprint = 1 PBI**

Unlike human Scrum where Sprints are time-boxed to amortize event overhead, AI agents have no such constraint. Scrum events are instant for AI, so we maximize iterations by:

- Each Sprint delivers exactly one PBI
- Sprint Planning = select top `ready` item from backlog
- Sprint Review/Retro = run after every PBI completion
- No fixed duration - Sprint ends when PBI is done

**Benefits**: Faster feedback, simpler planning, cleaner increments, easier rollback.

### Sprint Execution (TDD Workflow)

1. **One PBI per Sprint**: Select the top `ready` item. That's the Sprint Backlog.
2. **TDD Subtask Breakdown**: Break the PBI into subtasks. Each subtask produces commits through Red-Green-Refactor:
   - `test`: What behavior to verify (becomes the Red phase test)
   - `implementation`: What to build to make the test pass (Green phase)
   - `type`: `behavioral` (new functionality) or `structural` (refactoring only)
   - `status`: Current TDD phase (`pending` | `red` | `green` | `refactoring` | `completed`)
   - `commits`: Array tracking each commit made for this subtask
3. **TDD Cycle Per Subtask (Commit-Based)**:
   - **Red**: Write a failing test, commit it (`phase: red`), status becomes `red`
   - **Green**: Implement minimum code to pass, commit it (`phase: green`), status becomes `green`
   - **Refactor**: Make structural improvements, commit each one separately (`phase: refactor`), status becomes `refactoring`
   - **Complete**: All refactoring done, status becomes `completed`
4. **Multiple Refactor Commits**: Following Tidy First, make small, frequent structural changes. Each refactor commit should be a single logical improvement (rename, extract method, etc.).
5. **Commit Discipline**: Each commit represents one TDD phase step. Never mix behavioral and structural changes in the same commit.
6. **Full Event Cycle**: After PBI completion, run Review -> Retro -> next Planning.

### Impediment Handling

1. **Log Immediately**: When blocked, add to `impediments.active` right away.
2. **Escalation Path**: Developer -> Scrum Master -> Human.
3. **Resolution**: Move resolved impediments to `impediments.resolved`.

### Definition of Done

1. **All Criteria Must Pass**: Every required DoD criterion must be verified.
2. **Executable Verification**: Run the verification commands, don't just check boxes.
3. **No Partial Done**: An item is either fully Done or still in_progress.

### Status Transitions

``````
PBI Status (in Product Backlog):
  draft -> refining -> ready

Sprint Status (1 PBI per Sprint):
  in_progress -> done
       |
    blocked

Subtask Status (TDD Cycle with Commits):
  pending ─┬─> red ─────> green ─┬─> refactoring ─┬─> completed
           │   (commit)  (commit) │    (commit)    │
           │                      │       ↓        │
           │                      │   (more refactor commits)
           │                      │       ↓        │
           │                      └───────┴────────┘
           │
           └─> (skip to completed if no test needed, e.g., pure structural)

Each status transition produces a commit:
  pending -> red:        commit(test: ...)
  red -> green:          commit(feat: ... or fix: ...)
  green -> refactoring:  commit(refactor: ...)
  refactoring -> refactoring: commit(refactor: ...) [multiple allowed]
  refactoring -> completed:   (no commit, just status update)
  green -> completed:    (no commit, skip refactor if not needed)

Sprint Cycle:
  Planning -> Execution -> Review -> Retro -> (next Planning)
``````

### Agent Responsibilities

| Agent | Reads | Writes |
|-------|-------|--------|
| Product Owner | Full dashboard | Product Backlog, Product Goal, Sprint acceptance |
| Scrum Master | Full dashboard | Sprint config, Impediments, Retrospective, Metrics |
| Developer | Sprint Backlog, DoD | Subtask status, Progress, Notes, Impediments |
| Event Agents | Relevant sections | Event-specific outputs |

---

## Quick Status

``````yaml
sprint:
  number: 0
  pbi: null
  status: not_started
  subtasks_completed: 0
  subtasks_total: 0
  impediments: 0
``````

---

## 1. Product Backlog

### Product Goal

``````yaml
product_goal:
  statement: "[PRODUCT_GOAL_STATEMENT]"
  success_metrics:
    [SUCCESS_METRICS]
  owner: "@scrum-team-product-owner"
``````

### Backlog Items

``````yaml
product_backlog:
  [BACKLOG_ITEMS]
  # Example PBI format:
  # - id: PBI-001
  #   story:
  #     role: "registered user"
  #     capability: "log in with my email and password"
  #     benefit: "I can access my personalized content securely"
  #   acceptance_criteria:
  #     - criterion: "Login endpoint returns valid JWT on correct credentials"
  #       verification: "pytest tests/auth/test_login.py -v"
  #     - criterion: "Invalid credentials return 401 with error message"
  #       verification: "pytest tests/auth/test_login_errors.py -v"
  #     - criterion: "JWT expires after configured duration"
  #       verification: "pytest tests/auth/test_token_expiry.py -v"
  #   dependencies: []
  #   status: ready  # draft | refining | ready
``````

### Definition of Ready

``````yaml
definition_of_ready:
  criteria:
    - criterion: "AI can complete this story without human input"
      required: true
      note: "If human input needed, split or keep as refining"
    - criterion: "User story has role, capability, and benefit"
      required: true
    - criterion: "At least 3 acceptance criteria with verification commands"
      required: true
    - criterion: "Dependencies are resolved or not blocking"
      required: true
``````

---

## 2. Current Sprint

``````yaml
sprint:
  number: 0
  pbi_id: null
  story: null
  status: not_started

  subtasks: []
  # TDD Subtask Format - Each subtask tracks commits through Red-Green-Refactor:
  #
  # - test: "User model has email and hashed_password fields"
  #   implementation: "Create User SQLAlchemy model with fields"
  #   type: behavioral  # behavioral | structural
  #   status: completed  # pending | red | green | refactoring | completed
  #   commits:
  #     - phase: red
  #       message: "test: User model has email and hashed_password fields"
  #     - phase: green
  #       message: "feat: Create User SQLAlchemy model"
  #     - phase: refactor
  #       message: "refactor: Extract field definitions to constants"
  #     - phase: refactor
  #       message: "refactor: Add docstring to User model"
  #
  # - test: "hash_password returns bcrypt hash"
  #   implementation: "Implement hash_password utility function"
  #   type: behavioral
  #   status: green  # Test passing, no refactor needed yet
  #   commits:
  #     - phase: red
  #       message: "test: hash_password returns bcrypt hash"
  #     - phase: green
  #       message: "feat: Implement hash_password utility"
  #
  # - test: "verify_password returns True for matching passwords"
  #   implementation: "Implement verify_password utility function"
  #   type: behavioral
  #   status: red  # Failing test committed, implementation pending
  #   commits:
  #     - phase: red
  #       message: "test: verify_password returns True for matching"
  #
  # - test: "Extract password validation to separate module"
  #   implementation: "Move validation logic to validators.py"
  #   type: structural  # Refactoring - no new behavior, no red phase
  #   status: pending
  #   commits: []
  #
  # Status meanings:
  #   pending    -> Not started, no commits yet
  #   red        -> Failing test committed, ready for implementation
  #   green      -> Passing implementation committed, ready for refactoring
  #   refactoring -> One or more refactor commits done, more may come
  #   completed  -> All commits done, subtask finished
  #
  # Commit tracking:
  #   - Each TDD phase produces exactly one commit (except refactoring which may have many)
  #   - phase: red | green | refactor
  #   - message: The actual commit message used
  #   - Multiple refactor commits are encouraged (Tidy First = small structural changes)

  notes: |
    No sprint started yet. Run Sprint Planning to begin.
``````

### Impediment Registry

``````yaml
impediments:
  active: []
  # Example impediment format:
  # - id: IMP-001
  #   reporter: "@scrum-team-developer"
  #   description: "Redis connection timeout in test environment"
  #   impact: "Blocks rate limiting tests"
  #   severity: high  # low | medium | high | critical
  #   affected_items:
  #     - PBI-003
  #   resolution_attempts:
  #     - attempt: "Increased connection timeout to 30s"
  #       result: "Still failing"
  #   status: investigating  # new | investigating | escalated | resolved
  #   escalated_to: null
  #   resolution: null

  resolved: []
  # Example resolved impediment format:
  # - id: IMP-000
  #   reporter: "@scrum-team-developer"
  #   description: "Missing pytest-asyncio dependency"
  #   impact: "Async tests could not run"
  #   severity: medium
  #   resolution: "Added pytest-asyncio to dev dependencies"
``````

---

## 3. Definition of Done

``````yaml
definition_of_done:
  # Run all verification commands from the PBI's acceptance_criteria
  # Plus these baseline checks:
  checks:
    [DOD_CHECKS]
    # Example check format:
    # - name: "Tests pass"
    #   run: "pytest tests/ -v --tb=short"
    # - name: "Lint clean"
    #   run: "ruff check . && ruff format --check ."
    # - name: "Types valid"
    #   run: "mypy src/ --strict"
``````

---

## 4. Completed Sprints

``````yaml
# Log of completed PBIs (one per sprint)
completed: []
# Example completed sprint format:
# - sprint: 1
#   pbi: PBI-001
#   story: "As registered user, I can log in..."
#   verification: passed
#   notes: "Clean implementation"
``````

---

## 5. Retrospective Log

``````yaml
# After each sprint, record what to improve
retrospectives: []
# Example retrospective format:
# - sprint: 1
#   worked_well:
#     - "Clear acceptance criteria"
#   to_improve:
#     - "Better subtask breakdown"
#   actions:
#     - "Add more specific verification commands"
``````

---

## 6. Agents

``````yaml
agents:
  product_owner: "@scrum-team-product-owner"
  scrum_master: "@scrum-team-scrum-master"
  developer: "@scrum-team-developer"

events:
  planning: "@scrum-event-sprint-planning"
  review: "@scrum-event-sprint-review"
  retrospective: "@scrum-event-sprint-retrospective"
  refinement: "@scrum-event-backlog-refinement"
``````
``````````

### Step 3: Customize Based on Tech Stack

Replace placeholders with actual values:

**For Definition of Done checks**, use appropriate commands based on tech stack:

| Tech Stack | Test Command | Lint Command | Type Check |
|------------|--------------|--------------|------------|
| Python (pytest/ruff/mypy) | `pytest tests/ -v --tb=short` | `ruff check . && ruff format --check .` | `mypy src/ --strict` |
| TypeScript (jest/eslint) | `npm test` | `npm run lint` | `npx tsc --noEmit` |
| TypeScript (vitest/eslint) | `npm run test` | `npm run lint` | `npx tsc --noEmit` |
| Rust | `cargo test` | `cargo clippy -- -D warnings` | `cargo check` |
| Go | `go test ./...` | `golangci-lint run` | (built-in) |

**For Backlog Items**, format each PBI as:

```yaml
  - id: PBI-001
    story:
      role: "[role]"
      capability: "[capability]"
      benefit: "[benefit]"
    acceptance_criteria:
      - criterion: "[criterion 1]"
        verification: "[test command]"
      - criterion: "[criterion 2]"
        verification: "[test command]"
      - criterion: "[criterion 3]"
        verification: "[test command]"
    dependencies: []
    status: draft
```

### Step 4: Write the File

Save the generated content to `plan.md` in the project root.

### Step 5: Confirm and Guide

After creating the file:

1. Confirm the file was created at `[project_root]/plan.md`
2. Explain next steps:
   - Review and refine the initial PBIs
   - Change status from `draft` to `ready` when stories are complete
   - Run Sprint Planning to start the first sprint
3. Mention that all agents should use this file as the single source of truth

---

**Begin by running `/init`, then ask the user the required questions one section at a time.**
