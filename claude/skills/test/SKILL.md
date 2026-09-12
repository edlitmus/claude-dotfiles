---
name: test
description: Generates tests for existing code, or runs the project's test suite.
argument-hint: "[file to generate tests for | 'run' to run the suite]"
user-invocable: true
allowed-tools: Read, Edit, Write, Grep, Glob, Bash, Agent
model: sonnet
effort: high
---

# Test

## If the argument is "run" or empty
Detect and run the project's test suite:
```bash
# Detect the framework
[ -f pytest.ini ] || [ -f pyproject.toml ] && pytest -v
[ -f package.json ] && npm test
[ -f go.mod ] && go test -v ./...
```

Show the formatted result:
```
## Test results
- Total:   X
- Passed:  X ✅
- Failed:  X ❌
- Skipped: X ⏭️
- Time:    Xs
```

## If a file is provided
Generate tests for: `$ARGUMENTS`

### Process
1. Read the file and understand the public functions/classes.
2. Identify the project's test framework (pytest, jest, vitest, go test).
3. Generate tests covering:
   - **Happy path**: the main flow working
   - **Edge cases**: null, empty, boundaries, wrong types
   - **Errors**: expected exceptions, error handling
4. Use the AAA pattern (Arrange → Act → Assert).
5. Descriptive names: `test_should_return_404_when_user_not_found`.
6. Put the test file in the project's correct location:
   - Python: `tests/test_<name>.py` or alongside as `<name>_test.py`
   - JS/TS: `__tests__/<name>.test.ts` or `<name>.spec.ts`
   - Go: `<name>_test.go` in the same package

### After generating
Run the tests to validate that they pass:
```bash
# Run only the generated tests
```
