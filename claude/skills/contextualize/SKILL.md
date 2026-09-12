---
name: contextualize
description: Generates per-directory .context.md files for quick orientation.
argument-hint: "[optional root directory]"
user-invocable: true
allowed-tools: Read, Write, Grep, Glob, Bash, Agent
model: sonnet
effort: high
context: fork
---

# Contextualize — Per-Directory Orientation

Generate `.context.md` files for the project: `$ARGUMENTS`

## What a .context.md is

A quick orientation file per directory. It is not complete documentation — it is a navigation guide so humans and agents can quickly understand what each folder does.

## Schema

```markdown
<!-- .context.md — generated on YYYY-MM-DD -->
## Purpose
[1-2 sentences: what this directory contains and why]

## Files
- `file.ts` — [responsibility in 1 line]
- `other.ts` — [responsibility in 1 line]

## Subdirectories
- `sub/` — [purpose in 1 line]

## Constraints (optional)
- MUST: [mandatory rule for this module]
- MUST NOT: [prohibition]

## Guidance (optional)
- SHOULD: [recommendation]
```

## Process

### 1. Determine the scope
- If `$ARGUMENTS` is provided, use it as the root
- If not, use the project's current directory
- Exclude: `node_modules/`, `.git/`, `dist/`, `__pycache__/`, `.memory/`

### 2. Walk the directories
For each directory containing code files:
1. List files and subdirectories
2. Read the first ~50 lines of each key file
3. Identify the purpose from the structure, imports, and exports
4. Generate a `.context.md` following the schema

### 3. Generation rules
- **Never invent a purpose** — if you do not know, write "Purpose unclear — needs investigation"
- **Brevity** — one line per entry
- **Update, do not recreate** — if `.context.md` already exists, compare and update only what changed
- **Same commit** — `.context.md` must be in the same commit as structural changes

### 4. Report
```
## Contextualize — Report

### Directories covered
- [X] `src/` — [status: created/updated/unchanged]
- [X] `src/utils/` — [status]

### Coverage
[X/Y] directories with a .context.md

### Pending
- `src/legacy/` — purpose unclear, needs investigation
```

## When to use
- A new project without documentation
- Onboarding new members
- Before a large refactor (mapping the terrain)
- After significant structural changes
