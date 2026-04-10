# Dotfiles — Claude Code Complete Setup

Repositorio de dotfiles que transforma o Claude Code em um ambiente de desenvolvimento completo com agentes especializados, automacao de lint, protecao de arquivos sensiveis e comandos customizados.

**Um `git clone` + `bash install.sh` = ambiente pronto em qualquer maquina.**

---

## Instalacao

```bash
# Nova maquina
git clone https://github.com/vini-haa/dotfiles ~/dotfiles
cd ~/dotfiles && bash install.sh

# Atualizar (qualquer maquina ja configurada)
cd ~/dotfiles && git pull
# Symlinks refletem mudancas automaticamente
```

### Pre-requisitos opcionais

```bash
# Para MCP GitHub (issues, PRs, repos)
export GITHUB_TOKEN='ghp_seu_token'

# Verificar ferramentas de lint
lint-check
```

---

## O que e instalado

```
~/.claude/
├── settings.json      ← hooks + permissions (protegido)
├── CLAUDE.md          ← convencoes globais de codigo
├── .mcp.json          ← GitHub MCP server
├── keybindings.json   ← atalhos de teclado
├── hooks/
│   ├── lint_hook.sh       ← lint automatico pos-edicao
│   ├── bash_security.sh   ← bloqueio de comandos perigosos
│   ├── secret_scan.sh     ← deteccao de credenciais em codigo
│   ├── session_start.sh   ← deteccao automatica de stack
│   └── claude_md_reminder.sh   ← re-injeção de contexto a cada 3 prompts
├── agents/
│   ├── frontend.md    ← UI, React, acessibilidade
│   ├── backend.md     ← APIs, auth, services
│   ├── database.md    ← SQL, modelagem, performance
│   ├── architect.md   ← design de sistemas, trade-offs
│   ├── devops.md      ← CI/CD, Docker, infra
│   └── security.md    ← auditoria, vulnerabilidades
├── skills/
│   ├── review/        ← /review — code review
│   ├── ship/          ← /ship — lint+test+build+commit
│   ├── refactor/      ← /refactor — refatoracao guiada
│   ├── test/          ← /test — gerar/rodar testes
│   ├── security/      ← /security — auditoria
│   ├── debug/         ← /debug — investigar bugs
│   ├── handoff/       ← /handoff — salvar contexto entre sessoes
│   ├── compact/       ← /compact — resumir sessao para liberar contexto
│   ├── perf/          ← /perf — analise de performance
│   ├── dispatch/      ← /dispatch — orquestração de agentes
│   ├── agent-memory/  ← /agent-memory — memória persistente
│   ├── task-tracking/ ← /task-tracking — todos persistentes
│   ├── boot/          ← /boot — inicialização de sessão
│   ├── review-deep/   ← /review-deep — review paralelo multi-agente
│   ├── tdd/           ← /tdd — test-driven development
│   ├── explore/       ← /explore — exploração de codebase
│   ├── contextualize/ ← /contextualize — orientação por diretório
│   └── brainstorm/    ← /brainstorm — ideação criativa
└── rules/
    ├── python.md      ← ativado em *.py
    ├── typescript.md  ← ativado em *.ts/*.tsx/*.js/*.jsx
    ├── go.md          ← ativado em *.go
    ├── sql.md         ← ativado em *.sql
    ├── security.md    ← ativado em todos os arquivos
    └── testing.md     ← ativado em arquivos de teste
```

---

## Agentes especializados

Use agentes quando quiser delegar uma tarefa com contexto especializado:

| Agente | Quando usar | Modelo |
|--------|------------|--------|
| `frontend` | UI, componentes, CSS, acessibilidade, React/Vue/Angular | Sonnet |
| `backend` | APIs, auth, services, middleware, integracao | Sonnet |
| `database` | Modelagem, queries, migrations, indexacao, performance | Sonnet |
| `architect` | Design de sistemas, trade-offs, escolha de tecnologias | Opus |
| `devops` | Docker, CI/CD, IaC, monitoramento, deploy | Sonnet |
| `security` | Auditoria, vulnerabilidades, OWASP (read-only) | Opus |
| `fadex-context` | Sistemas internos FADEX, SAGI, UFPI/IFPI, regulamentações | Sonnet |
| `data-analyst` | SQL Server/PostgreSQL, queries complexas, ETL, BI | Sonnet |

