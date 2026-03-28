# Dotfiles — Claude Code Hooks

Repositório de dotfiles com hook universal de lint/format para o Claude Code.
Um único `git pull` mantém tudo sincronizado em qualquer máquina.

## Instalação em nova máquina

```bash
git clone https://github.com/USER/dotfiles ~/dotfiles
cd ~/dotfiles && bash install.sh
```

## Atualizar (qualquer máquina já configurada)

```bash
dotfiles-update
```

Ou manualmente:

```bash
cd ~/dotfiles && git pull
```

Como o `install.sh` cria **symlinks** (não cópias), o `git pull` já reflete as mudanças sem precisar rodar o instalador novamente.

## Linguagens suportadas pelo hook

| Extensão       | Ferramenta(s)              | Ação                             |
|----------------|----------------------------|----------------------------------|
| `.py`          | `ruff`                     | lint fix + format                |
| `.ts` `.tsx`   | `eslint` + `prettier`      | lint fix + format                |
| `.js` `.jsx`   | `eslint` + `prettier`      | lint fix + format                |
| `.go`          | `gofmt` + `golangci-lint`  | format + lint fix                |
| `.sql`         | `sqlfluff`                 | lint fix (dialeto auto-detectado)|

O hook é executado automaticamente pelo Claude Code após cada `Write`, `Edit` ou `MultiEdit`.

## Como adicionar config de projeto

Os arquivos em `config/` são **referências** para copiar na raiz de cada projeto:

```bash
# Python
cp ~/dotfiles/config/ruff.toml ./ruff.toml

# SQL
cp ~/dotfiles/config/.sqlfluff ./.sqlfluff

# Go
cp ~/dotfiles/config/golangci.yml ./.golangci.yml
```

Para JS/TS, crie `.eslintrc.*` e `.prettierrc` diretamente no projeto — cada um tem suas regras.

## Como modificar o hook

O hook principal fica em `claude/hooks/lint_hook.sh`. Para adicionar suporte a uma nova linguagem:

1. Adicione a extensão no `case` de verificação de extensões suportadas
2. Adicione um bloco `case` com a lógica de lint/format
3. Commit e `git pull` nas outras máquinas — pronto

## Aliases disponíveis

| Alias             | Ação                                    |
|-------------------|-----------------------------------------|
| `dotfiles-update` | `git pull` no repo de dotfiles          |
| `dotfiles-status` | `git status` do repo de dotfiles        |
| `lint-check`      | Verifica dependências de lint instaladas |

## Verificar dependências

```bash
lint-check
# ou
bash ~/dotfiles/scripts/check_deps.sh
```
