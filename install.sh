#!/usr/bin/env bash
# Dotfiles installer — sets up a complete Claude Code install on any machine
# Idempotent: can be run multiple times with no side effects

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
AGENTS_DIR="$CLAUDE_DIR/agents"
SKILLS_DIR="$CLAUDE_DIR/skills"
RULES_DIR="$CLAUDE_DIR/rules"
BASHRC="$HOME/.bashrc"

echo "╔══════════════════════════════════════════╗"
echo "║     Dotfiles — Claude Code Setup         ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Directory: $DOTFILES_DIR"
echo ""

ACTIONS=()

# --- Helper functions ---

link_file() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$source")" ]; then
        echo "  [ok] $name"
        return
    fi

    if ln -sf "$source" "$target" 2>/dev/null && [ -L "$target" ]; then
        echo "  [+]  $name (symlink)"
        ACTIONS+=("Symlink: $name")
    else
        cp -f "$source" "$target"
        echo "  [+]  $name (copy)"
        ACTIONS+=("Copied: $name")
    fi
}

link_dir() {
    local source_dir="$1"
    local target_dir="$2"
    local label="$3"

    mkdir -p "$target_dir"
    local count=0
    for file in "$source_dir"/*; do
        [ ! -e "$file" ] && continue
        local basename=$(basename "$file")
        if [ -d "$file" ]; then
            # Recurse into subdirectories (skills have subfolders)
            link_dir "$file" "$target_dir/$basename" "$label/$basename"
        else
            link_file "$file" "$target_dir/$basename" "$label/$basename"
            count=$((count + 1))
        fi
    done
    [ "$count" -gt 0 ] || [ -d "$source_dir" ]
}

# --- 1. Create directories ---
echo "📁 Creating directories..."
mkdir -p "$HOOKS_DIR" "$AGENTS_DIR" "$SKILLS_DIR" "$RULES_DIR"
echo ""

# --- 2. Main files ---
echo "🔗 Installing main files..."
link_file "$DOTFILES_DIR/claude/settings.json" "$CLAUDE_DIR/settings.json" "settings.json"
link_file "$DOTFILES_DIR/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md"
link_file "$DOTFILES_DIR/claude/.mcp.json" "$CLAUDE_DIR/.mcp.json" ".mcp.json"
link_file "$DOTFILES_DIR/claude/keybindings.json" "$CLAUDE_DIR/keybindings.json" "keybindings.json"
echo ""

# --- 3. Hook ---
echo "🪝 Installing hooks..."
link_file "$DOTFILES_DIR/claude/hooks/lint_hook.sh" "$HOOKS_DIR/lint_hook.sh" "hooks/lint_hook.sh"
chmod +x "$DOTFILES_DIR/claude/hooks/lint_hook.sh"
chmod +x "$HOOKS_DIR/lint_hook.sh" 2>/dev/null
echo ""

# --- 4. Agents ---
echo "🤖 Installing agents..."
link_dir "$DOTFILES_DIR/claude/agents" "$AGENTS_DIR" "agents"
echo ""

# --- 5. Skills ---
echo "⚡ Installing skills..."
link_dir "$DOTFILES_DIR/claude/skills" "$SKILLS_DIR" "skills"
echo ""

# --- 6. Rules ---
echo "📏 Installing rules..."
link_dir "$DOTFILES_DIR/claude/rules" "$RULES_DIR" "rules"
echo ""

# --- 7. Shell extras ---
echo "🐚 Configuring the shell..."
SOURCE_LINE="source \"$DOTFILES_DIR/shell/.bashrc_extras\""
if [ -f "$BASHRC" ] && grep -qF "$SOURCE_LINE" "$BASHRC"; then
    echo "  [ok] .bashrc_extras already configured"
else
    echo "" >> "$BASHRC"
    echo "# Dotfiles extras" >> "$BASHRC"
    echo "$SOURCE_LINE" >> "$BASHRC"
    echo "  [+]  .bashrc_extras added to .bashrc"
    ACTIONS+=(".bashrc_extras → ~/.bashrc")
fi
echo ""

# --- 8. Python dependencies ---
echo "🐍 Installing Python dependencies..."

install_python_dep() {
    local pkg="$1"
    local label="$2"
    if python3 -c "import ${pkg//-/_}" 2>/dev/null; then
        echo "  [ok] $label already installed"
    elif pip3 install "$pkg" --quiet 2>/dev/null; then
        echo "  [+]  $label installed"
        ACTIONS+=("pip: $label")
    else
        echo "  [--] $label unavailable (fallback active)"
    fi
}

install_python_dep "sentence-transformers" "Local embeddings (MiniLM-L6-v2)"
install_python_dep "turboquant-vectors" "TurboQuant (vector compression)"
echo ""

# --- 9. Memory repository ---
echo "🧠 Configuring memory..."
MEMORY_DIR="${HOME}/memory"

if [ -d "$MEMORY_DIR/.git" ]; then
    echo "  [ok] Memory repository already exists"
    cd "$MEMORY_DIR" && git pull --quiet --rebase 2>/dev/null && cd - > /dev/null
else
    echo "  [+]  Creating the memory repository..."
    bash "$DOTFILES_DIR/scripts/setup_memory_repo.sh"
    ACTIONS+=("Created: ~/memory")
fi

# Incremental rebuild of the embeddings
if [ -f "$DOTFILES_DIR/scripts/memory_bridge.py" ]; then
    echo "  [+]  Rebuilding the memory index..."
    python3 "$DOTFILES_DIR/scripts/memory_bridge.py" rebuild --incremental --quiet 2>/dev/null || true
fi
echo ""

# --- 10. ruah ---
echo "🔀 Checking ruah..."
if command -v ruah &>/dev/null; then
    echo "  [ok] ruah already installed: $(ruah --version 2>/dev/null)"
else
    if command -v npm &>/dev/null; then
        echo "  [+]  Installing ruah..."
        npm install -g @levi-tc/ruah --quiet 2>/dev/null && \
            echo "  [ok] ruah installed" || \
            echo "  [--] ruah not installed (optional)"
    else
        echo "  [--] npm unavailable — ruah not installed (optional)"
    fi
fi
echo ""

# --- 11. Post-install validation ---
echo "🔍 Validating the installation..."
VALIDATION_ERRORS=0

# Check hook permissions
for hook in "$HOOKS_DIR"/*.sh; do
    [ ! -e "$hook" ] && continue
    if [ ! -x "$hook" ]; then
        chmod +x "$hook"
        echo "  [fix] Permission fixed: $(basename "$hook")"
    fi
done

# Validate the JSON files
if command -v jq &>/dev/null; then
    for json_file in "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/keybindings.json" "$CLAUDE_DIR/.mcp.json"; do
        if [ -f "$json_file" ] && ! jq empty "$json_file" 2>/dev/null; then
            echo "  [ERROR] Invalid JSON: $(basename "$json_file")"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        fi
    done
fi

if [ "$VALIDATION_ERRORS" -eq 0 ]; then
    echo "  [ok] All files validated successfully"
fi
echo ""


# --- 12. Check dependencies ---
bash "$DOTFILES_DIR/scripts/check_deps.sh"

# --- 13. Summary ---
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║              Summary                     ║"
echo "╚══════════════════════════════════════════╝"

if [ ${#ACTIONS[@]} -eq 0 ]; then
    echo "  No changes — everything was already configured."
else
    for action in "${ACTIONS[@]}"; do
        echo "  • $action"
    done
fi

echo ""
echo "📦 Installed:"
echo "  • CLAUDE.md          — global conventions"
echo "  • settings.json      — hooks + permissions"
echo "  • .mcp.json          — GitHub MCP server"
echo "  • keybindings.json   — keyboard shortcuts"
echo "  • 1 hook             — automatic lint"
echo "  • 8 agents           — frontend, backend, database, architect, devops, security, fadex-context, data-analyst"
echo "  • 20 skills          — /review, /ship, /refactor, /test, /debug, /handoff, /boot, /sync-memory and 12 more"
echo "  • 6 rules            — python, typescript, go, sql, security, testing"
echo "  • memory_bridge.py   — semantic memory, numpy + ONNX (MiniLM-L6-v2)"
echo "  • ruah_bridge.sh     — integration with parallel sessions"
echo ""
echo "⚠️  Set GITHUB_TOKEN for the GitHub MCP server to work:"
echo "    export GITHUB_TOKEN='ghp_your_token_here'"
echo ""
echo "✅ Installation complete!"
echo "   Run 'source ~/.bashrc' or open a new terminal."
