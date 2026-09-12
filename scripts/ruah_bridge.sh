#!/usr/bin/env bash
# Bridge between ruah and memory_bridge for parallel sessions
# Usage: bash scripts/ruah_bridge.sh [start|complete] TASK_NAME [args...]

set -euo pipefail

MEMORY_BRIDGE="${HOME}/dotfiles/scripts/memory_bridge.py"
COMMAND="${1:-}"
TASK_NAME="${2:-}"

if [ -z "$COMMAND" ] || [ -z "$TASK_NAME" ]; then
    echo "Usage: ruah_bridge.sh [start|complete] TASK_NAME [args...]"
    exit 1
fi

shift 2

case "$COMMAND" in
    start)
        echo "→ Querying memory for task: $TASK_NAME" >&2

        if [ -f "$MEMORY_BRIDGE" ]; then
            CONTEXT=$(python3 "$MEMORY_BRIDGE" query \
                --text "$TASK_NAME $*" \
                --top-k 5 \
                --format plain 2>/dev/null || true)
        fi

        # If ruah is available and the task has a worktree, inject the context
        if command -v ruah &>/dev/null; then
            WORKTREE=$(ruah task list --json 2>/dev/null | \
                python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for t in data.get('tasks', []):
        if t.get('name') == '$TASK_NAME':
            print(t.get('worktree', ''))
            break
except: pass
" 2>/dev/null || true)

            if [ -n "${WORKTREE:-}" ] && [ -d "$WORKTREE" ] && [ -n "${CONTEXT:-}" ]; then
                echo "" >> "$WORKTREE/CLAUDE.md" 2>/dev/null || true
                echo "## Injected context (memory)" >> "$WORKTREE/CLAUDE.md" 2>/dev/null || true
                echo "$CONTEXT" >> "$WORKTREE/CLAUDE.md" 2>/dev/null || true
                echo "✓ Context injected into worktree $WORKTREE" >&2
            fi
        fi

        if [ -n "${CONTEXT:-}" ]; then
            echo "$CONTEXT"
        fi
        ;;

    complete)
        echo "→ Persisting task to memory: $TASK_NAME" >&2

        ARTIFACTS=""
        if command -v ruah &>/dev/null; then
            ARTIFACTS=$(ruah task list --json 2>/dev/null | \
                python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for t in data.get('tasks', []):
        if t.get('name') == '$TASK_NAME':
            print(json.dumps(t, indent=2))
            break
except: pass
" 2>/dev/null || true)
        fi

        if [ -f "$MEMORY_BRIDGE" ]; then
            SUMMARY="ruah task '${TASK_NAME}' completed."
            if [ -n "$ARTIFACTS" ]; then
                SUMMARY="$SUMMARY Details: $ARTIFACTS"
            fi
            if [ -n "$*" ]; then
                SUMMARY="$SUMMARY Notes: $*"
            fi

            python3 "$MEMORY_BRIDGE" store \
                --text "$SUMMARY" \
                --tags "ruah,task,$TASK_NAME" \
                --project "$(basename "$PWD")" 2>/dev/null || true

            echo "✓ Task persisted to memory" >&2
        fi
        ;;

    *)
        echo "Unknown command: $COMMAND"
        echo "Usage: ruah_bridge.sh [start|complete] TASK_NAME [args...]"
        exit 1
        ;;
esac
