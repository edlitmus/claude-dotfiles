#!/usr/bin/env bash
# claude_md_reminder.sh — UserPromptSubmit hook
# Re-injects the project's CLAUDE.md every 3 prompts to prevent context drift.
# Inspired by Ring (LerianStudio) claude-md-reminder.sh.

SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
STATE_FILE="/tmp/.claude_reminder_${SESSION_ID}.count"

# Initialize the counter
[ ! -f "$STATE_FILE" ] && echo 0 > "$STATE_FILE"
COUNT=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
COUNT=$((COUNT + 1))
echo "$COUNT" > "$STATE_FILE"

# Act only on every third prompt
[ $((COUNT % 3)) -ne 0 ] && exit 0

# Look for CLAUDE.md up the directory tree
CLAUDE_MD=""
for candidate in "./CLAUDE.md" "../CLAUDE.md" "../../CLAUDE.md" "$HOME/.claude/CLAUDE.md"; do
    if [ -f "$candidate" ]; then
        CLAUDE_MD="$candidate"
        break
    fi
done

[ -z "$CLAUDE_MD" ] && exit 0

# Cut at a section boundary rather than mid-rule: read past the target line
# until the next top-level heading, and stop at the hard limit if the file has
# no heading there. A heading inside a fenced code block is not a boundary.
TARGET_LINES=50
LIMIT_LINES=100

RULES=$(awk -v target="$TARGET_LINES" -v limit="$LIMIT_LINES" '
    /^```/                                        { fence = !fence }
    NR > target && !fence && /^#/ && !/^###/      { exit }
    NR > limit                                    { exit }
                                                  { print }
' "$CLAUDE_MD" 2>/dev/null)

[ -z "$RULES" ] && exit 0

# Build the reinforcement context: the reminder, then the rules themselves
CONTEXT="REINFORCEMENT (prompt #${COUNT}): Respond in English. The 3-file rule is active. Agent auto-triggers are active. Skills: /review /review-deep /ship /refactor /test /tdd /security /debug /handoff /compact /perf /dispatch /explore /contextualize /brainstorm /boot /agent-memory /task-tracking.

Rules in effect, from ${CLAUDE_MD}:

${RULES}"

# The rules are arbitrary Markdown, so the JSON is built by a tool that escapes
# it. A hand-built string breaks on the first backslash or quote in the file.
if command -v jq &>/dev/null; then
    jq -cn --arg ctx "$CONTEXT" \
        '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$ctx}}'
else
    CONTEXT="$CONTEXT" python3 -c "
import json, os
print(json.dumps({'hookSpecificOutput': {'hookEventName': 'UserPromptSubmit',
                                         'additionalContext': os.environ['CONTEXT']}}))
"
fi