O agente de **security** opera em modo read-only — analisa e reporta mas nao edita codigo.

### Como usar
```
"Use o agente frontend para criar o componente de login"
"Peca ao agente database para revisar essa migration"
"@agent-architect avalie essa proposta de arquitetura"
```

---

## Skills (slash commands)

| Comando | O que faz |
|---------|-----------|
| `/review` | Code review estruturado com veredicto formal (PASS/FAIL/NEEDS DISCUSSION) |
| `/ship` | Pipeline completo: lint → test → build → commit |
| `/refactor` | Analise e refatoracao com plano antes de executar |
| `/test` | Gera testes ou roda suite existente |
| `/security` | Auditoria de seguranca (secrets, vulnerabilidades, deps) |
| `/debug` | Investiga bug: reproduz → isola → diagnostica → corrige |
| `/handoff` | Salva contexto da sessao atual para continuar em outra sessao |
| `/compact` | Resume sessao atual em bloco estruturado para liberar contexto |
| `/perf` | Analise de performance: N+1, O(n²), re-renders, cache, I/O |
| `/review-deep` | Review paralelo com 4 agentes (code, security, test, consequences) |
| `/dispatch` | Orquestração de sub-agentes com auto-triggers |
| `/tdd` | Test-driven development: RED → GREEN → REFACTOR |
| `/explore` | Exploração estruturada de codebase (discovery + deep dive) |
| `/contextualize` | Gera .context.md por diretório para orientação |
| `/brainstorm` | Ideação criativa: gera, avalia e prioriza ideias |
| `/boot` | Inicialização de sessão com memória e contexto |
| `/agent-memory` | Memória persistente entre sessões (long-term + session) |
| `/task-tracking` | Todos persistentes em arquivo (sobrevive entre sessões) |
| `/sync-memory` | Reconcilia memória local + remoto + Obsidian |
| `/loop-recovery` | Detecta e escapa loops de retry improdutivos |

### Exemplos
```
/review src/api/
/ship "feat: add user authentication"
/refactor src/utils/helpers.ts
/test src/services/user.service.ts
/test run
/security full
/debug "erro 500 no endpoint /api/users"
/handoff
```

---

## Hooks automaticos

| Hook | Evento | O que faz |
|------|--------|-----------|
| **Lint** | PostToolUse (Write/Edit) | Formata codigo automaticamente |
| **Bash Security** | PreToolUse (Bash) | Bloqueia comandos perigosos (fork bombs, pipes para shell, etc) |
| **Secret Scanner** | PostToolUse (Write/Edit) | Detecta credenciais vazadas em codigo |
| **Protecao** | PreToolUse (Write/Edit) | Bloqueia edicao de .env, credentials, secrets, .pem, .key |
| **Contexto** | SessionStart | Detecta stack do projeto e injeta capacidades na sessao |
| **Reforco** | UserPromptSubmit (a cada 5 prompts) | Re-injeta regras criticas para combater esquecimento |
| **Memoria** | PreCompact | Preserva lembretes apos compactacao de contexto |
| **Context Reminder** | UserPromptSubmit (a cada 3 prompts) | Re-injeta regras e skills no contexto |
| **Pendencias** | Stop | Detecta TODOs/FIXMEs e pergunta se quer continuar |

### Linguagens suportadas pelo lint

| Extensao | Ferramentas | Acao |
|----------|------------|------|
| `.py` | `ruff` | lint fix + format |
| `.ts` `.tsx` | `eslint` + `prettier` | lint fix + format |
| `.js` `.jsx` | `eslint` + `prettier` | lint fix + format |
| `.go` | `gofmt` + `golangci-lint` | format + lint fix |
| `.sql` | `sqlfluff` | lint fix (dialeto auto-detectado) |

---

## Rules (regras por contexto)

Rules sao carregadas **sob demanda** quando o Claude le arquivos que batem com o glob pattern:

| Rule | Ativada em | Conteudo |
|------|-----------|----------|
| `python.md` | `**/*.py` | Type hints, f-strings, pathlib, docstrings Google |
| `typescript.md` | `**/*.ts/*.tsx/*.js/*.jsx` | Interface vs type, const, async/await, React |
| `go.md` | `**/*.go` | Error handling, interfaces, table-driven tests |
| `sql.md` | `**/*.sql` | Keywords uppercase, CTEs, indexacao, naming |
| `security.md` | `**/*` | OWASP, sanitizacao, secrets, HTTPS |
| `testing.md` | Arquivos de teste | AAA, nomes descritivos, fixtures, edge cases |

