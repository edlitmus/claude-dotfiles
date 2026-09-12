---
name: review-deep
description: Parallel code review with multiple specialized agents.
argument-hint: "[file or directory]"
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Agent
model: opus
effort: high
context: fork
---

# Review Deep — Parallel Multi-Agent Code Review

Deep review with 4 parallel reviewers: `$ARGUMENTS`

## Scope

### If an argument is provided
Review: `$ARGUMENTS`

### If no argument
```bash
git diff --name-only HEAD
git diff --cached --name-only
```

## Process

### Phase 1 — Preparation
1. Identify the files to review
2. Read each file to understand the context
3. Assemble a briefing: files, purpose, stack

### Phase 2 — Parallel dispatch (4 agents)

Dispatch ALL of them in parallel:

#### Reviewer 1 — Code Quality (backend/frontend)
- Logical correctness, edge cases, types
- Readability, naming, SRP, dead code
- Project standards

#### Reviewer 2 — Security (security)
- OWASP Top 10, input validation, injection
- Secrets, auth, headers, vulnerable deps

#### Reviewer 3 — Test Quality (backend/frontend)
- Coverage: happy path + edge cases
- Descriptive names, AAA, mocks vs integration

#### Reviewer 4 — Consequences (architect)
- Impact on dependents
- Undocumented breaking changes
- Cascading effects, compatibility

### Phase 3 — Consolidation
1. Collect findings from the 4 reviewers
2. Remove duplicates
3. Flag conflicts: "⚠️ Conflict" when reviewers disagree
4. Classify by severity

### Phase 4 — Report

```
## Review Deep — Consolidated Report

### Reviewers
| Reviewer | Findings | Critical | Important |
|----------|----------|----------|-----------|

### 🔴 Critical (blocks merge)
- **[Reviewer]** [file:line] Description
  - Impact: [...]
  - Fix: [...]

### 🟡 Important (must fix)
### 🔵 Suggestion

### ⚠️ Conflicts between reviewers
- [Reviewer A] says X vs [Reviewer B] says Y

### ✅ Positive points

## Verdict: PASS | FAIL | NEEDS DISCUSSION
**Confidence: X/5**
```

## When to use
- `/review` = 1 sequential pass, fast, small changes
- `/review-deep` = 4 parallel agents, large or critical PRs
