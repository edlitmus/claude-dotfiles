#!/usr/bin/env bash
# Checks lint/format dependencies
# Installs nothing — only reports what is missing

echo "=== Lint/format dependency check ==="
echo ""

MISSING=0

check_tool() {
    local tool="$1"
    local install_hint="$2"
    local display_name
    display_name=$(printf "%-15s" "$tool")

    if command -v "$tool" &>/dev/null; then
        echo "[✅] $display_name found"
    else
        echo "[❌] $display_name not found — install with: $install_hint"
        MISSING=$((MISSING + 1))
    fi
}

check_tool "jq"             "sudo apt install jq (or brew install jq)"
check_tool "ruff"           "pip install ruff"
check_tool "sqlfluff"       "pip install sqlfluff"
check_tool "golangci-lint"  "go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"
check_tool "gofmt"          "install Go (https://go.dev/dl/)"
check_tool "npx"            "install Node.js (https://nodejs.org/)"

echo ""
if [ "$MISSING" -eq 0 ]; then
    echo "✅ All dependencies are installed!"
else
    echo "⚠️  $MISSING dependency/dependencies not found — see the commands above."
fi