---

## Padroes comportamentais (inspirados no Ring)

O CLAUDE.md inclui padroes avancados de engenharia de prompt:

### Regra dos 3 arquivos
Se uma tarefa exige ler/editar mais de 3 arquivos, o Claude delega automaticamente para um sub-agente. Isso previne estouro de contexto.

### Hierarquia de duvidas
Antes de perguntar ao usuario, o Claude tenta resolver sozinho: contexto da conversa → CLAUDE.md → codigo existente → boas praticas → so entao pergunta.

### Anti-racionalizacao
Tabela de "pensamentos-armadilha" que o Claude deve reconhecer e evitar. Exemplo: "O codigo parece limpo" nao e motivo para pular revisao.

### Resistencia a pressao
Se o usuario pedir para pular testes ou revisao, o Claude sugere o minimo viavel em vez de obedecer cegamente.

### Reforco periodico
A cada 5 prompts, um hook re-injeta regras criticas no contexto para combater o "esquecimento" em sessoes longas.

---

## Permissions pre-configuradas

### Permitido automaticamente
- Leitura de arquivos, busca, grep
- Comandos de lint (ruff, eslint, prettier, gofmt, golangci-lint, sqlfluff)
- Comandos de teste (pytest, npm test, go test)
- Git somente leitura (status, diff, log, branch, show, blame)
- Comandos seguros (ls, cat, head, tail, echo, which)

### Bloqueado sempre
- `rm -rf /`, `rm -rf ~` e variantes destrutivas
- `git push --force` para main/master
- `git reset --hard origin/*`
- `chmod -R 777`
- Pipe de curl/wget para bash/sh
- Comandos destrutivos de disco (mkfs, dd)

---

## MCP Servers

Pre-configurado com GitHub e PostgreSQL MCP. Para ativar:

```bash
# Adicione ao seu .bashrc ou .env
export GITHUB_TOKEN='ghp_seu_token_aqui'
export DATABASE_URL='postgresql://user:pass@localhost:5432/dev'
```

- **GitHub**: interacao com issues, PRs e repos diretamente.
- **PostgreSQL**: consulta de schemas, SELECTs e analise de indices durante debug (use apenas em banco de dev).
- **Filesystem**: acesso controlado a `~/projects`.

---

## Atalhos de teclado

| Atalho | Acao |
|--------|------|
| `Ctrl+K, Ctrl+R` | /review |
| `Ctrl+K, Ctrl+T` | /test |
| `Ctrl+K, Ctrl+S` | /ship |
| `Ctrl+K, Ctrl+D` | /debug |

---

## Configs de linter (referencia)

Arquivos em `config/` para copiar na raiz de cada projeto:

```bash
cp ~/dotfiles/config/ruff.toml ./ruff.toml        # Python
cp ~/dotfiles/config/.sqlfluff ./.sqlfluff         # SQL
cp ~/dotfiles/config/golangci.yml ./.golangci.yml  # Go
```

JS/TS: crie `.eslintrc.*` e `.prettierrc` direto no projeto.

---

## Aliases de shell

| Alias | Acao |
|-------|------|
| `dotfiles-update` | `git pull` no repo de dotfiles |
| `dotfiles-status` | `git status` do repo |
| `lint-check` | Verifica dependencias de lint instaladas |

---

## Estrutura do repositorio

