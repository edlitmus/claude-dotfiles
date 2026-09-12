---
name: tdd
description: Test-Driven Development — strict RED-GREEN-REFACTOR cycle.
argument-hint: "<feature to implement>"
user-invocable: true
allowed-tools: Read, Edit, Write, Grep, Glob, Bash, Agent
model: sonnet
effort: high
context: fork
---

# TDD — Test-Driven Development

Implement using strict TDD: `$ARGUMENTS`

## RED → GREEN → REFACTOR cycle

### 🔴 RED — Write the test FIRST
1. Understand the expected behavior
2. Write ONE test describing that behavior
3. **Run the test — IT MUST FAIL**
4. If the test passes without an implementation → the test is wrong

```bash
# Check that the test fails
npm test -- --run [file]  # or pytest, go test
```

**RULE**: Never move on to GREEN if the test did not fail first.

### 🟢 GREEN — Minimal implementation
1. Write the MINIMUM code to make the test pass
2. Do not optimize, do not embellish, do not generalize
3. **Run the test — IT MUST PASS**
4. If it does not pass → fix the implementation (not the test)

**RULE**: The minimal fix. If the test expects `return 42`, return a literal `42`.

### 🔵 REFACTOR — Improve without changing behavior
1. All tests passing? You may refactor
2. Improve: naming, duplication, structure
3. **Run the tests again — THEY MUST KEEP PASSING**
4. If a test broke → undo the refactor

**RULE**: Refactor only with all tests green.

## Protocol

### One test at a time
Do not write 5 tests and then implement everything. The cycle is:
```
1 test RED → 1 implementation GREEN → refactor → next test
```

### Test naming
Describe the behavior, not the method:
- ✅ `should return 404 when user not found`
- ✅ `should calculate total with discount applied`
- ❌ `test_get_user`
- ❌ `testCalculate`

### Scenario coverage (in order)
1. **Happy path** — the most common case
2. **Edge cases** — null, empty, boundaries, zero
3. **Errors** — exceptions, timeouts, invalid inputs
4. **Concurrency** — race conditions (if applicable)

## Anti-patterns (FORBIDDEN)

| Anti-pattern | Correct |
|---|---|
| Writing the implementation before the test | Test first, always |
| A test that never fails (tautology) | A test must be falsifiable |
| Multiple tests before implementing | One test at a time |
| Refactoring with failing tests | Green before refactoring |
| Testing internal implementation | Test observable behavior |

## When to use
- A new feature that needs guaranteed coverage
- A bug fix (write a test reproducing the bug → fix → green)
- Complex logic where edge cases matter
