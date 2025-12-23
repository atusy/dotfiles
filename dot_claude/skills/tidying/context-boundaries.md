# Context-Specific Boundaries

What counts as "behavior" differs by context. The behavior boundary determines what's safe to tidy.

## Quick Reference

| Context | Behavior = ? | Safe to Tidy | Risky to Change |
|---------|--------------|--------------|-----------------|
| **Frontend** | Visual output + interactions | Component internals, hooks, state shape | CSS class names (if external), DOM structure (if tested) |
| **Backend** | API responses + side effects | Service internals, query structure | Response schema, HTTP status codes |
| **CLI** | Command output + exit codes | Parsing logic, internal functions | Flag names, output format |
| **Library** | Public API contracts | Private functions, internal modules | Any exported symbol |

## The Surface Area Model

```
┌─────────────────────────────────────────┐
│              External World             │
│   (users, other services, consumers)    │
└────────────────────┬────────────────────┘
                     │ ← BEHAVIOR BOUNDARY (don't change!)
┌────────────────────▼────────────────────┐
│            Public Interface             │
│  (API routes, CLI flags, exports)       │
└────────────────────┬────────────────────┘
                     │ ← safe to restructure below
┌────────────────────▼────────────────────┐
│           Internal Structure            │
│  (services, helpers, private modules)   │
└─────────────────────────────────────────┘
```

**Tidying freedom increases as you go deeper.**

## Context-Specific Examples

### Frontend

```jsx
// SAFE: extract hook (same render output)
function UserProfile() {
  const user = useUser();  // extracted from inline useState/useEffect
  return <div>{user?.name}</div>;
}
```

### Backend

```python
# SAFE: extract to service layer (same API response)
@app.get("/users/{id}")
def get_user(id):
    return user_service.get_by_id(id)  # extracted from inline db query
```

### CLI

```bash
# Behavior includes exit codes, stdout format, flag names
# SAFE: refactor internal argument parsing
# UNSAFE: --config → --configuration (breaks scripts!)
```

### Library

```rust
// Libraries have STRICTEST constraints
mod internal {
    pub(crate) fn helper() { }  // crate-private, safe to change
}

// UNSAFE: any public signature change
pub fn process(input: &str) -> Result<String, Error>
//                    ^^^^^ changing type = breaking change
```

## Library Special Considerations

- You don't know who uses your code or how
- Semver exists because public API changes ARE behavioral changes to consumers
- Internal structure is free; public surface is frozen
- Use `internal`/`private` modules for maximum tidying freedom
