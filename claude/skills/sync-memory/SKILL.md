---
name: sync-memory
description: Reconciles the local .memory/, the remote memory repository, and the Obsidian vault
---

# /sync-memory

Reconciles every memory layer in the system.

## When to use
- When switching machines
- After a long session
- When you suspect the memory is out of date
- Weekly, as maintenance

## Workflow

### 1. Sync the memory repository
```bash
cd ~/memory && git pull --rebase 2>/dev/null; git push 2>/dev/null || echo "Remote not configured"
```

### 2. Incremental rebuild of the embeddings
```bash
python3 ~/dotfiles/scripts/memory_bridge.py rebuild --incremental
```

### 3. Sync with Obsidian (if a vault is configured)
```bash
python3 ~/dotfiles/scripts/memory_bridge.py sync
```

### 4. Report the status
```bash
python3 ~/dotfiles/scripts/memory_bridge.py status
```

## Expected output
A report with:
- Number of indexed memories
- Vector sizes (numpy + ONNX)
- Last sync
- Identified pending items
