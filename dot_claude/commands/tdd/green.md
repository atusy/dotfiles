---
description: Complete the GREEN phase - Make the test pass with minimal code
---

## TDD GREEN Phase: Make the Test Pass

You are entering the **GREEN** phase. Your goal is to make the failing test pass with a **minimal behavioral change**.

### Phase Rules

- This phase occurs **EXACTLY ONCE** per cycle
- Do NOT add unnecessary functionality
- Ignore code quality temporarily - that is for REFACTOR phase

### Beck's Three Strategies

Choose based on your confidence level:

#### 1. Fake It (Till You Make It)
**Use when**: You are unsure how to implement the real solution

```python
# Test: assert add(1, 1) == 2
def add(a, b):
    return 2  # Fake it! Just return the expected constant
```

- Return a constant that makes the test pass
- Gradually replace constants with variables via Triangulation

#### 2. Obvious Implementation
**Use when**: The solution is clear and you are confident

```python
# Test: assert add(1, 1) == 2
def add(a, b):
    return a + b  # Obviously correct, just type it
```

- Type in the real implementation directly
- **Warning**: If it fails, fall back to Fake It

#### 3. Triangulation
**Use when**: You faked it and need to generalize

```python
# First test passed with fake: return 2
# Add second test to force generalization:
def test_add_two_and_three():
    assert add(2, 3) == 5  # This breaks the fake!

# Now must implement real logic
def add(a, b):
    return a + b  # Triangulation forced this
```

### Strategy Selection Criteria

**Use Fake It when:**
- Implementation would require > 1 new function
- Algorithm is unclear after reading the test
- Multiple conditionals or branches needed
- You've already tried Obvious Implementation and it failed

**Use Obvious Implementation when:**
- Single expression or statement suffices
- Pattern matches existing code in codebase
- Implementation is a direct translation of the test

**Use Triangulation when:**
- You faked it and need to generalize
- The abstraction is not yet clear
- You want to discover the design through tests

### Checklist Before Commit

- [ ] Test passes (run all tests to confirm)
- [ ] Implementation is minimal (no extra features)
- [ ] You used an appropriate strategy for your confidence level

### Commit Your Progress

**GREEN = SAFE**. You now have a working checkpoint you can always return to.

Run `/git:commit` to commit this behavioral change.

### Next Step

After committing, proceed to `/tdd:refactor` to improve code quality while keeping tests green.

---

**Remember**: Do NOT refactor yet! Get to green first, commit, THEN improve the code.
