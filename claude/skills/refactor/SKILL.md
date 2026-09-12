---
name: refactor
description: Analyzes and refactors code to improve quality, readability, and maintainability without changing behavior.
argument-hint: "<file or directory>"
user-invocable: true
allowed-tools: Read, Edit, Write, Grep, Glob, Bash, Agent
model: sonnet
effort: high
---

# Refactor

Refactor the code in `$ARGUMENTS` while keeping the behavior identical.

## Process

### 1. Analysis
Read the code and identify:
- Duplicated logic
- Very long functions (>30 lines)
- High cyclomatic complexity (many nested if/else)
- Poorly descriptive names
- Mixed responsibilities (god classes/functions)
- Dead code (unused code)
- Circular dependencies

### 2. Plan
Before editing, present a plan:
```
## Refactoring plan
1. [What] — [Why]
2. [What] — [Why]
...
Files affected: X
Risk: low/medium/high
```

Wait for the user's confirmation before proceeding.

### 3. Execution
- One logical change at a time.
- Keep the external behavior identical.
- If there are tests, run them after each significant change.
- Name extractions descriptively.

### 4. Validation
- Run the existing tests.
- Show a summarized diff of the changes.

## Common techniques
- Extract Method/Function
- Rename for clarity
- Replace conditional with polymorphism or strategy
- Introduce Parameter Object
- Remove dead code
- Split module by responsibility
