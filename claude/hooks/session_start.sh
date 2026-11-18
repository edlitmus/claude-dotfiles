#!/usr/bin/env bash
# session_start.sh — SessionStart hook for Claude Code
# Detects project stack and reports context automatically.

CONTEXT="Active hooks: automatic lint, sensitive-file protection, bash security, secret scanner."
CONTEXT="$CONTEXT Agents: frontend, backend, database, architect, devops, security."
CONTEXT="$CONTEXT Skills: /review, /ship, /refactor, /test, /security, /debug, /handoff, /compact, /perf."
CONTEXT="$CONTEXT Always respond in English."

# --- Stack detection ---
STACK=""

if [ -f "package.json" ]; then
    STACK="$STACK Node.js"
    # Detect framework
    for fw in next react vue angular express nestjs fastify; do
        if grep -q "\"$fw\"" package.json 2>/dev/null || grep -q "\"@${fw}/" package.json 2>/dev/null; then
            STACK="$STACK ($fw)"
            break
        fi
    done
    STACK="$STACK;"
fi

if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
    STACK="$STACK Python"
    for fw in django fastapi flask; do
        if grep -qi "$fw" requirements.txt 2>/dev/null || grep -qi "$fw" pyproject.toml 2>/dev/null; then
            STACK="$STACK ($fw)"
            break
        fi
    done
    STACK="$STACK;"
fi

if [ -f "go.mod" ]; then
    # go.mod is repo-controlled, and this value ends up in the model's context,
    # so it is clamped to the characters a module path can legitimately use.
    MOD_NAME=$(head -1 go.mod 2>/dev/null | awk '{print $2}' \
        | tr -cd 'A-Za-z0-9._/@~-' | cut -c1-80)
    STACK="$STACK Go ($MOD_NAME);"
fi

if [ -f "Cargo.toml" ]; then
    STACK="$STACK Rust;"
fi

if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ]; then
    STACK="$STACK Docker Compose;"
fi

if [ -f "Dockerfile" ]; then
    STACK="$STACK Dockerfile;"
fi

if [ -d ".github/workflows" ]; then
    STACK="$STACK GitHub Actions CI/CD;"
fi

if [ -f "terraform.tf" ] || [ -d ".terraform" ]; then
    STACK="$STACK Terraform;"
fi

if [ -n "$STACK" ]; then
    CONTEXT="$CONTEXT Detected stack:$STACK"
fi

# The context embeds repo-derived text (the go.mod module name), so the JSON is
# built by a tool that escapes it. The previous hand-built printf broke on the
# first quote in that text — which silently dropped the WHOLE SessionStart
# context — and let repo content inject its own keys into hookSpecificOutput.
# Same reasoning as claude_md_reminder.sh.
if command -v jq >/dev/null 2>&1; then
    jq -cn --arg ctx "$CONTEXT" \
        '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
else
    CONTEXT="$CONTEXT" python3 -c "
import json, os
print(json.dumps({'hookSpecificOutput': {'hookEventName': 'SessionStart',
                                         'additionalContext': os.environ['CONTEXT']}}))
"
fi
