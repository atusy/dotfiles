# MADR Template

Use this structure for all ADRs:

```markdown
# [Short Title of Solved Problem and Solution]

| | |
|---|---|
| **Status** | [proposed \| accepted \| deprecated \| superseded by [ADR-XXXX](link)] |
| **Date** | YYYY-MM-DD |
| **Decision-makers** | [list names or roles] |
| **Consulted** | [list or link to consultation] |
| **Informed** | [list stakeholders to inform] |

## Context and Problem Statement

[Describe the context and problem in 2-3 sentences. What is the issue motivating this decision?]

## Decision Drivers

* [Driver 1: e.g., scalability requirements]
* [Driver 2: e.g., team expertise]
* [Driver 3: e.g., maintenance burden]

## Considered Options

1. [Option 1]
2. [Option 2]
3. [Option 3]

## Decision Outcome

**Chosen option**: "[Option N]", because [justification linking back to decision drivers].

### Consequences

**Positive:**
* [Benefit 1]
* [Benefit 2]

**Negative:**
* [Trade-off 1]
* [Trade-off 2]

**Neutral:**
* [Side effect that is neither clearly positive nor negative]

### Confirmation

[How will we verify this decision is implemented correctly? What tests, reviews, or metrics?]

## Pros and Cons of the Options

### [Option 1]

[Brief description]

* Good, because [argument]
* Good, because [argument]
* Neutral, because [argument]
* Bad, because [argument]

### [Option 2]

[Brief description]

* Good, because [argument]
* Bad, because [argument]

### [Option 3]

[Brief description]

* Good, because [argument]
* Bad, because [argument]

## More Information

[Links to related ADRs, documentation, or external resources. Implementation timeline if relevant.]
```

## Section Guidance

| Section | Purpose | Tips |
|---------|---------|------|
| **Status** | Track lifecycle | Start as "proposed", update when implemented |
| **Context** | Explain the situation | Focus on WHY this decision is needed NOW |
| **Decision Drivers** | List constraints | These justify the final choice |
| **Considered Options** | Show alternatives | At least 2 genuine options |
| **Decision Outcome** | State the choice | Link back to drivers |
| **Consequences** | Document trade-offs | Include negatives honestly |
| **Confirmation** | Define success | How will you know it worked? |
| **Pros/Cons** | Detailed analysis | Compare options fairly |
