---
name: boot
description: Session initialization — checks the environment, loads memory and context.
user-invocable: true
allowed-tools: Read, Write, Grep, Glob, Bash
model: sonnet
effort: medium
---

# Boot — Session Initialization

Run the boot sequence to make sure the environment is configured.

## Checklist (7 steps)

### 1. Query semantic memory
Before any other initialization, look up accumulated project context:
```bash
python3 ~/dotfiles/scripts/memory_bridge.py query \
    --text "$(basename $PWD) project context stack decisions" \
    --top-k 8 \
    --project "$(basename $PWD)" \
    --format markdown
```
- If there are results: incorporate them as context before proceeding
- If there are none: proceed normally (new project or no history)

### 2. Check .gitignore
Make sure `.memory/` is in `.gitignore`:
```bash
grep -q '.memory/' .gitignore 2>/dev/null || echo '.memory/' >> .gitignore
```

### 3. Create the memory structure
```bash
mkdir -p .memory/session .memory/todo .memory/plan
```

### 4. Load long-term memory
- Read `.memory/long-term.md` if it exists
- Apply preferences and feedback to your behavior
- If it does not exist, create it with an empty template (skill `/agent-memory`)

### 5. Check for paused sessions
- List `.memory/session/*.md` with status `paused` or `active`
- If found: "Previous session detected: [slug]. Resume or start a new one?"
- If not found: proceed

### 6. Index the project context
- Check for `.context.md` files in the project
- If absent: suggest `/contextualize`
- Detect the stack (package.json, go.mod, pyproject.toml, etc.)

### 7. Greeting
Report the state to the user:
- Memory: loaded / empty / paused session found
- Stack: detected / not identified
- Ask for instructions

## When to use
- Starting a session on a new project
- After a long period away from the project
- When the context looks degraded
- Manually: `/boot`
