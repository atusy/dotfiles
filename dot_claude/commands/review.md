* Invoke @"general-purpose (agent)" subagent to create a review report by
    * orchestrating @"Explore (agent)" subagents asking for strict multi-perspective review
    * fact check the review result and create a final report

```mermaid
sequenceDiagram
    participant U as User
    participant C as Claude Code
    participant GP as general-purpose<br/>(agent)
    participant E1 as Explore<br/>(Perspective 1)
    participant E2 as Explore<br/>(Perspective 2)
    participant En as Explore<br/>(Perspective N)

    U->>C: /review
    C->>GP: Create review report

    par Multi-perspective Review
        GP->>E1: Review (e.g., correctness)
        GP->>E2: Review (e.g., security)
        GP->>En: Review (e.g., performance)
    end

    E1-->>GP: Findings
    E2-->>GP: Findings
    En-->>GP: Findings

    Note over GP: Fact-check & consolidate

    GP-->>C: Final review report
    C-->>U: Present report
```
