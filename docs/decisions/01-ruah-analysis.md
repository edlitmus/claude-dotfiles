# Technical Analysis: ruah (@levi-tc/ruah v0.4.3)

**Date:** 2026-04-10
**Status:** Decided — integrate via a bridge script
**Current package:** `@levi-tc/ruah` v0.4.3 (deprecated → `@ruah-dev/orch`)

---

## What it is

ruah is a task orchestrator for AI agents that uses git worktrees as the unit of isolation. Each task gets its own worktree, allowing parallel execution without branch conflicts.

---

## Available commands

### Initialization and configuration

| Command | Description |
|---|---|
| `ruah init` | Initializes `.ruah/` in the git repository (requires at least 1 commit) |
| `ruah setup` | Initial environment setup |
| `ruah config` | Manages configuration |
| `ruah doctor` | Environment diagnostics |
| `ruah status` | Current state of the tasks |
| `ruah clean` | Cleans up worktrees and state |
| `ruah demo` | Interactive demo |

### Task life cycle

| Command | Description |
|---|---|
| `ruah task create` | Creates a new task (with a worktree) |
| `ruah task start` | Starts running the task |
| `ruah task done` | Marks the task as complete |
| `ruah task merge` | Merges the worktree back into the main branch |
| `ruah task list` | Lists every task and its state |
| `ruah task cancel` | Cancels a task |
| `ruah task retry` | Retries a failed task |
| `ruah task takeover` | Takes back control of a running task |

### Workflows

| Command | Description |
|---|---|
| `ruah workflow run` | Runs a workflow defined in markdown |
| `ruah workflow plan` | Analyzes and plans the execution (DAG) |
| `ruah workflow list` | Lists the available workflows |
| `ruah workflow create` | Creates a new workflow file |

---

## Relevant features

### File claiming

When creating a task, you can declare the files it will modify:

```bash
ruah task create "implement authentication" --files "src/auth/**" --files "tests/auth/**"
```

This records modification contracts in the task's `.ruah-task.md`.

### Modification contracts

The `.ruah-task.md` file defines access boundaries between concurrent tasks:

- **owned** — the file belongs exclusively to the task
- **shared-append** — multiple tasks may append content
- **read-only** — the task only reads, it does not modify

This avoids conflicts in parallel runs without requiring explicit locks.

### Supported executors

| Executor | Description |
|---|---|
| `claude-code` | Claude Code via the CLI |
| `aider` | Aider (interactive or automatic mode) |
| `codex` | OpenAI Codex CLI |
| `open-code` | Open-source alternative |
| `script` | An arbitrary shell script |

### Parallel execution

The planner analyzes file overlaps between tasks and decides which ones can run in parallel. Tasks with file conflicts are serialized automatically.

### Subtasks

Tasks can be hierarchical via `--parent`:

```bash
ruah task create "implement the POST /users endpoint" --parent parent-task-uuid
```

The subtask creates a worktree branching from the parent's branch, not from main.

### Integration with crag

Before `task merge`, ruah can call crag as a quality gate — checking test coverage, lint, and other criteria before accepting the merge.

### Persisted state

All state lives in `.ruah/state.json` with the following structure:

```json
{
  "tasks": {},
  "locks": {},
  "lockModes": {},
  "history": []
}
```

---

## Limitations identified

| Limitation | Impact | Mitigation |
|---|---|---|
| Deprecated package (`@levi-tc/ruah`) | Medium — no new fixes | Migrate to `@ruah-dev/orch` once it is stable |
| No memory/context injection | High — agents start with no history | The bridge script injects context via `--context` or a temp file |
| Requires at least 1 commit for `init` | Low — known condition | Document it in the README |
| No native hook system | Medium — lifecycle only via workflows | Wrap the ruah commands with the bridge script |
| Worktrees require extra disk | Low — proportional to the repo size | Monitor with periodic `ruah clean` |

---

## Integration decision

**Verdict:** Integrate via `ruah_bridge.sh`.

The bridge script wraps the ruah commands and adds the missing capabilities:

```
ruah task create  →  the bridge injects memory context (ChromaDB/numpy)
ruah task done    →  the bridge persists the result to the vector store
ruah task merge   →  the bridge updates the memory index with the merged diff
```

This keeps ruah as the worktree orchestrator (its core responsibility) without modifying the package. Memory and context live in the bridge, which is our own code.

### Why not migrate to `@ruah-dev/orch` now

- The `@ruah-dev/orch` API is not yet stable enough to analyze
- `@levi-tc/ruah` v0.4.3 works and has known behavior
- Migration is an isolated task that does not block the bridge

---

## References

- Current package: `npm install -g @levi-tc/ruah`
- Successor package: `npm install -g @ruah-dev/orch`
- Local state: `.ruah/state.json`
- File contracts: `.ruah-task.md` per worktree
