# Architecture — Unified Memory System

## Overview

The dotfiles configure Claude Code with a complete productivity ecosystem:
automatic hooks, specialized agents, workflow skills, and semantic memory
persisted across sessions and machines.

## Component diagram

```
┌──────────────────────────────────────────────────────────────┐
│                      Claude Code CLI                         │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────────┐ │
│  │   Hooks      │  │   Skills    │  │      Agents          │ │
│  │             │  │             │  │                      │ │
│  │ SessionStart│  │ /review     │  │ frontend  backend    │ │
│  │ PostToolUse │  │ /ship       │  │ database  architect  │ │
│  │ PreToolUse  │  │ /refactor   │  │ devops    security   │ │
│  │ PreCompact  │  │ /test       │  │ fadex-ctx data-anlst │ │
│  │ Stop        │  │ /debug      │  │                      │ │
│  │ UserPrompt  │  │ /handoff    │  └──────────────────────┘ │
│  │             │  │ /security   │                           │
│  └──────┬──────┘  │ /sync-mem   │                           │
│         │         │ /loop-recov │                           │
│         │         └─────────────┘                           │
│         │                                                    │
│  ┌──────▼──────────────────────────────────────────────────┐ │
│  │              memory_bridge.py                           │ │
│  │  store | query | rebuild | sync | status                │ │
│  └──────┬────────────────┬─────────────────┬───────────────┘ │
│         │                │                 │                 │
│  ┌──────▼──────┐  ┌──────▼──────┐  ┌───────▼─────────────┐  │
│  │ numpy+ONNX  │  │ ~/memory/   │  │ Obsidian (optional)  │  │
│  │ (vectors)   │  │ (git repo)  │  │                      │  │
│  │ index.json  │  │ projects/   │  │ vault/claude-memory/ │  │
│  │ vectors.npy │  │ session/    │  │                      │  │
│  └─────────────┘  │ global/     │  └──────────────────────┘  │
│                    └─────────────┘                            │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              ruah_bridge.sh (optional)                   │ │
│  │  Coordinates parallel sessions with isolated worktrees  │ │
│  │  start → injects memory | complete → persists context   │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Rules     │  │   Config    │  │     Shell           │  │
│  │  python.md  │  │  ruff.toml  │  │  .bashrc_extras     │  │
│  │  ts.md      │  │  .sqlfluff  │  │  aliases            │  │
│  │  go/sql/etc │  │  golangci   │  │                     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

## Data flow per event

### SessionStart
1. The hook injects a static message (available agents/skills)
2. memory_bridge.py query → looks up context for the current project
3. The result is injected as additional session context

### PreCompact
1. The hook reinforces the rules (English, agents, skills)
2. memory_bridge.py store → saves a session summary before compacting

### Stop
1. The hook detects pending TODO/FIXME markers
2. Auto-commit of ~/memory/ (if there are changes)

### /handoff
1. Generates HANDOFF.md with the session state
2. memory_bridge.py store → persists it to semantic memory

### /sync-memory
1. git pull --rebase in ~/memory/
2. Incremental rebuild of the embeddings
3. Bidirectional sync with Obsidian
4. Status report

## Technical decisions

| Decision | Alternatives | Rationale |
|----------|-------------|-----------|
| numpy + ONNX (MiniLM-L6-v2) as the vector store | ChromaDB, mempalace, qdrant | Git-syncable format (index.json + vectors.npy), no binary SQLite, local embeddings |
| turboquant-vectors (optional) | turboquant-py, numpy | Works on Python 3.14, 4-8x compression for export |
| ruah for coordination | manual git worktree | Ready-made CLI with file claiming and a merge DAG |
| ~/memory/ as a git repo | local database, cloud | Portable, versioned, simple push/pull |
| char-trigram fallback | — | Guarantees it works with no extra dependencies |

Full details in:
- [docs/decisions/01-ruah-analysis.md](decisions/01-ruah-analysis.md)
- [docs/decisions/02-mempalace-analysis.md](decisions/02-mempalace-analysis.md)
- [docs/decisions/03-turboquant-analysis.md](decisions/03-turboquant-analysis.md)

## External dependencies

| Package | Required | Fallback |
|---------|----------|----------|
| chromadb (ONNX embeddings only) | No | char-trigram hashing fallback |
| turboquant-vectors | No | No compression (raw vectors) |
| @levi-tc/ruah | No | No parallel coordination |

## Roadmap

- [ ] A dedicated MCP server for memory_bridge (query/store via tools)
- [ ] Integration with mempalace once a Windows build is available
- [ ] Memory dashboard via an Obsidian plugin
- [ ] TurboQuant compression for syncing vectors between machines
- [ ] Usage metrics (how many queries/stores per session)
