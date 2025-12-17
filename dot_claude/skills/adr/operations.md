# ADR Operations

## Discovery

Before creating an ADR, detect the project's existing conventions:

### 1. Find ADR Directory

Check in order:
1. `docs/adr/`
2. `docs/ADR/`
3. `doc/adr/`
4. `doc/architecture/decisions/`
5. `adr/`
6. `ADR/`
7. **Fallback**: create `docs/ADR/`

### 2. Detect Naming Convention

Examine existing files to match the project's style:

| Pattern | Example | Detection |
|---------|---------|-----------|
| Sequential | `0001-title.md` | Files start with digits |
| Date-based | `20250115-title.md` | 8-digit prefix |
| Timestamp | `20250115-134032-title.md` | 14-digit prefix |
| **Fallback** | `YYYYMMDD-HHMMSS-slug.md` | Use when no ADRs exist |

### 3. Deprecation Prefix Convention

| State | Filename | Visibility |
|-------|----------|------------|
| Active | `20250115-134032-use-postgresql.md` | Top of listing |
| Deprecated/Superseded | `_20250115-134032-use-postgresql.md` | Bottom of listing |

The `_` prefix visually separates inactive ADRs while preserving history.

### 4. Detect Next Number

If sequential naming is used, scan existing ADRs and increment.

---

## Commit Integration

### Referencing ADRs in Commits

When committing changes that implement an ADR:

```
feat(auth): implement OAuth2 authentication

Implements the authentication strategy decided in ADR-0012.
See docs/ADR/20250115-134032-use-oauth2.md for rationale.
```

### Updating ADR Status

| Transition | Action |
|------------|--------|
| proposed → accepted | Update status in file (implementation complete) |
| → deprecated | Update status + **rename with `_` prefix** |
| → superseded by ADR-XXXX | Update status + **rename with `_` prefix** |

### Rename Command

```bash
# Deprecating an ADR
git mv docs/ADR/20250115-134032-use-rest-api.md \
       docs/ADR/_20250115-134032-use-rest-api.md

# Commit the status change
git commit -m "docs(adr): deprecate REST API decision

Superseded by ADR 20250620-091500-use-graphql.md.
REST API approach had scaling issues beyond 10k requests/sec."
```

Using `git mv` preserves file history for traceability.
