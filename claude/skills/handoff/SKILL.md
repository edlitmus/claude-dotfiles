---
name: handoff
description: Generates a handoff document so the work can continue in a new session. Use when the context is large or before clearing the session.
argument-hint: "[optional handoff file name]"
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash
model: sonnet
effort: high
---

# Session Handoff

Generate a complete handoff document so a new session can continue exactly where we stopped.

## Process

### 1. Collect the current state
```bash
# Branch and status
git branch --show-current
git status --short
git log --oneline -10

# Modified, uncommitted files
git diff --name-only
git diff --cached --name-only
```

### 2. Analyze the conversation
Review the whole current conversation and extract:
- What was originally requested
- What has already been implemented
- What is still pending
- Decisions made and their reasons
- Problems found and how they were resolved
- Problems found and NOT resolved

### 3. Generate the document

Save it as `HANDOFF.md` in the current directory (or under the name given in `$ARGUMENTS`):

```markdown
# Handoff — [Date]

## Context
[What we are doing and why]

## Current state
- Branch: `feature/x`
- Last commit: `abc1234 feat: ...`
- Modified, uncommitted files: [list]

## What was done
1. [Task] — [status: complete/partial]
2. ...

## What is left to do
1. [ ] [Pending task] — [required context]
2. [ ] ...

## Decisions made
| Decision | Reason | Discarded alternative |
|---|---|---|
| ... | ... | ... |

## Known problems
- [Problem] — [status: resolved/pending] — [context]

## To continue
Paste this prompt into the new session:
> Read the HANDOFF.md file in this directory. It contains the context
> from the previous session. Continue where we stopped.

## Key files
[List of the files most relevant to the task in progress]
```

### 4. Confirm
Show a summary of the handoff to the user before saving.

## Post-handoff: Persisting to memory

After creating the handoff file, persist it to semantic memory:

```bash
python3 ~/dotfiles/scripts/memory_bridge.py store \
    --text "$(cat CREATED_HANDOFF_FILE)" \
    --tags "handoff,$(basename $PWD),$(date +%Y-%m-%d)" \
    --project "$(basename $PWD)"
```

Confirm: "✓ Session persisted to semantic memory"
