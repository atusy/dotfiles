---
description: Start the RED phase - Write a small, focused failing test
---

## TDD RED Phase: Write a Failing Test

You are entering the **RED** phase of Kent Beck's TDD cycle. Your goal is to write ONE small, focused failing test.

### Phase Rules

- **NO COMMIT** during RED phase (you are not in a safe state)
- This phase occurs **EXACTLY ONCE** per cycle
- Write **ONE** failing test or add **ONE** failing assertion to an existing test

### Writing Your Test

**1. Choose a test name that describes behavior:**
- Good: `shouldAuthenticateValidUser`, `test_empty_input_returns_error`
- Bad: `testAuth`, `test1`

**2. Keep the test small:**
- Test ONE specific behavior
- If you are thinking "and also...", stop - that is a second test

**3. The test must fail for the RIGHT reason:**
- Missing implementation (expected)
- NOT syntax errors or typos

### Beck's Strategy Preview

Before writing, consider which strategy you will use in GREEN:

| Confidence Level | Strategy | Description |
|------------------|----------|-------------|
| Uncertain | **Fake It** | Return a constant to pass |
| Confident | **Obvious Implementation** | Type the real solution |
| Generalizing | **Triangulation** | Add test to break a fake |

### When to Split Into a New Test

Consider creating a separate test function when:
- You're testing a **different behavior** (not just another case of the same behavior)
- The new assertion requires **different setup** than existing assertions
- You're unsure which assertion would fail first (tests should have clear failure points)

### Checklist Before Proceeding

- [ ] Test has a descriptive name explaining the expected behavior
- [ ] Test is small and focused on ONE thing
- [ ] Test FAILS (verify by running tests)
- [ ] Test fails for the RIGHT reason (not syntax/typo)

### Defect-Driven Testing (Bug Fixing with TDD)

When a bug is discovered, use this special RED phase protocol:

**1. First**: Write a failing test that reproduces the bug
   - This test should fail with the current code
   - Make the test as small as possible
   - The test documents the bug forever

**2. Second**: Make the minimal fix to pass the test (in GREEN phase)
   - No additional "while I'm here" changes
   - Keep the fix focused

**3. Third**: Verify the bug can never return
   - The test now guards against regression
   - Add to your test suite permanently

```python
# Bug: Users with empty passwords can log in

# Step 1: Write failing test that reproduces bug
def test_empty_password_should_fail_authentication():
    result = auth.login("user@example.com", "")
    assert result.success == False  # This FAILS with buggy code

# Step 2 (GREEN phase): Fix with minimal change
def login(email, password):
    if not password:  # Add this guard
        return AuthResult(success=False)
    # ... rest of implementation

# Step 3: Test passes, bug can never return
```

**Two-Level Testing for Critical Bugs:**
- **API-level test**: Ensures the user-facing behavior is fixed
- **Unit test**: Pinpoints the exact code that was broken
- **Together**: Provide defense in depth against regression

### Next Step

Once your test fails for the right reason, proceed to `/tdd:green` to make it pass.

---

**Remember**: Each RED phase adds exactly ONE failing test or ONE failing assertion. Keep iterations small!
