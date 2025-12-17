---
name: adr
description: Document architectural decisions using MADR format. Use when user says "we should use", "let's go with", "I've decided to", discusses trade-offs between alternatives, selects technologies/frameworks, makes structural changes, deprecates features, or asks "why did we choose X?"
---

# INSTRUCTIONS

Create Architecture Decision Records (ADRs) using the MADR format when architectural decisions are made or discussed.

- **Template**: See `template.md` for the full MADR structure
- **Operations**: See `operations.md` for discovery, naming, and commit integration

## Workflow

1. **Detect decision context** from conversation
2. **Discover project conventions** (see `operations.md`)
3. **Gather information** through clarifying questions:
   - What problem are we solving?
   - What options were considered?
   - What are the key decision drivers?
   - Who should be consulted/informed?
4. **Draft the ADR** using template from `template.md`
5. **Review with user** before saving
6. **Save to appropriate location**
7. **Suggest commit integration** (see `operations.md`)

## Quality Checklist

Before finalizing an ADR:

- [ ] Title clearly states the decision (not the problem)
- [ ] Context explains WHY this decision is needed now
- [ ] At least 2 options were genuinely considered
- [ ] Decision drivers link to actual project constraints
- [ ] Consequences include both positive AND negative impacts
- [ ] Confirmation section describes how to validate the decision

## Anti-Patterns to Avoid

- **Decision without options**: Always document alternatives considered
- **Vague consequences**: Be specific about trade-offs
- **Missing "why"**: The ADR should answer "why this, why now"
- **Premature acceptance**: New ADRs should be "proposed" until implemented
- **Orphan ADRs**: Always link to related ADRs when relevant

## Integration with Documentation Philosophy

Following the principle "Commits explain WHY":
- The ADR captures the full reasoning behind architectural choices
- Commit messages reference ADRs for traceability
- Code comments can link to ADRs for complex implementation details

## Reference

Based on [MADR - Markdown Architectural Decision Records](https://adr.github.io/madr/) (Version 4.0, 2024)
