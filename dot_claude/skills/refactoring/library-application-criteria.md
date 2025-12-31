# Library vs Application Criteria

Refactoring scope differs based on whether the code is a **library** or an **application**.

## The Key Distinction

| Type | External Consumers? | Public API Refactorable? |
|------|---------------------|--------------------------|
| **Library** | Yes (unknown callers) | No — breaking change |
| **Application** | No (you control all callers) | Yes — internal restructuring |

## Library Constraints

Libraries have **external consumers** who depend on the public API:

```
┌─────────────────────────────────────┐
│        External Consumers           │
│  (other packages, unknown callers)  │
└────────────────┬────────────────────┘
                 │ ← PUBLIC API BOUNDARY (frozen)
┌────────────────▼────────────────────┐
│   Exported Symbols (pub, export)    │
│   - Function signatures             │
│   - Type definitions                │
│   - Module paths (if re-exported)   │
└────────────────┬────────────────────┘
                 │ ← safe to refactor below
┌────────────────▼────────────────────┐
│      Internal Implementation        │
│   - Private functions               │
│   - Internal modules                │
│   - Data structures                 │
└─────────────────────────────────────┘
```

**NOT allowed for libraries:**
- Renaming exported functions/types
- Changing function signatures (parameters, return types)
- Removing or renaming public modules
- Changing default values of public parameters

## Application Freedom

Applications have **no external consumers** — you control all the code:

```
┌─────────────────────────────────────┐
│         Your Application            │
│   (you control all the code)        │
└────────────────┬────────────────────┘
                 │ ← no external boundary
┌────────────────▼────────────────────┐
│        All Code is Internal         │
│   - Entry points (main, handlers)   │
│   - Services and modules            │
│   - Internal APIs                   │
└─────────────────────────────────────┘
```

**Allowed for applications:**
- Renaming any function/type (update all call sites)
- Changing function signatures (update all callers)
- Reorganizing module structure freely
- Changing internal API contracts

## How to Identify

| Signal | Library | Application |
|--------|---------|-------------|
| Published to package registry | ✅ | ❌ |
| Has `lib.rs` / `index.ts` exports | ✅ | Maybe |
| Other repos depend on it | ✅ | ❌ |
| Has CLI entry point only | ❌ | ✅ |
| Deployed as a service | ❌ | ✅ |
| You control all consumers | ❌ | ✅ |

## Hybrid Cases

Some projects are both:

```
my-project/
├── src/lib/        # Library code (API frozen)
├── src/cli/        # CLI application (freely refactorable)
└── src/server/     # Server application (freely refactorable)
```

Apply library constraints only to the library portion.
