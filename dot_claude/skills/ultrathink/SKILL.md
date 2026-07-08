---
name: ultrathink
description: Perform deep multi-perspective analysis with problem-specific analytical lenses, cross-validation, and a final recommendation. Use when the user asks to ultrathink, deeply analyze a complex problem, compare strategic options, expose risks, or make a high-impact technical decision.
---

# Ultrathink

Analyze complex problems through multiple independent analytical lenses, then
synthesize a recommendation grounded in evidence.

## Workflow

1. Clarify the problem, desired decision, constraints, and what evidence is
   available.
2. Select 3-5 problem-specific analytical lenses. Choose lenses that reveal
   different blind spots, such as:
   - Feasibility, alternatives, risks, and implications
   - Security, performance, maintainability, and operability
   - User impact, cost, timeline, and migration path
   - Historical context, industry patterns, dependencies, and edge cases
3. Explore each lens independently. Use parallel subagents when tooling allows
   and the task benefits from independent passes.
4. Cross-validate the outputs:
   - Identify consensus and conflicts
   - Verify claims against available evidence
   - Mark unknowns that require investigation
   - Separate assumptions from facts
5. Produce a final recommendation with clear rationale, explicit trade-offs,
   rejected alternatives, and concrete next steps.

## Output Shape

Prefer this order:

1. Recommendation
2. Rationale
3. Key trade-offs
4. Critical risks or unknowns
5. Next steps
