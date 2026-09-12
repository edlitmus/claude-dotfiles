#!/usr/bin/env bash
# Sets up the centralized memory repository
# Usage: bash scripts/setup_memory_repo.sh

set -euo pipefail

MEMORY_DIR="${HOME}/memory"

if [ -d "$MEMORY_DIR/.git" ]; then
    echo "✓ Memory repository already exists at $MEMORY_DIR"
    exit 0
fi

echo "→ Creating memory repository at $MEMORY_DIR..."
mkdir -p "$MEMORY_DIR"/{global,projects,session,todo,plan,patterns,.embeddings}

cd "$MEMORY_DIR"
git init
git branch -M main

cat > global/long-term.md << 'EOF'
# Long-Term Memory

Insights accumulated across sessions. Updated automatically by memory_bridge.py.

## Technical patterns identified

## Recurring bugs

## Important architectural decisions

## Developer preferences
EOF

cat > .gitignore << 'EOF'
*.pyc
__pycache__/
.DS_Store
*.tmp
.embeddings/chromadb/
EOF

cat > README.md << 'EOF'
# Memory Repository

Private repository of memory persisted across Claude Code sessions.
DO NOT share publicly — it contains context from internal projects.

Automatic synchronization via the dotfiles hooks.

## Structure

- `global/` — long-term memory, recurring patterns
- `projects/` — per-project context
- `session/` — session logs (auto-generated)
- `todo/` — tasks pending across sessions
- `plan/` — active implementation plans
- `patterns/` — code patterns identified
- `.embeddings/` — vector index (git-ignored)
EOF

git add -A
git commit -m "chore(init): initialize memory repository"

echo ""
echo "✓ Memory repository created at $MEMORY_DIR"
echo ""
echo "→ Next step: create a PRIVATE GitHub repo named 'memory'"
echo "  Then run:"
echo "  cd ~/memory"
echo "  git remote add origin https://github.com/YOUR_USERNAME/memory"
echo "  git push -u origin main"
echo ""