```
dotfiles/
├── README.md
├── install.sh                 ← instalador principal
├── scripts/
│   └── check_deps.sh         ← verificador de dependencias
├── claude/
│   ├── CLAUDE.md              ← convencoes globais
│   ├── settings.json          ← hooks + permissions
│   ├── .mcp.json              ← MCP servers
│   ├── keybindings.json       ← atalhos
│   ├── hooks/
│   │   ├── lint_hook.sh       ← hook de lint
│   │   ├── bash_security.sh   ← seguranca de comandos
│   │   ├── secret_scan.sh     ← scanner de credenciais
│   │   ├── session_start.sh   ← deteccao de stack
│   │   └── claude_md_reminder.sh   ← re-injeção de contexto
│   ├── agents/
│   │   ├── frontend.md
│   │   ├── backend.md
│   │   ├── database.md
│   │   ├── architect.md
│   │   ├── devops.md
│   │   └── security.md
│   ├── skills/
│   │   ├── review/SKILL.md
│   │   ├── ship/SKILL.md
│   │   ├── refactor/SKILL.md
│   │   ├── test/SKILL.md
│   │   ├── security/SKILL.md
│   │   ├── debug/SKILL.md
│   │   ├── handoff/SKILL.md
│   │   ├── compact/SKILL.md
│   │   ├── perf/SKILL.md
│   │   ├── dispatch/SKILL.md
│   │   ├── agent-memory/SKILL.md
│   │   ├── task-tracking/SKILL.md
│   │   ├── boot/SKILL.md
│   │   ├── review-deep/SKILL.md
│   │   ├── tdd/SKILL.md
│   │   ├── explore/SKILL.md
│   │   ├── contextualize/SKILL.md
│   │   └── brainstorm/SKILL.md
│   └── rules/
│       ├── python.md
│       ├── typescript.md
│       ├── go.md
│       ├── sql.md
│       ├── security.md
│       └── testing.md
├── config/
│   ├── ruff.toml
│   ├── .sqlfluff
│   └── golangci.yml
└── shell/
    └── .bashrc_extras
```

---

---

## Taxonomia de regras

As regras seguem hierarquia formal (ver `rules/README.md`):

| Tier | Nome | Força |
|------|------|-------|
| 1 | **Commandments** (🔴) | Bloqueiam review. Sem exceção |
| 2 | **Edicts** (🟡) | Precisam justificativa para ignorar |
| 3 | **Counsel** (🔵) | Sugestões. Nunca bloqueiam |

---

## Sistema de Memória Unificado

O sistema de memória permite continuidade entre sessões e máquinas.

### Arquitetura

```
                    ┌─────────────────────┐
                    │   Claude Code CLI   │
                    └─────────┬───────────┘
                              │
                    ┌─────────▼───────────┐
                    │   settings.json     │
                    │   (hooks lifecycle) │
                    └──┬──────┬────────┬──┘
                       │      │        │
              SessionStart  PreCompact  Stop
                       │      │        │
                    ┌──▼──────▼────────▼──┐
                    │  memory_bridge.py   │
                    │  (query/store)      │
                    └──┬──────────────┬───┘
                       │              │
              ┌────────▼──┐    ┌──────▼──────┐
              │ ChromaDB  │    │  ~/memory/  │
              │ (vetores) │    │ (git repo)  │
              └───────────┘    └─────────────┘
```

### Fluxo por evento

| Evento | Ação automática |
|--------|----------------|
| **SessionStart** | Consulta memória → injeta contexto do projeto |
| **PreCompact** | Salva resumo da sessão antes de compactar |
| **Stop** | Auto-commit do repositório de memória |
| **/handoff** | Persiste handoff na memória semântica |
| **/sync-memory** | Reconcilia todas as camadas |

### Setup em máquina nova

```bash
git clone https://github.com/vini-haa/dotfiles ~/dotfiles
cd ~/dotfiles && bash install.sh
# install.sh configura automaticamente:
# - ChromaDB + TurboQuant (pip)
# - ~/memory/ (git repo)
# - Índice de embeddings (rebuild incremental)
# - ruah (npm, opcional)
```

### Comandos de manutenção

```bash
# Status do sistema de memória
python3 ~/dotfiles/scripts/memory_bridge.py status

# Buscar memórias
python3 ~/dotfiles/scripts/memory_bridge.py query --text "autenticação JWT" --top-k 5

# Armazenar manualmente
python3 ~/dotfiles/scripts/memory_bridge.py store --text "..." --tags "t1,t2" --project "nome"

# Reconciliar tudo
/sync-memory

# Reconstruir índice
python3 ~/dotfiles/scripts/memory_bridge.py rebuild --incremental
```

## Como adicionar/modificar

### Novo agente
Crie `claude/agents/nome.md` com frontmatter YAML + instrucoes.

### Nova skill
Crie `claude/skills/nome/SKILL.md` com frontmatter YAML + workflow.

### Nova rule
Crie `claude/rules/nome.md` com `paths:` no frontmatter.

### Novo hook
Adicione ao array correspondente em `claude/settings.json`.

Apos qualquer mudanca: `git commit && git push`. Nas outras maquinas: `git pull`.
