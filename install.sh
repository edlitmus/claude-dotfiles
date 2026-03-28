#!/usr/bin/env bash
# Instalador de dotfiles — cria symlinks e configura o ambiente
# Idempotente: pode rodar múltiplas vezes sem efeitos colaterais

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
BASHRC="$HOME/.bashrc"

echo "=== Instalação de dotfiles ==="
echo "Diretório: $DOTFILES_DIR"
echo ""

ACTIONS=()

# 1. Criar diretórios necessários
mkdir -p "$HOOKS_DIR"

# 2. Symlink: settings.json
SOURCE="$DOTFILES_DIR/claude/settings.json"
TARGET="$CLAUDE_DIR/settings.json"
if [ -L "$TARGET" ] && [ "$(readlink -f "$TARGET")" = "$(readlink -f "$SOURCE")" ]; then
    echo "[ok] settings.json — symlink já existe"
else
    ln -sf "$SOURCE" "$TARGET"
    echo "[+]  settings.json → $TARGET"
    ACTIONS+=("Criado symlink settings.json")
fi

# 3. Symlink: lint_hook.sh
SOURCE="$DOTFILES_DIR/claude/hooks/lint_hook.sh"
TARGET="$HOOKS_DIR/lint_hook.sh"
if [ -L "$TARGET" ] && [ "$(readlink -f "$TARGET")" = "$(readlink -f "$SOURCE")" ]; then
    echo "[ok] lint_hook.sh — symlink já existe"
else
    ln -sf "$SOURCE" "$TARGET"
    echo "[+]  lint_hook.sh → $TARGET"
    ACTIONS+=("Criado symlink lint_hook.sh")
fi

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
