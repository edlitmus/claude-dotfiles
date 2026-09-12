---
name: agent-memory
description: Manages persistent memory across sessions — long-term and session memory.
argument-hint: "[load|save|review]"
user-invocable: true
allowed-tools: Read, Write, Grep, Glob, Bash
model: sonnet
effort: medium
context: fork
---

# Agent Memory — Persistent Memory

Manage the project's persistent memory: `$ARGUMENTS`

## 2-layer architecture

### Layer 1 — Long-term Memory
**File**: `.memory/long-term.md`

Accumulates reusable insights across ALL sessions:

```markdown
# Long-term Memory

## User Preferences
[How the user likes to work, preferred code style]

## Accumulated Feedback
[Corrections received, validated patterns, rejected approaches]

## Discovered Rules
[Learned constraints that are not in CLAUDE.md]

## Known Issues
[Bugs, quirks, workarounds in the project]

## Project Notes
[Architecture, patterns, decisions, gotchas]
```

### Layer 2 — Session Memory
**Directory**: `.memory/session/`
**Format**: `.memory/session/YYYY-MM-DD-<slug>.md`

```markdown
# Session: [slug]
**Status**: active | paused | done
**Start**: [date]

## Current Work
## Active Todos
- [ ] [item]

## Event Log
- [timestamp] [event]
```

## Signal Protocol

| Tier | Example | Action |
|------|---------|--------|
| **Strong** (explicit) | "Always use Tailwind in this project" | Record immediately |
| **Medium** (correction) | The user corrects your approach | Record the learned pattern |
| **Weak** (implicit) | The user accepts without comment | Observe; record only if it repeats 3x |

## Life Cycle

### At the start (load)
1. Check whether `.memory/` exists; create it if needed
2. Read `.memory/long-term.md` for context
3. Check for paused sessions in `.memory/session/`
4. Offer: resume the paused session or start a new one

### During (observe)
1. Watch for user signals (strong/medium/weak)
2. Update session memory at every significant milestone
3. Never record sensitive data (tokens, passwords, PII)

### At the end (save)
1. Distill the session log into insights for long-term memory
2. Filter: "Will this help future work?" — if not, discard it
3. Mark the session as `done` or `paused`

## Rules
- Only actionable insights go into memory
- Sensitive data NEVER goes into `.memory/`
- Entries must be concise (1-2 lines each)
- At most 80 entries in long-term memory (prune the oldest)
- `.memory/` must be in the project's `.gitignore`
