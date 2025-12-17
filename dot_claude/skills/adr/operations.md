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

---

## ADR-Aligned Development

### Before Implementation

1. **Search for relevant ADRs** by domain (auth, database, API, etc.)
2. **Check ADR status** — is it active or superseded?
3. **Note constraints** from the decision's consequences
4. **Plan commit references** to the ADR

### During Implementation

Reference ADRs in commits when implementing related code:

```
feat(auth): add JWT token validation

Following ADR 20250115-use-jwt-auth.md, tokens are validated
server-side with RS256 signatures per the security decision.
```

### On Completion

When implementation is complete, update ADR status:

```bash
# Edit the ADR to change status from "proposed" to "accepted"
# Add implementation date and any lessons learned

git add docs/ADR/20250115-use-jwt-auth.md
git commit -m "docs(adr): mark JWT auth decision as accepted

Implementation complete in auth/ module. Token rotation
added as enhancement beyond original scope."
```

### On Deviation

If implementation must deviate from an existing ADR:

1. **Create new ADR** explaining the new decision
2. **Reference the old ADR** in "supersedes" field
3. **Deprecate old ADR** with `_` prefix
4. **Commit both changes** together

```bash
# Create new ADR, then deprecate old one
git mv docs/ADR/20250115-use-rest-api.md \
       docs/ADR/_20250115-use-rest-api.md
git add docs/ADR/20250620-use-graphql.md
git commit -m "docs(adr): supersede REST API with GraphQL decision

REST API couldn't handle nested resource queries efficiently.
GraphQL provides flexible querying needed for mobile clients.
See 20250620-use-graphql.md for full rationale."
```
