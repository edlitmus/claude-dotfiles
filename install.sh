#!/usr/bin/env bash
# Instalador de dotfiles — cria symlinks (ou cópias no Windows) e configura o ambiente
# Idempotente: pode rodar múltiplas vezes sem efeitos colaterais

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
BASHRC="$HOME/.bashrc"

echo "=== Instalação de dotfiles ==="
echo "Diretório: $DOTFILES_DIR"
echo ""

ACTIONS=()

# Detectar SO para escolher entre symlink e cópia
link_file() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$source")" ]; then
        echo "[ok] $name — symlink já existe"
        return
    fi

    # Tentar symlink primeiro; fallback para cópia no Windows/MSYS
    if ln -sf "$source" "$target" 2>/dev/null && [ -L "$target" ]; then
        echo "[+]  $name → $target (symlink)"
        ACTIONS+=("Criado symlink $name")
    else
        cp -f "$source" "$target"
        echo "[+]  $name → $target (cópia — symlinks indisponíveis)"
        echo "     ⚠️  Rode 'bash install.sh' após git pull para sincronizar"
        ACTIONS+=("Copiado $name (symlink indisponível)")
    fi
}

# 1. Criar diretórios necessários
mkdir -p "$HOOKS_DIR"

# 2. Instalar settings.json
link_file "$DOTFILES_DIR/claude/settings.json" "$CLAUDE_DIR/settings.json" "settings.json"

# 3. Instalar lint_hook.sh
link_file "$DOTFILES_DIR/claude/hooks/lint_hook.sh" "$HOOKS_DIR/lint_hook.sh" "lint_hook.sh"

# 4. Garantir executável
chmod +x "$DOTFILES_DIR/claude/hooks/lint_hook.sh"
chmod +x "$HOOKS_DIR/lint_hook.sh" 2>/dev/null

# 5. Source do .bashrc_extras no .bashrc (idempotente)
SOURCE_LINE="source \"$DOTFILES_DIR/shell/.bashrc_extras\""
if [ -f "$BASHRC" ] && grep -qF "$SOURCE_LINE" "$BASHRC"; then
    echo "[ok] .bashrc_extras — já configurado no .bashrc"
else
    echo "" >> "$BASHRC"
    echo "# Dotfiles extras" >> "$BASHRC"
    echo "$SOURCE_LINE" >> "$BASHRC"
    echo "[+]  .bashrc_extras adicionado ao .bashrc"
    ACTIONS+=("Adicionado source .bashrc_extras ao .bashrc")
fi

# 6. Verificar dependências
echo ""
bash "$DOTFILES_DIR/scripts/check_deps.sh"

# 7. Resumo
echo ""
echo "=== Resumo ==="
if [ ${#ACTIONS[@]} -eq 0 ]; then
    echo "Nenhuma alteração necessária — tudo já estava configurado."
else
    for action in "${ACTIONS[@]}"; do
        echo "  • $action"
    done
fi
echo ""
echo "✅ Instalação concluída!"
echo "   Execute 'source ~/.bashrc' ou abra um novo terminal para ativar os aliases."
