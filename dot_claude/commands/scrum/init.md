---
allowed-tools: Read, Write, Bash(cat:*), Bash(ls:*), Bash(deno:*)
description: Initialize a scrum.ts file based on AI-Agentic Scrum Dashboard template
---

## Initialize AI-Agentic Scrum Dashboard

You are setting up a new project with the AI-Agentic Scrum methodology. This command will create a `scrum.ts` file in the project root that serves as the single source of truth for all Scrum artifacts.

**Reference**: Use the `scrum-dashboard` skill for ongoing dashboard maintenance after initialization.

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

### Step 2: Generate scrum.ts

After gathering information, generate the `scrum.ts` file. The file has two sections:
1. **Type definitions** (fixed schema - do not modify)
2. **Dashboard data** (AI edits this section)

```typescript
// ============================================================
// Type Definitions (DO NOT MODIFY - request human review for schema changes)
// ============================================================

// PBI lifecycle: draft (idea) -> refining (gathering info) -> ready (can start) -> done
type PBIStatus = "draft" | "refining" | "ready" | "done";

// Sprint lifecycle
type SprintStatus = "planning" | "in_progress" | "review" | "done" | "cancelled";

// TDD cycle: pending -> red (test written) -> green (impl done) -> refactoring -> completed
type SubtaskStatus = "pending" | "red" | "green" | "refactoring" | "completed";

// behavioral = changes observable behavior, structural = refactoring only
type SubtaskType = "behavioral" | "structural";

// Commits happen only after tests pass (green/refactoring), never on red
type CommitPhase = "green" | "refactoring";

// When to execute retrospective actions:
//   immediate: Apply within Retrospective (non-production code, single logical change)
//   sprint: Add as subtask to next sprint (process improvements)
//   product: Add as new PBI to Product Backlog (feature additions)
type ImprovementTiming = "immediate" | "sprint" | "product";

type ImprovementStatus = "active" | "completed" | "abandoned";

interface SuccessMetric {
  metric: string;
  target: string;
}

interface ProductGoal {
  statement: string;
  success_metrics: SuccessMetric[];
}

interface AcceptanceCriterion {
  criterion: string;
  verification: string;
}

interface UserStory {
  role: string;
  capability: string;
  benefit: string;
}

interface PBI {
  id: string;
  story: UserStory;
  acceptance_criteria: AcceptanceCriterion[];
  status: PBIStatus;
}

interface Commit {
  hash: string;
  message: string;
  phase: CommitPhase;
}

interface Subtask {
  test: string;
  implementation: string;
  type: SubtaskType;
  status: SubtaskStatus;
  commits: Commit[];
  notes: string[];
}

interface Sprint {
  number: number;
  pbi_id: string;
  goal: string;
  status: SprintStatus;
  subtasks: Subtask[];
}

interface DoDCheck {
  name: string;
  run: string;
}

interface DefinitionOfDone {
  checks: DoDCheck[];
}

interface Improvement {
  action: string;
  timing: ImprovementTiming;
  status: ImprovementStatus;
  outcome: string | null;
}

interface Retrospective {
  sprint: number;
  improvements: Improvement[];
}

interface ScrumDashboard {
  product_goal: ProductGoal;
  product_backlog: PBI[];
  sprint: Sprint | null;
  definition_of_done: DefinitionOfDone;
  completed: Sprint[];
  retrospectives: Retrospective[];
}

// ============================================================
// Dashboard Data (AI edits this section)
// ============================================================

const scrum: ScrumDashboard = {
  product_goal: {
    statement: "[PRODUCT_GOAL_STATEMENT]",
    success_metrics: [
      { metric: "[METRIC_NAME]", target: "[TARGET_VALUE]" },
    ],
  },

  product_backlog: [
    {
      id: "PBI-001",
      story: {
        role: "[USER_ROLE]",
        capability: "[WHAT_THEY_CAN_DO]",
        benefit: "[WHY_IT_MATTERS]",
      },
      acceptance_criteria: [
        {
          criterion: "[CRITERION_DESCRIPTION]",
          verification: "[EXECUTABLE_COMMAND]",
        },
      ],
      status: "draft",
    },
  ],

  sprint: null,

  definition_of_done: {
    checks: [
      { name: "Tests pass", run: "[TEST_COMMAND]" },
      { name: "Lint clean", run: "[LINT_COMMAND]" },
      { name: "Type check", run: "[TYPE_CHECK_COMMAND]" },
    ],
  },

  completed: [],

  retrospectives: [],
};

// JSON output (deno run scrum.ts | jq for queries)
console.log(JSON.stringify(scrum, null, 2));
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
| Go | `go test ./...` | `golangci-lint run` | (use `echo ok` or remove) |

### Step 4: Write the File

Save the generated content to `scrum.ts` in the project root.

### Step 5: Validate and Guide

After creating the file:

1. **Validate the dashboard**:
   ```bash
   deno check scrum.ts
   ```

2. **Confirm the file was created** at `[project_root]/scrum.ts`

3. **Explain next steps**:
   - Review and refine the initial PBIs
   - Change status from `draft` to `ready` when stories are complete
   - Run Sprint Planning to start the first sprint

4. **Mention the core principles**:
   - **Single Source of Truth**: All agents read/write `scrum.ts`
   - **Git is History**: No timestamps needed
   - **Order is Priority**: Higher in list = higher priority
   - **Dashboard Compaction**: Keep ≤300 lines (prune after retrospectives)

5. **Show useful queries**:
   ```bash
   # Current sprint
   deno run scrum.ts | jq '.sprint'

   # Ready PBIs
   deno run scrum.ts | jq '.product_backlog[] | select(.status == "ready")'

   # Red subtasks
   deno run scrum.ts | jq '.sprint.subtasks[] | select(.status == "red")'
   ```

---

**Begin by asking the user the required questions one section at a time.**
