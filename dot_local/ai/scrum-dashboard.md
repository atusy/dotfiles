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
2. **Escalation Path**: Developer (15 min) → Scrum Master (30 min) → Human.
3. **Resolution Documentation**: Move resolved impediments to `impediments.resolved` with resolution notes.

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
    # User Story format: As <role>, I can <capability>, so that <benefit>
    story:
      role: "registered user"
      capability: "log in with my email and password"
      benefit: "I can access my personalized content securely"
    type: feature  # feature | bug | spike | tech-debt
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
    type: tech-debt
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
    type: feature
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

  # Priority 2 - Should Have
  - id: PBI-004
    story:
      role: "registered user"
      capability: "view and update my profile information"
      benefit: "I can personalize my account and upload an avatar"
    type: feature
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

  # Icebox / Future Consideration
  - id: PBI-005
    story:
      role: "new user"
      capability: "sign up using my Google, GitHub, or Microsoft account"
      benefit: "I can start using the service without creating a new password"
    type: feature
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

## 2. Sprint Backlog

### Sprint Goal

```yaml
sprint_goal:
  number: 1
  statement: "Establish core authentication infrastructure enabling secure user access"
  rationale: |
    Authentication is foundational for all user-facing features.
    Completing this enables parallel work on user-dependent features in next sprint.
  success_criteria:
    - "All auth endpoints operational and tested"
    - "Database schema supports user and session storage"
    - "Integration tests pass in CI pipeline"
  forecast_confidence: high  # low | medium | high
```

### Current Sprint

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
  # All criteria must pass for an item to be "Done"
  criteria:
    - id: DOD-1
      name: "Code Implemented"
      description: "Feature code is written and follows project conventions"
      verification:
        type: manual
        command: null
        check: "Code exists and is syntactically correct"
      required: true

    - id: DOD-2
      name: "Unit Tests Pass"
      description: "All unit tests for the feature pass"
      verification:
        type: automated
        command: "pytest tests/ -v --tb=short"
        success_pattern: "passed"
        failure_pattern: "failed|error"
      required: true

    - id: DOD-3
      name: "Acceptance Criteria Verified"
      description: "Each acceptance criterion has been explicitly verified"
      verification:
        type: automated
        command: "Run each AC verification command from PBI"
        success_pattern: "All verification commands exit 0"
      required: true

    - id: DOD-4
      name: "No Linting Errors"
      description: "Code passes all linting checks"
      verification:
        type: automated
        command: "ruff check . && ruff format --check ."
        success_pattern: "All checks passed"
      required: true

    - id: DOD-5
      name: "Type Checks Pass"
      description: "Static type analysis passes"
      verification:
        type: automated
        command: "mypy src/ --strict"
        success_pattern: "Success: no issues found"
      required: true

    - id: DOD-6
      name: "Documentation Updated"
      description: "API docs and README updated if applicable"
      verification:
        type: manual
        command: null
        check: "New public APIs have docstrings; README updated for user-facing changes"
      required: true

    - id: DOD-7
      name: "No Regression"
      description: "Existing tests still pass"
      verification:
        type: automated
        command: "pytest tests/ -v"
        success_pattern: "0 failed"
      required: true

    - id: DOD-8
      name: "Security Check"
      description: "No new security vulnerabilities introduced"
      verification:
        type: automated
        command: "bandit -r src/ -ll"
        success_pattern: "No issues identified"
      required: false
      note: "Recommended but not blocking"

  # Composite verification script
  verify_all:
    script: |
      #!/bin/bash
      set -e
      echo "=== Running Definition of Done Verification ==="

      echo "[DOD-2] Running unit tests..."
      pytest tests/ -v --tb=short

      echo "[DOD-4] Running linter..."
      ruff check . && ruff format --check .

      echo "[DOD-5] Running type checker..."
      mypy src/ --strict

      echo "[DOD-7] Verifying no regression..."
      pytest tests/ -v

      echo "[DOD-8] Running security scan..."
      bandit -r src/ -ll || echo "Security check has warnings (non-blocking)"

      echo "=== All DoD checks completed ==="

    command: "bash scripts/verify_dod.sh"
