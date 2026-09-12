---
name: debug
description: Bug investigation and resolution — analyzes the error, identifies the root cause, and proposes a fix.
argument-hint: "<error description or file containing the bug>"
user-invocable: true
allowed-tools: Read, Edit, Write, Grep, Glob, Bash, Agent
model: sonnet
effort: high
---

# Debug

Investigate and resolve the bug: `$ARGUMENTS`

## Methodology

### 1. Reproduce
- Understand the reported error (message, stacktrace, behavior).
- If possible, reproduce it locally.
- Identify when it works vs when it fails.

### 2. Isolate
- Locate the file and line where the error occurs.
- Trace the data flow: where does the input come from? What does it pass through?
- Use `git log` and `git blame` to understand recent changes to that code.

### 3. Diagnose
Identify the **root cause** (not the symptom):
- Unexpected state? Race condition?
- Unvalidated input? Wrong type?
- Failing external dependency?
- A recent change that broke a contract?
- An unhandled edge case?

### 4. Fix
- Minimal, focused fix — do not refactor while debugging.
- Add a test reproducing the bug BEFORE the fix.
- Verify the test fails without the fix and passes with it.

### 5. Report
```
## 🐛 Debug Report
**Error**: [description]
**Root cause**: [explanation]
**File**: [path:line]
**Fix**: [what was done]
**Test**: [test added]
**Prevention**: [how to avoid it in the future]
```

## Tips
- Read the stacktrace from the bottom up.
- `git bisect` to find the commit that introduced the bug.
- Add temporary logs if needed (remove them afterwards).
- Distrust the obvious — the bug is often one level up.
