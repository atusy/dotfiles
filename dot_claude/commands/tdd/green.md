---
description: Complete the GREEN phase - Make the test pass with minimal code
---

## TDD GREEN Phase: Make the Test Pass

You are entering the **GREEN** phase. Your goal is to make the failing test pass with **minimal code**.

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

Triangulation forces your code to become general through multiple examples:

```python
# Test 1: Can fake with constant
def test_add_one_and_one():
    assert add(1, 1) == 2

# Fake implementation (passes Test 1)
def add(a, b):
    return 2  # Fake it!

# Test 2: Forces generalization (Triangulation)
def test_add_two_and_three():
    assert add(2, 3) == 5  # This breaks the fake!

# Now must implement real solution
def add(a, b):
    return a + b  # Triangulation forced this!
```

**When to use Triangulation:**
- When you are uncertain about the algorithm
- When the abstraction is not obvious
- When you want to discover the design through tests

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

### Extended Example: Authentication Service

This example shows the complete GREEN phase using all three strategies across multiple cycles:

```python
# ============================================================
# CYCLE 1: Fake It strategy (uncertain about implementation)
# ============================================================

# Test (from RED phase):
def test_should_authenticate_valid_user():
    auth = AuthenticationService()
    result = auth.authenticate("test@example.com", "password123")
    assert result.is_authenticated == True

# GREEN - Use "Fake It" strategy
class AuthenticationService:
    def authenticate(self, email, password):
        return AuthResult(is_authenticated=True)  # Fake it!

# Run test: PASSES! -> /git:commit

# ============================================================
# CYCLE 2: Triangulation forces real implementation
# ============================================================

# Test (from RED phase) - breaks the fake:
def test_should_reject_invalid_password():
    auth = AuthenticationService()
    result = auth.authenticate("test@example.com", "wrong_password")
    assert result.is_authenticated == False  # This FAILS with our fake!

# GREEN - Triangulation forced real logic
class AuthenticationService:
    def __init__(self):
        self.valid_credentials = {"test@example.com": "password123"}

    def authenticate(self, email, password):
        if self.valid_credentials.get(email) == password:
            return AuthResult(is_authenticated=True)
        return AuthResult(is_authenticated=False)

# Run ALL tests: BOTH PASS! -> /git:commit

# ============================================================
# CYCLE 3: Obvious Implementation (confident about solution)
# ============================================================

# Test (from RED phase):
def test_should_return_token_on_success():
    auth = AuthenticationService(mock_repository)
    result = auth.authenticate("test@example.com", "password123")
    assert result.token is not None

# GREEN - Use "Obvious Implementation" (we know how to do this)
def authenticate(self, email, password):
    user = self.user_repository.find_by_email(email)
    if user and user.verify_password(password):
        token = self._generate_token(user)  # Obvious implementation
        return AuthResult(is_authenticated=True, token=token)
    return AuthResult(is_authenticated=False, token=None)

# Run tests: PASS -> /git:commit
```

**Key Insights:**
1. **Fake It** (Cycle 1): Started with hardcoded `True` - fastest path to green
2. **Triangulation** (Cycle 2): Second test forced real implementation
3. **Obvious Implementation** (Cycle 3): Used when confident about the solution
4. **Cycle times**: Each cycle was 2-5 minutes, not hours

### Checklist Before Commit

- [ ] Test passes (run all tests to confirm)
- [ ] Implementation is minimal (no extra features)
- [ ] You used an appropriate strategy for your confidence level

### Commit Your Progress

**GREEN = SAFE**. You now have a working checkpoint you can always return to.

Run `/git:commit` to commit this behavioral change. The commit will be typed as:
- `feat:` for new functionality
- `fix:` for bug fixes
- `test:` for test additions

### Next Step

After committing, proceed to `/tdd:refactor` to improve code quality while keeping tests green.

---

**Remember**: Do NOT refactor yet! Get to green first, commit, THEN improve the code.
