# ADR Queries

How to find and read existing Architecture Decision Records.

## Finding ADRs

### By Topic/Keyword

```bash
# Search ADR content for keywords
grep -ri "authentication" docs/ADR/
grep -ri "database" docs/ADR/

# List all ADR titles (first heading)
head -1 docs/ADR/*.md
```

### By Status

```bash
# Active ADRs (no _ prefix)
ls docs/ADR/*.md | grep -v "^_"

# Deprecated/Superseded ADRs (_ prefix)
ls docs/ADR/_*.md

# Find by status in content
grep -l "Status.*accepted" docs/ADR/*.md
grep -l "Status.*deprecated" docs/ADR/*.md
```

### By Date Range

```bash
# ADRs from 2025 (timestamp naming)
ls docs/ADR/2025*.md

# Recent ADRs (last 30 days by file modification)
find docs/ADR -name "*.md" -mtime -30
```

## Reading ADRs

When summarizing an ADR for the user, extract:

1. **Title**: What decision was made
2. **Status**: Is it active, deprecated, or superseded?
3. **Context**: Why was this decision needed?
4. **Decision**: What was chosen and why?
5. **Consequences**: What are the trade-offs?

### Quick Summary Format

```
**[Title]** (Status: accepted)

**Decision**: We chose X because of Y.

**Key trade-offs**:
- (+) Benefit 1
- (-) Trade-off 1

**Related**: ADR-0005, ADR-0012
```

## Checking ADR Alignment

Before implementing a feature:

1. **Search for related ADRs** by domain keywords
2. **Check if decision still applies** (not deprecated/superseded)
3. **Note any constraints** from the ADR's consequences
4. **Plan to reference ADR** in implementation commits

### Alignment Questions

- Does an ADR exist for this domain?
- Is the ADR still active (no `_` prefix, status not deprecated)?
- Does my implementation follow the decision?
- If deviating, should I create a superseding ADR?
