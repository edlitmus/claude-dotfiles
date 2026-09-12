---
name: task-tracking
description: Persists tasks to a file so they survive across sessions.
argument-hint: "[create|update|list|close]"
user-invocable: true
allowed-tools: Read, Write, Grep, Glob, Bash
model: sonnet
effort: medium
---

# Task Tracking — Persistent Todos

Manage persistent tasks: `$ARGUMENTS`

## Why use this (vs TodoWrite)
Claude Code's TodoWrite is **volatile** — it dies with the session. For tasks lasting days/weeks, use this file-based system.

## Structure

### Directory
`.memory/todo/`

### File format
`.memory/todo/YYYY-MM-DD-<prefix>-<slug>.md`

Prefixes: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

### Template
```markdown
# [prefix]: [short description]
**Status**: active | paused | done | cancelled
**Created**: YYYY-MM-DD
**Updated**: YYYY-MM-DD

## Tasks
- [x] Completed task
- [ ] Pending task

## Event Log
- [YYYY-MM-DD HH:MM] Created — initial context
- [YYYY-MM-DD HH:MM] Decision — chose X because Y
- [YYYY-MM-DD HH:MM] Blocked — waiting on Z
- [YYYY-MM-DD HH:MM] Progress — completed tasks 1-3
```

## Workflow

### Create (`create`)
1. Determine the prefix and a descriptive slug (kebab-case)
2. Create the file from the template
3. Log the creation event

### Update (`update`)
1. Locate the file in `.memory/todo/`
2. Tick the completed checkboxes
3. Add a log entry with a timestamp

### List (`list`)
1. List the files in `.memory/todo/`
2. Filter by status (active by default)
3. Show: name, status, progress (X/Y tasks)

### Close (`close`)
1. Mark every task as completed or cancelled
2. Change the status to `done` or `cancelled`
3. Log the closing event

## Rules
- Update the status IMMEDIATELY (do not batch)
- Preserve files with incomplete items
- Log every action with a timestamp
- Keep the file even after it is done (history)
