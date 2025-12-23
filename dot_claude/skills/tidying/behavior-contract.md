# Behavior Contract

Behavior isn't just output — it's the full contract between code and its callers.

## The Complete Definition

```
BEHAVIOR = What inputs are ACCEPTED
         + How inputs are VALIDATED/TRANSFORMED
         + What outputs are PRODUCED
         + What side effects OCCUR
         + What errors are RAISED (and when)
```

**If tests pass before and after, it was structural. If they fail, you changed behavior.**

## Structural vs Behavioral Changes

| Structural (Safe to Tidy) | Behavioral (Not Tidying) |
|---------------------------|--------------------------|
| Rename variable `x` → `userId` | Add new validation logic |
| Extract method for readability | Fix a bug in calculation |
| Reorder functions in file | Change how errors are handled |
| Remove dead code | Modify return values |
| Improve indentation/formatting | Add/remove accepted input types |

## Input-Related Behavioral Changes

Often overlooked — changing what inputs are accepted IS behavioral:

| Change | Behavioral? | Why |
|--------|-------------|-----|
| Add required parameter | ✅ Yes | Existing calls break |
| Remove parameter | ✅ Yes | Callers may break |
| Change parameter type | ✅ Yes | Type checks may fail |
| Add stricter validation | ✅ Yes | Previously valid input rejected |
| Relax validation | ✅ Yes | Previously invalid input accepted |
| Change default value | ✅ Yes | Callers relying on default affected |
| Rename keyword parameter | ✅ Yes | Named calls break |

## The Symmetry Principle

```
Callers depend on:          Code depends on:
├─ What they can SEND  ←→  ├─ What it will ACCEPT
├─ What they'll GET    ←→  ├─ What it will RETURN
└─ What will HAPPEN    ←→  └─ What effects it CAUSES
```

Changing **any** side = behavioral change.

## Safe Structural Changes (Input-Related)

```python
# SAFE: Internal destructuring
def process(data):
    name, age = data["name"], data["age"]  # reorganized, same acceptance

# SAFE: Internal variable naming
def calculate(value):
    multiplied = value * 2  # renamed from 'x', same behavior
    return multiplied
```