```

---

## 4. Increment

### Completed This Sprint

```yaml
increment:
  sprint: 1
  status: in_progress  # in_progress | ready_for_review | accepted | released

  completed_items: []
  # Example of completed item:
  # - id: PBI-001
  #   story:
  #     role: "registered user"
  #     capability: "log in with my email and password"
  #     benefit: "I can access my personalized content securely"
  #   verification_results:
  #     - criterion: "Login endpoint returns valid JWT"
  #       command: "pytest tests/auth/test_login.py -v"
  #       result: passed
  #       output_summary: "3 tests passed in 0.45s"
  #     - criterion: "Invalid credentials return 401"
  #       command: "pytest tests/auth/test_login_errors.py -v"
  #       result: passed
  #       output_summary: "5 tests passed in 0.32s"
  #     - criterion: "JWT expires after configured duration"
  #       command: "pytest tests/auth/test_token_expiry.py -v"
  #       result: passed
  #       output_summary: "2 tests passed in 1.12s"
  #   dod_verification:
  #     command: "bash scripts/verify_dod.sh"
  #     result: passed
  #   notes: "Clean implementation"

  verification_summary:
    total_acceptance_criteria: 0
    criteria_passed: 0
    criteria_failed: 0
    dod_checks_passed: true
    ready_for_review: false
```

### Release Notes Draft

```yaml
release_notes:
  version: "0.1.0"
  sprint: 1

  summary: |
    Initial release establishing core authentication infrastructure.

  features: []
  # - title: "User Authentication"
  #   description: "Secure JWT-based authentication with login, logout, and token refresh"
  #   pbi_reference: PBI-001

  bug_fixes: []

  technical_improvements: []
  # - title: "Database Migration System"
  #   description: "Alembic-based schema migrations for reliable database evolution"
  #   pbi_reference: PBI-002

  breaking_changes: []

  known_issues: []

  upgrade_notes: |
    First release - no upgrade path needed.
```

---

## 5. Retrospective Log

### Current Sprint Retrospective

```yaml
current_retrospective:
  sprint: 1
  status: pending  # pending | in_progress | completed

  # To be filled during retrospective
  data_collected:
    what_went_well: []
    what_could_improve: []
    action_items: []
```

### Historical Retrospectives

```yaml
retrospective_history:
  # Example from a previous sprint:
  # - sprint: 0
  #   what_went_well:
  #     - item: "Clear acceptance criteria made verification straightforward"
  #       category: process
  #     - item: "Small user stories completed quickly"
  #       category: planning
  #     - item: "Subtask breakdown improved progress visibility"
  #       category: transparency
  #
  #   what_could_improve:
  #     - item: "Context loss between agent sessions caused rework"
  #       category: tooling
  #       impact: high
  #     - item: "Impediment escalation path unclear"
  #       category: process
  #       impact: medium
  #
  #   action_items:
  #     - id: RETRO-0-1
  #       action: "Add checkpoint summaries to dashboard after each PBI"
  #       owner: "@scrum-team-scrum-master"
  #       status: completed
  #       implemented_in_sprint: 1
  #
  #     - id: RETRO-0-2
  #       action: "Define escalation protocol with timeouts"
  #       owner: "@scrum-team-scrum-master"
  #       status: completed
  #       implemented_in_sprint: 1
  #
  #   metrics:
  #     pbis_completed: 2
  #     items_carried_over: 0
  #     impediments_encountered: 1
  #     impediments_resolved: 1
  #     dod_violations: 0
  #
  #   configuration_changes:
  #     - change: "Increased checkpoint frequency to after each subtask"
  #       rationale: "Improve context persistence"
```

### Continuous Improvement Tracking

```yaml
improvement_backlog:
  implemented:
    - id: IMP-RETRO-001
      improvement: "Structured YAML format for all artifacts"
      implemented_sprint: 1
      measured_benefit: "Eliminated ambiguity in status tracking"

  in_progress:
    - id: IMP-RETRO-002
      improvement: "Automated DoD verification script"
      target_sprint: 1
      status: "Script created, integrating into workflow"

  planned: []
```

---

## 6. Team Configuration

### Agent Roles

```yaml
team:
  product_owner:
    agent: "@scrum-team-product-owner"
    responsibilities:
      - "Maintain Product Backlog priority"
      - "Define and communicate Product Goal"
      - "Accept or reject completed increments"
      - "Refine acceptance criteria"
    authorities:
      - "Reorder Product Backlog at any time"
      - "Accept/reject work as Done"
      - "Cancel Sprint if Goal becomes obsolete"
    escalation_from:
      - "@scrum-team-developer"
      - "@scrum-team-scrum-master"

  scrum_master:
    agent: "@scrum-team-scrum-master"
    responsibilities:
      - "Facilitate Scrum events"
      - "Maintain dashboard artifacts"
      - "Track and resolve impediments"
      - "Enforce Scrum framework"
      - "Coach on Scrum practices"
    authorities:
      - "Enforce timeboxes"
      - "Update artifact status"
      - "Escalate to human oversight"
    escalation_from:
      - "@scrum-team-developer"
    escalation_to:
      - "human_oversight"
      - "@scrum-team-product-owner"

  developers:
    - agent: "@scrum-team-developer"
      capabilities:
        - "Code implementation"
        - "Test writing"
        - "Code review"
        - "Documentation"
      responsibilities:
        - "Deliver PBIs meeting DoD"
        - "Break PBIs into subtasks"
        - "Report impediments immediately"
        - "Update progress in dashboard"
      escalation_to:
        - "@scrum-team-scrum-master"
