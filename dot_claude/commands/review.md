* Invoke @"general-purpose (agent)" subagent to create a review report by
    * orchestrate 10 @general-purpose subagents asking for strict multi-perspective review
    * fact check the review result and create a final report

```mermaid
sequenceDiagram
    participant U as User
    participant C as Claude Code
    participant GP as general-purpose<br/>(agent)
    participant E0 as Explore<br/>(Perspective 1)
    participant E1 as Explore<br/>(Perspective 2)
    participant E9 as Explore<br/>(Perspective N)

    U->>C: /review
    C->>GP: Create review report

    par Multi-perspective Review
        GP->>E0: Review Topic 0
        GP->>E1: Review Topic 1
        %% ...
        GP->>E9: Review Topic 9
    end

    E0-->>GP: Findings
    E1-->>GP: Findings
    %% ...
    E9-->>GP: Findings

    Note over GP: Fact-check & consolidate

    GP-->>C: Final review report
    C-->>U: Present report
```
