---
name: ship
description: Prepares the code for deployment — runs lint and tests, validates the build, and creates a commit/PR if everything passes.
argument-hint: "[optional commit message]"
user-invocable: true
allowed-tools: Read, Edit, Write, Grep, Glob, Bash
model: sonnet
effort: high
---

# Ship — Prepare for deployment

Run the full validation pipeline before delivering the code.

## Pipeline
Run each stage in order. Stop if any of them fails.

### 1. Status
```bash
git status
git diff --stat
```
Show what is going to be delivered.

### 2. Lint & Format
Run the project's lint tools:
- Python: `ruff check --fix && ruff format`
- JS/TS: `npx eslint --fix && npx prettier --write`
- Go: `gofmt -w && golangci-lint run --fix`
- SQL: `sqlfluff fix`

Detect from the project which languages are present.

### 3. Tests
Detect and run the test suite:
- Python: `pytest` or `python -m pytest`
- JS/TS: `npm test` or `npx vitest run` or `npx jest`
- Go: `go test ./...`

### 4. Build (if applicable)
- JS/TS: `npm run build` or `npx tsc --noEmit`
- Go: `go build ./...`
- Python: check syntax with `python -m py_compile`

### 5. Commit
If every stage passed:
- Stage the changed files
- Create the commit with the provided message, or generate one from the changes
- Use conventional prefixes: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`

### 6. Final report
```
## Ship Report
- Lint:    ✅/❌
- Tests:   ✅/❌ (X passed, Y failed)
- Build:   ✅/❌/N/A
- Commit:  [hash] message
```

If something failed, show the error and suggest how to fix it.