```

### Event Agents (Specialized Facilitators)

```yaml
event_agents:
  sprint_planning:
    agent: "@scrum-event-sprint-planning"
    trigger: "Sprint start"
    inputs:
      - "Product Backlog (ready items)"
    outputs:
      - "Sprint Goal"
      - "Sprint Backlog"
      - "Initial subtask breakdown"

  sprint_review:
    agent: "@scrum-event-sprint-review"
    trigger: "Sprint end (before retrospective)"
    inputs:
      - "Increment"
      - "Sprint Goal"
      - "Stakeholder questions"
    outputs:
      - "Feedback log"
      - "Product Backlog updates"
      - "Acceptance decisions"

  sprint_retrospective:
    agent: "@scrum-event-sprint-retrospective"
    trigger: "After Sprint Review"
    inputs:
      - "Sprint metrics"
      - "Impediment log"
      - "Team observations"
    outputs:
      - "Retrospective log entry"
      - "Action items for next sprint"
      - "Configuration changes"

  backlog_refinement:
    agent: "@scrum-event-backlog-refinement"
    trigger: "On demand or scheduled"
    inputs:
      - "Draft PBIs"
      - "Definition of Ready"
    outputs:
      - "Refined PBIs"
      - "Estimation updates"
```

### Escalation Protocols

```yaml
escalation_protocols:
  impediment_escalation:
    - level: 1
      handler: "@scrum-team-developer"
      timeout_minutes: 15
      actions:
        - "Attempt self-resolution"
        - "Document attempts in impediment registry"

    - level: 2
      handler: "@scrum-team-scrum-master"
      timeout_minutes: 30
      actions:
        - "Analyze root cause"
        - "Coordinate with other agents"
        - "Attempt resolution"

    - level: 3
      handler: "human_oversight"
      timeout_minutes: null
      actions:
        - "Human reviews and decides"
        - "May provide missing context"
        - "May adjust Sprint scope"

  scope_change_request:
    authority: "@scrum-team-product-owner"
    process:
      - "Developer identifies need"
      - "SM facilitates discussion"
      - "PO decides if scope changes"
      - "If yes, update Sprint Backlog"

  dod_violation:
    process:
      - "SM identifies violation"
      - "Work returns to in_progress"
      - "Developer addresses gaps"
      - "Re-verify all DoD criteria"

  sprint_cancellation:
    authority: "@scrum-team-product-owner"
    criteria:
      - "Sprint Goal obsolete"
      - "Unresolvable impediment blocking all work"
    process:
      - "PO declares cancellation with rationale"
      - "SM documents in dashboard"
      - "Incomplete items return to Product Backlog"
      - "Retrospective still occurs"
```

### Human Oversight Touchpoints

```yaml
human_oversight:
  required_approvals:
    - event: "Sprint Goal acceptance"
      when: "Start of Sprint Planning"

    - event: "Increment acceptance"
      when: "End of Sprint Review"

    - event: "Production deployment"
      when: "After increment accepted"

  optional_checkpoints:
    - event: "Mid-sprint progress review"
      when: "50% of sprint items completed or in_progress"
      purpose: "Validate direction, adjust if needed"

    - event: "Impediment escalation"
      when: "Level 3 escalation triggered"
      purpose: "Provide context, make decisions"

  async_notifications:
    - "Sprint started"
    - "PBI completed"
    - "Impediment escalated"
    - "Sprint completed"
```

---

## 7. Metrics and Analytics

```yaml
metrics:
  historical:
    sprints_completed: 0
    pbis_completed: 0

  quality:
    dod_violations: 0
    bugs_found_in_increment: 0
    rework_count: 0
```

---

## Appendix: Quick Reference

### Command Reference

```bash
# Verify Definition of Done
bash scripts/verify_dod.sh

# Run all tests
pytest tests/ -v

# Check code quality
ruff check . && ruff format --check . && mypy src/ --strict

# Security scan
bandit -r src/ -ll
```

### Agent Mentions

| Role | Mention | Primary Function |
|------|---------|------------------|
| Product Owner | `@scrum-team-product-owner` | Backlog, priorities, acceptance |
| Scrum Master | `@scrum-team-scrum-master` | Process, impediments, facilitation |
| Developer | `@scrum-team-developer` | Implementation, testing |
| Sprint Planning | `@scrum-event-sprint-planning` | Planning facilitation |
| Sprint Review | `@scrum-event-sprint-review` | Review facilitation |
| Retrospective | `@scrum-event-sprint-retrospective` | Retro facilitation |
| Refinement | `@scrum-event-backlog-refinement` | Backlog refinement |
