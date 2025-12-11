# AI-Agentic Scrum Dashboard

## Rules

### General Principles

1. **Single Source of Truth**: This dashboard is the only place for Scrum artifacts. All agents read from and write to this file.
2. **Git as History**: Do not add timestamps. Git tracks when changes were made.
3. **Order is Priority**: Items higher in lists have higher priority. No separate priority field needed.

### Product Backlog Management

1. **User Story Format**: Every PBI must have a `story` block with `role`, `capability`, and `benefit`.
2. **Ordering**: Product Owner reorders by moving items up/down in the YAML array.
3. **Refinement**: Change status from `draft` → `refining` → `ready` as stories mature.

### Definition of Ready (AI-Agentic)

**Ready = AI can complete it without asking humans.**

| Status | Meaning |
|--------|---------|
| `ready` | All information available. AI can execute autonomously. |
| `refining` / `draft` | Human input needed. AI cannot proceed alone. |

**When a story needs human input**:
1. First, try to **split the story** — separate parts AI can do alone from parts needing human input
2. If split is possible, mark the autonomous part as `ready`, keep the rest as `refining`
3. If split is not possible, keep the whole story as `refining`

**Prioritization principle**: Since PBIs are Independent (INVEST), prefer `ready` items over items needing human input. Delay human questions as long as possible to maximize autonomous progress.

### Sprint Structure (AI-Agentic)

**1 Sprint = 1 PBI**

Unlike human Scrum where Sprints are time-boxed to amortize event overhead, AI agents have no such constraint. Scrum events are instant for AI, so we maximize iterations by:

- Each Sprint delivers exactly one PBI
- Sprint Planning = select top `ready` item from backlog
- Sprint Review/Retro = run after every PBI completion
- No fixed duration — Sprint ends when PBI is done

**Benefits**: Faster feedback, simpler planning, cleaner increments, easier rollback.

### Sprint Execution

1. **One PBI per Sprint**: Select the top `ready` item. That's the Sprint Backlog.
2. **Subtask Breakdown**: Break the PBI into subtasks at Sprint start.
3. **Update on Completion**: Mark subtasks `completed` immediately when done.
4. **Full Event Cycle**: After PBI completion, run Review → Retro → next Planning.

### Impediment Handling

1. **Log Immediately**: When blocked, add to `impediments.active` right away.
2. **Escalation Path**: Developer → Scrum Master → Human.
3. **Resolution**: Move resolved impediments to `impediments.resolved`.

### Definition of Done

1. **All Criteria Must Pass**: Every required DoD criterion must be verified.
2. **Executable Verification**: Run the verification commands, don't just check boxes.
3. **No Partial Done**: An item is either fully Done or still in_progress.

### Status Transitions

```
PBI Status (in Product Backlog):
  draft → refining → ready

Sprint Status (1 PBI per Sprint):
  in_progress → done
       ↓
    blocked

Sprint Cycle:
  Planning → Execution → Review → Retro → (next Planning)
```

### Agent Responsibilities

| Agent | Reads | Writes |
|-------|-------|--------|
| Product Owner | Full dashboard | Product Backlog, Product Goal, Sprint acceptance |
| Scrum Master | Full dashboard | Sprint config, Impediments, Retrospective, Metrics |
| Developer | Sprint Backlog, DoD | Subtask status, Progress, Notes, Impediments |
| Event Agents | Relevant sections | Event-specific outputs |

---

## Quick Status

```yaml
sprint:
  number: 1
  pbi: "PBI-001: As registered user, I can log in..."
  status: in_progress  # in_progress | blocked | done
  subtasks_completed: 2
  subtasks_total: 6
  impediments: 0
```

---

## 1. Product Backlog

### Product Goal

```yaml
product_goal:
  statement: "Deliver a functional MVP of [product name] that enables [core user value]"
  success_metrics:
    - metric: "All acceptance criteria verified by automated tests"
    - metric: "Documentation generated for public API"
    - metric: "Performance benchmarks met"
  owner: "@scrum-team-product-owner"
```

### Backlog Items

