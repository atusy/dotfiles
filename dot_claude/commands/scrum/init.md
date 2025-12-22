---
allowed-tools: Read, Write, Bash(cat:*), Bash(ls:*)
description: Initialize a scrum.yaml file based on AI-Agentic Scrum Dashboard template
---

## Initialize AI-Agentic Scrum Dashboard

You are setting up a new project with the AI-Agentic Scrum methodology. This command will create a `scrum.yaml` file in the project root that serves as the single source of truth for all Scrum artifacts.

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

### Step 2: Generate scrum.yaml

After gathering information, generate the `scrum.yaml` file with this structure:

```yaml
# Product Goal
product_goal:
  statement: "[PRODUCT_GOAL_STATEMENT]"
  success_metrics:
    - metric: "[METRIC_NAME]"
      target: "[TARGET_VALUE]"

# Product Backlog (order = priority)
product_backlog:
  - id: PBI-001
    story:
      role: "[USER_ROLE]"
      capability: "[WHAT_THEY_CAN_DO]"
      benefit: "[WHY_IT_MATTERS]"
    acceptance_criteria:
      - criterion: "[CRITERION_DESCRIPTION]"
        verification: "[EXECUTABLE_COMMAND]"
    status: draft  # draft | refining | ready

# Current Sprint
sprint:
  number: 1
  pbi_id: PBI-001
  goal: "[SPRINT_GOAL]"
  status: in_progress  # planning | in_progress | review | done | cancelled
  subtasks:
    - test: "[TEST_DESCRIPTION]"
      implementation: "[IMPLEMENTATION_DESCRIPTION]"
      type: behavioral  # behavioral | structural
      status: pending  # pending | red | green | refactoring | completed
      commits: []
      notes: []

# Definition of Done
definition_of_done:
  checks:
    - name: "Tests pass"
      run: "[TEST_COMMAND]"
    - name: "Lint clean"
      run: "[LINT_COMMAND]"
    - name: "Type check"
      run: "[TYPE_CHECK_COMMAND]"
    - name: "Acceptance criteria"
      run: "<PBI acceptance_criteria.verification commands>"

# Completed Sprints (keep latest 2-3 only)
completed: []

# Retrospectives
# timing: immediate (do now) | sprint (next sprint subtask) | product (new PBI)
retrospectives: []
```

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

Save the generated content to `scrum.yaml` in the project root.

### Step 5: Confirm and Guide

After creating the file:

1. Confirm the file was created at `[project_root]/scrum.yaml`
2. Explain next steps:
   - Review and refine the initial PBIs
   - Change status from `draft` to `ready` when stories are complete
   - Run Sprint Planning to start the first sprint
3. Mention the core principles:
   - **Single Source of Truth**: All agents read/write `scrum.yaml`
   - **Git is History**: No timestamps needed
   - **Order is Priority**: Higher in list = higher priority
   - **Dashboard Compaction**: Keep ≤300 lines (prune after retrospectives)

---

**Begin by asking the user the required questions one section at a time.**
