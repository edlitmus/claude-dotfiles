---
name: compact
description: Summarizes the current session's context to free up the context window.
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash
model: sonnet
effort: medium
context: fork
---

# Compact

Analyze the current conversation history and produce a structured summary of the working context. The goal is to produce a copyable block that lets the work continue in a new session without losing relevant context.

## Process

### 1. Analyze the conversation history
Go through the whole conversation, identifying:
- Which project is being worked on (name, stack, main goal)
- Technical decisions made and the reasons behind them
- Files that were read, created, or modified (with absolute paths)
- Problems diagnosed and resolved
- Tasks started but not yet finished
- The exact point where the work was interrupted

### 2. Complement with the tools
Use the available tools to confirm the current state:
- `Read` to check the current content of modified files
- `Grep` to locate code snippets that were discussed
- `Glob` to list files in mentioned directories
- `Bash` to check the repository state (`git status`, `git log --oneline -5`)

### 3. Produce the summary
Produce the block below in at most 500 words. Focus on actionable context, not on conversation history.

## Summary Format

```
## Session Summary

### Project Context
- **Project**: [name or description]
- **Stack**: [languages, frameworks, main tools]
- **Goal**: [what was being built or solved]
- **Root directory**: [absolute path]

### Decisions Made
- [Decision 1]: [reason in one sentence]
- [Decision 2]: [reason in one sentence]

### Modified Files
- `/absolute/path/file.ext`: [what changed and why]
- `/absolute/path/other.ext`: [what changed and why]

### Problems Resolved
- [Problem description]: [how it was resolved]

### Pending Work
- [ ] [Pending task 1 -- descriptive enough to be picked up without extra context]
- [ ] [Pending task 2]

### Current State
[2-3 sentences describing exactly where the work stopped. Include file and line if applicable.]
```

## Rules

- Limit: 500 words -- cut conversation details, preserve actionable context.
- Always use absolute paths, never relative ones.
- When a file was modified in a specific spot, indicate the line number.
- Clearly distinguish between what is done and what is in progress.
- Do not include long code snippets -- reference the file and line.
- Do not include a history of failed attempts, only the correct final state.

## Final Output

After the summary block, show this instruction to the user:

---

**Paste the summary below into a new session to continue the work:**

> "Continuing a previous session. Context: [paste the block above here]. Resume from the pending items listed."
