---
name: review
description: Run a strict multi-perspective review with fact-checked findings. Use when the user asks for a review, code review, design review, risk review, or wants independent reviewer perspectives before merging or shipping.
---

# Review

Create a review report by combining independent perspectives and then verifying
the resulting findings against the actual artifacts.

## Workflow

1. Define the review target, scope, and base comparison when relevant.
2. Choose approximately 10 independent review perspectives that fit the work.
   Examples: correctness, tests, security, performance, concurrency, UX,
   maintainability, compatibility, documentation drift, operations, and bot
   anticipation.
3. Run reviewers independently and in parallel when tooling allows subagents.
4. Ask each reviewer for concrete findings with file and line references,
   severity, impact, and suggested fix.
5. Fact-check every finding before reporting it:
   - Read the cited code or artifact directly
   - Confirm the behavior is reachable or the risk is credible
   - Refute false positives with evidence
   - Merge duplicate findings
6. Produce the final report with findings first, ordered by severity, followed
   by open questions and a brief summary.

## Reporting Rules

- Lead with actionable findings, not praise or broad summaries
- Include file and line references for code findings
- State when no actionable findings remain
- Keep speculative concerns out of the final report unless they are explicitly
  framed as open questions
- Distinguish confirmed issues from recommendations
