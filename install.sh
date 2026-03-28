#!/usr/bin/env bash
# Instalador de dotfiles — configura Claude Code completo em qualquer máquina
# Idempotente: pode rodar múltiplas vezes sem efeitos colaterais

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
echo "Diretório: $DOTFILES_DIR"
echo ""

ACTIONS=()

# --- Funções auxiliares ---

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
        echo "  [+]  $name (cópia)"
        ACTIONS+=("Copiado: $name")
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
            # Recursivo para subdiretórios (skills têm subpastas)
            link_dir "$file" "$target_dir/$basename" "$label/$basename"
        else
            link_file "$file" "$target_dir/$basename" "$label/$basename"
            count=$((count + 1))
        fi
    done
    [ "$count" -gt 0 ] || [ -d "$source_dir" ]
}

# --- 1. Criar diretórios ---
echo "📁 Criando diretórios..."
mkdir -p "$HOOKS_DIR" "$AGENTS_DIR" "$SKILLS_DIR" "$RULES_DIR"
echo ""

# --- 2. Arquivos principais ---
echo "🔗 Instalando arquivos principais..."
link_file "$DOTFILES_DIR/claude/settings.json" "$CLAUDE_DIR/settings.json" "settings.json"
link_file "$DOTFILES_DIR/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" "CLAUDE.md"
link_file "$DOTFILES_DIR/claude/.mcp.json" "$CLAUDE_DIR/.mcp.json" ".mcp.json"
link_file "$DOTFILES_DIR/claude/keybindings.json" "$CLAUDE_DIR/keybindings.json" "keybindings.json"
echo ""

# --- 3. Hook ---
echo "🪝 Instalando hooks..."
link_file "$DOTFILES_DIR/claude/hooks/lint_hook.sh" "$HOOKS_DIR/lint_hook.sh" "hooks/lint_hook.sh"
chmod +x "$DOTFILES_DIR/claude/hooks/lint_hook.sh"
chmod +x "$HOOKS_DIR/lint_hook.sh" 2>/dev/null
echo ""

# --- 4. Agents ---
echo "🤖 Instalando agentes..."
link_dir "$DOTFILES_DIR/claude/agents" "$AGENTS_DIR" "agents"
echo ""

# --- 5. Skills ---
echo "⚡ Instalando skills..."
link_dir "$DOTFILES_DIR/claude/skills" "$SKILLS_DIR" "skills"
echo ""

# --- 6. Rules ---
echo "📏 Instalando rules..."
link_dir "$DOTFILES_DIR/claude/rules" "$RULES_DIR" "rules"
echo ""

# --- 7. Shell extras ---
echo "🐚 Configurando shell..."
SOURCE_LINE="source \"$DOTFILES_DIR/shell/.bashrc_extras\""
if [ -f "$BASHRC" ] && grep -qF "$SOURCE_LINE" "$BASHRC"; then
    echo "  [ok] .bashrc_extras já configurado"
else
    echo "" >> "$BASHRC"
    echo "# Dotfiles extras" >> "$BASHRC"
    echo "$SOURCE_LINE" >> "$BASHRC"
    echo "  [+]  .bashrc_extras adicionado ao .bashrc"
    ACTIONS+=(".bashrc_extras → ~/.bashrc")
fi
echo ""

# --- 8. Verificar dependências ---
bash "$DOTFILES_DIR/scripts/check_deps.sh"

# --- 9. Resumo ---
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║              Resumo                      ║"
echo "╚══════════════════════════════════════════╝"

if [ ${#ACTIONS[@]} -eq 0 ]; then
    echo "  Nenhuma alteração — tudo já estava configurado."
else
    for action in "${ACTIONS[@]}"; do
        echo "  • $action"
    done
fi

echo ""
echo "📦 Instalado:"
echo "  • CLAUDE.md          — convenções globais"
echo "  • settings.json      — hooks + permissions"
echo "  • .mcp.json          — GitHub MCP server"
echo "  • keybindings.json   — atalhos de teclado"
echo "  • 1 hook             — lint automático"
echo "  • 6 agents           — frontend, backend, database, architect, devops, security"
echo "  • 7 skills           — /review, /ship, /refactor, /test, /security-audit, /debug, /handoff"
echo "  • 6 rules            — python, typescript, go, sql, security, testing"
echo ""
echo "⚠️  Configure GITHUB_TOKEN para o MCP GitHub funcionar:"
echo "    export GITHUB_TOKEN='ghp_seu_token_aqui'"
echo ""
echo "✅ Instalação concluída!"
echo "   Execute 'source ~/.bashrc' ou abra um novo terminal."
