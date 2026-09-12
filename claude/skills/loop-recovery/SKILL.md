---
name: loop-recovery
description: Detects and recovers from retry loops, oscillation, or drift. Use when you notice you are repeating actions without progress.
argument-hint: "[optional problem description]"
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Bash
model: sonnet
effort: high
---

# Loop Recovery

Stop, analyze, and recover from an unproductive pattern.

## Diagnosis — Identify the pattern

### 1. Oscillation (A → B → A → B)
Are you alternating between two approaches without converging?
```
Signs:
- Undid a change you just made
- Alternating between two implementations
- Reverting and re-applying the same fix
```

### 2. Blind retry (A → A → A)
Are you repeating the same action expecting a different result?
```
Signs:
- The same command failed 2+ times in a row
- The same error appears after every attempt
- Minimal tweaks that do not address the root cause
```

### 3. Drift (expanding scope)
Are you touching files unrelated to the original problem?
```
Signs:
- Edited 5+ files for a fix that should touch 1-2
- You are "fixing" things that were not broken
- You lost sight of the original goal
```

### 4. Rabbit hole (excessive depth)
Are you descending through abstraction layers without solving the surface problem?
```
Signs:
- You are debugging the framework instead of the user's code
- You reached third-party/stdlib code
- The fix requires understanding 5+ layers of indirection
```

## Recovery protocol

### Step 1 — STOP
Do not try one more time. Stop completely.

### Step 2 — Diagnose
Identify which of the 4 patterns above is happening.
List the last 3 actions taken and their results.

### Step 3 — Pivot
Choose ONE pivot strategy based on the diagnosis:

| Pattern | Pivot |
|---|---|
| **Oscillation** | Pick approach A or B definitively. List pros/cons of each. Commit to one. |
| **Blind retry** | Reread the error calmly. Identify the real root cause (not the symptom). Try a FUNDAMENTALLY different approach. |
| **Drift** | Return to the original goal. List only the essential files. Undo unrelated changes. |
| **Rabbit hole** | Climb back up to the level of the user's problem. Consider a workaround instead of a deep fix. |

### Step 4 — Limit
- After 3 failed attempts → change approach completely
- After 2 failed approaches → report to the user with a diagnosis:
  ```
  ## 🔄 Loop Recovery Report
  **Goal**: [what I am trying to do]
  **Attempts**: [numbered list of what I tried]
  **Pattern detected**: [oscillation/retry/drift/rabbit hole]
  **Diagnosis**: [why it is failing]
  **Suggestion**: [a different approach, or a decision that needs the user]
  ```

### Step 5 — Verify the resolution
After the pivot, confirm the new path is making real progress:
- Did the output change? (not just the input)
- Is the error different? (progress, even if partial)
- Are you closer to the goal? (fewer files with problems, tests passing)

If not → go back to Step 3 with another pivot strategy.

## Absolute rule
NEVER try the same approach more than 3 times. If it failed 3x, it is wrong — change it.