```yaml
product_backlog:
  # Priority 1 - Must Have (Current Sprint Candidates)
  - id: PBI-001
    story:
      role: "registered user"
      capability: "log in with my email and password"
      benefit: "I can access my personalized content securely"
    acceptance_criteria:
      - criterion: "Login endpoint returns valid JWT on correct credentials"
        verification: "pytest tests/auth/test_login.py -v"
      - criterion: "Invalid credentials return 401 with error message"
        verification: "pytest tests/auth/test_login_errors.py -v"
      - criterion: "JWT expires after configured duration"
        verification: "pytest tests/auth/test_token_expiry.py -v"
      - criterion: "User can refresh token before expiry"
        verification: "pytest tests/auth/test_token_refresh.py -v"
      - criterion: "User can log out and invalidate session"
        verification: "pytest tests/auth/test_logout.py -v"
    dependencies: []
    status: ready  # draft | refining | ready

  - id: PBI-002
    story:
      role: "developer"
      capability: "run database migrations safely"
      benefit: "schema changes are versioned and reversible"
    acceptance_criteria:
      - criterion: "Alembic configured with auto-generation support"
        verification: "alembic check"
      - criterion: "Initial migration creates users and sessions tables"
        verification: "alembic upgrade head && pytest tests/db/test_schema.py"
      - criterion: "Rollback works correctly"
        verification: "alembic downgrade -1 && alembic upgrade head"
    dependencies: []
    status: ready

  - id: PBI-003
    story:
      role: "system administrator"
      capability: "limit API requests per user"
      benefit: "the system is protected from abuse and overload"
    acceptance_criteria:
      - criterion: "Rate limiter blocks requests exceeding threshold"
        verification: "pytest tests/middleware/test_rate_limit.py -v"
      - criterion: "Rate limit headers included in responses"
        verification: "pytest tests/middleware/test_rate_headers.py -v"
      - criterion: "Configuration allows per-route customization"
        verification: "pytest tests/middleware/test_rate_config.py -v"
    dependencies:
      - PBI-001  # Needs auth for per-user limiting
    status: refining

  - id: PBI-004
    story:
      role: "registered user"
      capability: "view and update my profile information"
      benefit: "I can personalize my account and upload an avatar"
    acceptance_criteria:
      - criterion: "GET /profile returns current user data"
        verification: "pytest tests/profile/test_get_profile.py"
      - criterion: "PATCH /profile updates allowed fields"
        verification: "pytest tests/profile/test_update_profile.py"
      - criterion: "Avatar upload accepts PNG/JPG under 5MB"
        verification: "pytest tests/profile/test_avatar_upload.py"
    dependencies:
      - PBI-001
      - PBI-002
    status: draft

  - id: PBI-005
    story:
      role: "new user"
      capability: "sign up using my Google, GitHub, or Microsoft account"
      benefit: "I can start using the service without creating a new password"
    acceptance_criteria:
      - criterion: "OAuth2 flow completes for Google provider"
        verification: "pytest tests/auth/test_oauth_google.py"
      - criterion: "New OAuth users automatically create local account"
        verification: "pytest tests/auth/test_oauth_account_creation.py"
    dependencies:
      - PBI-001
    status: draft
```

### Definition of Ready

```yaml
definition_of_ready:
  # Core criterion: AI can complete without asking humans
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
```

---

## 2. Current Sprint

```yaml
sprint:
  number: 1
  pbi_id: PBI-001
  story:
    role: "registered user"
    capability: "log in with my email and password"
    benefit: "I can access my personalized content securely"
  status: in_progress  # in_progress | blocked | done

  subtasks:
    - task: "Create User model and database migration"
      status: completed

    - task: "Implement password hashing utility"
      status: completed

    - task: "Create login endpoint with JWT generation"
      status: in_progress

    - task: "Implement token refresh endpoint"
      status: pending

    - task: "Add logout endpoint (token blacklist)"
      status: pending

    - task: "Write integration tests for all auth flows"
      status: pending

  notes: |
    - Using bcrypt for password hashing (industry standard)
    - JWT includes user_id and role claims
    - Token expiry set to 1 hour with 7-day refresh token
```

### Impediment Registry

```yaml
impediments:
  active: []
  # Example of an impediment entry:
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

  resolved:
    - id: IMP-000
      reporter: "@scrum-team-developer"
      description: "Missing pytest-asyncio dependency"
      impact: "Async tests could not run"
      severity: medium
      resolution: "Added pytest-asyncio to dev dependencies"
```

---

## 3. Definition of Done

```yaml
definition_of_done:
  # Run all verification commands from the PBI's acceptance_criteria
  # Plus these baseline checks:
  checks:
    - name: "Tests pass"
      run: "pytest tests/ -v --tb=short"
    - name: "Lint clean"
      run: "ruff check . && ruff format --check ."
    - name: "Types valid"
      run: "mypy src/ --strict"
```

---

## 4. Completed Sprints

```yaml
# Log of completed PBIs (one per sprint)
completed:
  # - sprint: 1
  #   pbi: PBI-001
  #   story: "As registered user, I can log in..."
  #   verification: passed
  #   notes: "Clean implementation"
```

---

## 5. Retrospective Log

```yaml
# After each sprint, record what to improve
retrospectives:
  # - sprint: 1
  #   worked_well:
  #     - "Clear acceptance criteria"
  #   to_improve:
  #     - "Better subtask breakdown"
  #   actions:
  #     - "Add more specific verification commands"
```

---

## 6. Agents

```yaml
agents:
  product_owner: "@scrum-team-product-owner"    # Backlog ordering, acceptance
  scrum_master: "@scrum-team-scrum-master"      # Process, impediments
  developer: "@scrum-team-developer"            # Implementation

events:
  planning: "@scrum-event-sprint-planning"
  review: "@scrum-event-sprint-review"
  retrospective: "@scrum-event-sprint-retrospective"
  refinement: "@scrum-event-backlog-refinement"
```

