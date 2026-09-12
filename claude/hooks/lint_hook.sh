#!/usr/bin/env bash
# Universal lint and format hook for Claude Code
# Runs automatically after Write, Edit and MultiEdit
# Receives JSON on stdin, as the documentation describes

# Read the input from stdin, in Claude Code's own format
INPUT=$(cat)

# Extract file_path from the JSON, with jq preferred and python3 as the fallback
# Write and Edit carry tool_input.file_path directly
# MultiEdit carries tool_input.edits[0].file_path
if command -v jq &>/dev/null; then
    FILE_PATH=$(echo "$INPUT" | jq -r '
        .tool_input.file_path //
        (.tool_input.edits[0].file_path // empty)
    ' 2>/dev/null)
else
    FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
fp = data.get('tool_input', {}).get('file_path', '')
if not fp:
    edits = data.get('tool_input', {}).get('edits', [])
    if edits and isinstance(edits, list):
        fp = edits[0].get('file_path', '')
print(fp)
" 2>/dev/null)
fi

# Exit quietly when there is no file to process
[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# Detect the extension
EXT="${FILE_PATH##*.}"
EXT=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

# Handle only the extensions this hook supports
case "$EXT" in
    py|ts|tsx|js|jsx|go|sql) ;;
    *) exit 0 ;;
esac

echo "🔧 [$EXT] $FILE_PATH"

case "$EXT" in
    py)
        if command -v ruff &>/dev/null; then
            ruff check --fix --quiet "$FILE_PATH" 2>/dev/null
            ruff format --quiet "$FILE_PATH" 2>/dev/null
            echo "✅ ruff lint and format done"
        else
            echo "⚠️ ruff not found, skipping the Python lint"
        fi
        ;;

    ts|tsx|js|jsx)
        # Walk up the directory tree until package.json appears
        PROJECT_DIR="$FILE_PATH"
        FOUND_PROJECT=""
        while true; do
            PROJECT_DIR=$(dirname "$PROJECT_DIR")
            if [ -f "$PROJECT_DIR/package.json" ]; then
                FOUND_PROJECT="$PROJECT_DIR"
                break
            fi
            # Reached the root without finding one
            if [ "$PROJECT_DIR" = "/" ] || [ "$PROJECT_DIR" = "." ]; then
                break
            fi
        done

        if [ -z "$FOUND_PROJECT" ]; then
            echo "⚠️ package.json not found, skipping the JS/TS lint"
        else
            if command -v npx &>/dev/null; then
                # ESLint
                npx --prefix "$FOUND_PROJECT" eslint --fix --quiet "$FILE_PATH" 2>/dev/null
                eslint_status=$?
                # Prettier
                npx --prefix "$FOUND_PROJECT" prettier --write --log-level silent "$FILE_PATH" 2>/dev/null
                prettier_status=$?

                if [ $eslint_status -eq 0 ] && [ $prettier_status -eq 0 ]; then
                    echo "✅ eslint and prettier done"
                else
                    echo "⚠️ eslint or prettier finished with warnings"
                fi
            else
                echo "⚠️ npx not found, install Node.js"
            fi
        fi
        ;;

    go)
        if command -v gofmt &>/dev/null; then
            gofmt -w "$FILE_PATH" 2>/dev/null
            echo "✅ gofmt done"
        else
            echo "⚠️ gofmt not found, install Go"
        fi

        if command -v golangci-lint &>/dev/null; then
            golangci-lint run --fix --quiet "$(dirname "$FILE_PATH")/..." 2>/dev/null
            echo "✅ golangci-lint done"
        else
            echo "⚠️ golangci-lint not found, skipping the Go lint"
        fi
        ;;

    sql)
        if command -v sqlfluff &>/dev/null; then
            # Guess the dialect from the path
            DIALECT="ansi"
            case "$FILE_PATH" in
                *sagi*|*sqlserver*) DIALECT="tsql" ;;
                *postgres*|*/pg/*) DIALECT="postgres" ;;
            esac

            sqlfluff fix --dialect "$DIALECT" --quiet "$FILE_PATH" 2>/dev/null
            echo "✅ sqlfluff fix done (dialect: $DIALECT)"
        else
            echo "⚠️ sqlfluff not found, skipping the SQL lint"
        fi
        ;;
esac

exit 0
