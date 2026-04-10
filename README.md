# Dotfiles — Claude Code com Memória Persistente

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Feito para Claude Code](https://img.shields.io/badge/feito%20para-Claude%20Code-blueviolet.svg)](https://claude.ai/code)

Dotfiles que dão memória ao Claude Code. Toda sessão nova já sabe quem você é, como você trabalha e o que estava fazendo — sem você explicar nada.

---

## O que é isso

O Claude Code começa do zero a cada sessão. Você explica o mesmo contexto, repete as mesmas preferências, perde continuidade entre sessões e máquinas. Sessões paralelas podem conflitar sem coordenação.

Este repositório resolve isso com três camadas:

1. **Memória semântica persistente** — um repositório git privado (`~/memory/`) com embeddings vetoriais que sincronizam entre máquinas
2. **Hooks automáticos** — injetam contexto ao abrir, salvam contexto ao fechar, protegem arquivos sensíveis, rodam lint
3. **Agentes + skills + rules** — 8 agentes especializados, 20 skills de workflow e 6 conjuntos de regras por linguagem

---

## Como funciona

```
ABERTURA DE SESSÃO
┌─────────────────────────────────────────────────────┐
│ SessionStart hook                                   │
│   └→ memory_bridge.py query                         │
│       └→ busca em ~/memory/.embeddings/vectors.npy  │
│           └→ injeta contexto: "você estava fazendo X│
│              no projeto Y, com stack Z"             │
└─────────────────────────────────────────────────────┘

DURANTE O TRABALHO
┌─────────────────────────────────────────────────────┐
│ /handoff → salva sessão na memória semântica        │
│ /boot    → carrega memória + estado do projeto      │
│ PreCompact → persiste contexto antes de compactar   │
│ Lint automático → roda a cada Write/Edit            │
└─────────────────────────────────────────────────────┘

FECHAMENTO DE SESSÃO
┌─────────────────────────────────────────────────────┐
│ Stop hook                                           │
│   └→ cd ~/memory && git add -A && git commit        │
│       └→ memória sincronizada automaticamente       │
└─────────────────────────────────────────────────────┘

NOVA MÁQUINA
┌─────────────────────────────────────────────────────┐
│ git clone dotfiles + git clone memory               │
│   └→ bash install.sh                                │
│       └→ rebuild embeddings (~10 segundos)           │
│           └→ mesmo contexto da máquina anterior     │
└─────────────────────────────────────────────────────┘
```

---

## Instalação rápida

### Pré-requisitos

- [Claude Code](https://claude.ai/code) instalado
- Python 3.9+
- Git configurado
- Node.js 18+ (opcional, para ruah)

### Setup em nova máquina (~5 minutos)

**Passo 1 — Clonar e instalar dotfiles**

```bash
git clone https://github.com/vini-haa/dotfiles ~/dotfiles
cd ~/dotfiles && bash install.sh
```

> **Nota:** Clone obrigatoriamente em `~/dotfiles`. Os hooks de memória usam `$HOME/dotfiles` como caminho fixo.

O `install.sh` é idempotente — instala tudo automaticamente:
- Symlinks para `~/.claude/` (settings, hooks, agents, skills, rules)
- Dependências Python (sentence-transformers para embeddings locais, turboquant-vectors)
- Repositório de memória em `~/memory/`
- ruah para coordenação de sessões (opcional)
- Validação de JSONs e permissões

**Passo 2 — Criar repo privado de memória no GitHub**

```bash
gh repo create memory --private --description "Memória persistente — Claude Code"
```

**Passo 3 — Conectar e fazer push**

```bash
cd ~/memory
git remote add origin git@github.com:SEU_USUARIO/memory
git push -u origin main
```

**Passo 4 — Sua apresentação ao sistema**

```bash
python3 ~/dotfiles/scripts/memory_bridge.py store \
  --text "SEU NOME. Stack: SUAS TECNOLOGIAS. Projetos ativos: SEUS PROJETOS. Regras: SUAS REGRAS CRÍTICAS." \
  --tags "perfil,global" \
  --project "global"
```

**Passo 5 — Validar**

```bash
python3 ~/dotfiles/scripts/memory_bridge.py status
python3 ~/dotfiles/scripts/memory_bridge.py query --text "meu perfil" --top-k 3
```

### Atualizar máquina existente

```bash
cd ~/dotfiles && git pull        # symlinks refletem mudanças automaticamente
cd ~/memory && git pull          # sincroniza memória da outra máquina
python3 ~/dotfiles/scripts/memory_bridge.py rebuild --incremental
```

---

## Sistema de memória

Três camadas trabalham juntas:

| Camada | Onde | O que faz |
|--------|------|-----------|
| **Markdown** | `~/memory/projects/`, `~/memory/global/` | Arquivos `.md` com frontmatter — legíveis, versionados, diffable |
| **Embeddings** | `~/memory/.embeddings/` | `index.json` (metadados) + `vectors.npy` (vetores float32) — busca semântica |
| **memory_bridge.py** | `~/dotfiles/scripts/` | Interface CLI que conecta tudo |

### Comandos

```bash
# Armazenar uma memória
python3 ~/dotfiles/scripts/memory_bridge.py store \
  --text "GED usa JWT auth com refresh tokens" \
  --tags "ged,jwt,auth" \
  --project "ged-fadex"
# → ✓ Memória armazenada: a1b2c3d4e5f6 (embeddings: onnx)

# Buscar memórias similares
python3 ~/dotfiles/scripts/memory_bridge.py query \
  --text "autenticação no GED" \
  --top-k 5
# → [0.4058] (ged-fadex) GED usa JWT auth com refresh tokens

# Status do sistema
python3 ~/dotfiles/scripts/memory_bridge.py status
# → ✓ Índice: 5 memórias (modelo: onnx)
# → vectors.npy: 7.6 KB

# Reconstruir índice a partir dos .md
python3 ~/dotfiles/scripts/memory_bridge.py rebuild --incremental

# Sincronizar com Obsidian (se configurado)
python3 ~/dotfiles/scripts/memory_bridge.py sync
```

### Como os embeddings funcionam

O `memory_bridge.py` tenta, nesta ordem:
1. **ONNX** (all-MiniLM-L6-v2, 384 dims) — via pacote chromadb, roda local, sem API
2. **Char-trigram** — fallback se ONNX não estiver disponível, funciona sem dependências

Os vetores são salvos em `vectors.npy` (numpy float32) e os metadados em `index.json` (JSON texto). Ambos sincronizam via git.

---

## Sincronização entre máquinas

O ciclo é automático:

| Momento | O que acontece | Quem faz |
|---------|---------------|----------|
| Abrir sessão | `git pull` no `~/memory/` + query de contexto | Hook SessionStart |
| Antes de compactar | `memory_bridge.py store` salva contexto | Hook PreCompact |
| Fechar sessão | `git add -A && git commit` no `~/memory/` | Hook Stop |
| Trocar de máquina | `git pull` + `rebuild --incremental` | Manual ou `/sync-memory` |

O push automático não está habilitado (para evitar conflitos silenciosos). Use `/sync-memory` ou `cd ~/memory && git push` manualmente.

---

## Coordenação de sessões paralelas (ruah)

O [ruah](https://www.npmjs.com/package/@levi-tc/ruah) coordena múltiplas sessões Claude Code trabalhando no mesmo repositório, usando git worktrees isolados e file claiming.

O `scripts/ruah_bridge.sh` integra ruah com a memória:

```bash
# Ao iniciar uma task: injeta contexto de memória no worktree
bash ~/dotfiles/scripts/ruah_bridge.sh start nome-da-task

# Ao completar: persiste resultado na memória
bash ~/dotfiles/scripts/ruah_bridge.sh complete nome-da-task
```

Instalação opcional — o sistema funciona sem ruah.

---

## Agentes especializados

Use agentes para delegar tarefas com contexto especializado:

| Agente | Quando usar | Modelo |
|--------|------------|--------|
| `frontend` | UI, componentes, CSS, acessibilidade, React/Vue/Angular | Sonnet |
| `backend` | APIs, auth, services, middleware, integração | Sonnet |
| `database` | Modelagem, queries, migrations, indexação, performance | Sonnet |
| `architect` | Design de sistemas, trade-offs, escolha de tecnologias | Opus |
| `devops` | Docker, CI/CD, IaC, monitoramento, deploy | Sonnet |
| `security` | Auditoria, vulnerabilidades, OWASP (read-only, não edita) | Opus |
| `fadex-context` | Sistemas internos FADEX, SAGI, UFPI/IFPI, regulamentações | Sonnet |
| `data-analyst` | SQL Server/PostgreSQL, queries complexas, ETL, BI | Sonnet |

```
"Use o agente frontend para criar o componente de login"
"Peça ao agente database para revisar essa migration"
```

---

## Skills (slash commands)

| Comando | O que faz |
|---------|-----------|
| `/review` | Code review estruturado com veredicto formal (PASS/FAIL/NEEDS DISCUSSION) |
| `/review-deep` | Review paralelo com 4 agentes (code, security, test, consequences) |
| `/ship` | Pipeline completo: lint → test → build → commit |
| `/refactor` | Análise e refatoração com plano antes de executar |
| `/test` | Gera testes ou roda suite existente |
| `/tdd` | Test-driven development: RED → GREEN → REFACTOR |
| `/security` | Auditoria de segurança (secrets, vulnerabilidades, deps) |
| `/debug` | Investiga bug: reproduz → isola → diagnostica → corrige |
| `/perf` | Análise de performance: N+1, O(n²), re-renders, cache, I/O |
| `/handoff` | Salva contexto da sessão + persiste na memória semântica |
| `/boot` | Inicialização: consulta memória → carrega estado → detecta stack |
| `/sync-memory` | Reconcilia git + embeddings + Obsidian |
| `/loop-recovery` | Detecta e escapa loops de retry improdutivos |
| `/compact` | Resume sessão para liberar contexto |
| `/dispatch` | Orquestração de sub-agentes com auto-triggers |
| `/explore` | Exploração estruturada de codebase (discovery + deep dive) |
| `/contextualize` | Gera .context.md por diretório para orientação |
| `/brainstorm` | Ideação criativa: gera, avalia e prioriza ideias |
| `/agent-memory` | Memória persistente entre sessões (long-term + session) |
| `/task-tracking` | Todos persistentes em arquivo (sobrevive entre sessões) |

```
/review src/api/
/ship "feat: add user authentication"
/debug "erro 500 no endpoint /api/users"
/handoff
/boot
/sync-memory
```

---

## Hooks automáticos

| Hook | Evento | O que faz |
|------|--------|-----------|
| **Proteção de arquivos** | PreToolUse (Edit/Write) | Bloqueia edição de .env, credentials, secrets, .pem, .key |
| **Bash security** | PreToolUse (Bash) | Bloqueia comandos perigosos (fork bombs, pipes para shell) |
| **Lint** | PostToolUse (Write/Edit) | Formata código automaticamente |
| **Secret scanner** | PostToolUse (Write/Edit) | Detecta credenciais vazadas em código |
| **Memória: injeção** | SessionStart | Consulta `memory_bridge.py` e injeta contexto do projeto |
| **Memória: captura** | PreCompact | Salva contexto da sessão antes de compactar |
| **Memória: sync** | Stop | Auto-commit do `~/memory/` |
| **Reforço de regras** | UserPromptSubmit | Re-injeta regras críticas a cada N prompts |
| **Pendências** | Stop | Detecta TODO/FIXME e pergunta se quer continuar |

### Linguagens suportadas pelo lint

| Extensão | Ferramentas |
|----------|------------|
| `.py` | ruff (lint + format) |
| `.ts` `.tsx` `.js` `.jsx` | eslint + prettier |
| `.go` | gofmt + golangci-lint |
| `.sql` | sqlfluff (dialeto auto-detectado) |

---

## Primeiros passos para beta testers

### 1. Siga o setup acima (passos 1-5)

### 2. Armazene seu perfil pessoal

Personalize e rode:

```bash
python3 ~/dotfiles/scripts/memory_bridge.py store \
  --text "SEU NOME, CARGO. Stack: LINGUAGENS E FRAMEWORKS. \
Projetos ativos: PROJETO A (stack), PROJETO B (stack). \
Padrões: SEUS PADRÕES DE CÓDIGO. \
Regras críticas: COISAS QUE NUNCA DEVEM ACONTECER." \
  --tags "perfil,global" \
  --project "global"
```

### 3. Use por uma sessão real de trabalho

Trabalhe normalmente em qualquer projeto. O sistema captura contexto nos bastidores.

### 4. Use `/handoff` ao fechar a sessão

Isso persiste o estado completo na memória semântica.

### 5. Abra uma nova sessão e observe

O hook SessionStart vai injetar automaticamente o contexto relevante. Você deve ver algo como:

```
Contexto de memoria injetado: [0.4058] (meu-projeto) ...
```

### 6. Relate o que funcionou e o que não

Abra uma Issue em [github.com/vini-haa/dotfiles/issues](https://github.com/vini-haa/dotfiles/issues) com:
- O que funcionou bem
- O que não funcionou ou ficou confuso
- Sugestões de melhoria

---

## Rules (regras por contexto)

Carregadas sob demanda quando o Claude lê arquivos que batem com o glob:

| Rule | Ativada em | Conteúdo |
|------|-----------|----------|
| `python.md` | `**/*.py` | Type hints, f-strings, pathlib, docstrings Google |
| `typescript.md` | `**/*.ts/*.tsx/*.js/*.jsx` | Interface vs type, const, async/await, React |
| `go.md` | `**/*.go` | Error handling, interfaces, table-driven tests |
| `sql.md` | `**/*.sql` | Keywords uppercase, CTEs, indexação, naming |
| `security.md` | `**/*` | OWASP, sanitização, secrets, HTTPS |
| `testing.md` | Arquivos de teste | AAA, nomes descritivos, fixtures, edge cases |

Hierarquia de severidade:
- **Commandments** (🔴) — bloqueiam review, sem exceção
- **Edicts** (🟡) — precisam justificativa para ignorar
- **Counsel** (🔵) — sugestões, nunca bloqueiam

---

## Padrões comportamentais

O `CLAUDE.md` inclui padrões avançados de engenharia de prompt:

- **Regra dos 3 arquivos** — se a tarefa exige ler/editar mais de 3 arquivos, delega para sub-agente automaticamente
- **Hierarquia de dúvidas** — contexto da conversa → CLAUDE.md → código existente → boas práticas → só então pergunta
- **Anti-racionalização** — tabela de pensamentos-armadilha que o Claude deve reconhecer e evitar
- **Resistência a pressão** — se pedirem para pular testes ou revisão, sugere o mínimo viável
- **Reforço periódico** — hook re-injeta regras críticas a cada N prompts

---

## Permissions pré-configuradas

**Permitido automaticamente:** leitura de arquivos, busca, grep, lint (ruff, eslint, prettier, gofmt, golangci-lint, sqlfluff), testes (pytest, npm test, go test), git somente leitura.

**Bloqueado sempre:** `rm -rf /`, `rm -rf ~`, `git push --force` para main/master, `git reset --hard`, `chmod -R 777`, pipe de curl/wget para bash/sh, comandos destrutivos de disco.

---

## MCP Servers

Pré-configurado com GitHub MCP. Para ativar:

```bash
export GITHUB_TOKEN='ghp_seu_token_aqui'
```

---

## Atalhos de teclado

| Atalho | Ação |
|--------|------|
| `Ctrl+K, Ctrl+R` | /review |
| `Ctrl+K, Ctrl+T` | /test |
| `Ctrl+K, Ctrl+S` | /ship |
| `Ctrl+K, Ctrl+D` | /debug |

---

## Estrutura do repositório

```
dotfiles/
├── README.md
├── install.sh                          ← instalador idempotente
├── scripts/
│   ├── memory_bridge.py                ← memória semântica (store/query/rebuild/sync/status)
│   ├── setup_memory_repo.sh            ← inicializa ~/memory/
│   ├── ruah_bridge.sh                  ← integração ruah + memória
│   └── check_deps.sh                   ← verificador de dependências
├── claude/
│   ├── CLAUDE.md                       ← convenções globais de código
│   ├── settings.json                   ← hooks + permissions
│   ├── .mcp.json                       ← MCP servers
│   ├── keybindings.json                ← atalhos de teclado
│   ├── hooks/
│   │   ├── lint_hook.sh                ← lint automático pós-edição
│   │   ├── bash_security.sh            ← bloqueio de comandos perigosos
│   │   ├── secret_scan.sh              ← detecção de credenciais
│   │   ├── session_start.sh            ← detecção de stack
│   │   └── claude_md_reminder.sh       ← reforço periódico de regras
│   ├── agents/
│   │   ├── frontend.md                 ← UI, React, acessibilidade
│   │   ├── backend.md                  ← APIs, auth, services
│   │   ├── database.md                 ← SQL, modelagem, performance
│   │   ├── architect.md                ← design de sistemas
│   │   ├── devops.md                   ← CI/CD, Docker, infra
│   │   ├── security.md                 ← auditoria OWASP (read-only)
│   │   ├── fadex-context.md            ← contexto FADEX/SAGI/UFPI
│   │   └── data-analyst.md             ← SQL Server, ETL, BI
│   ├── skills/
│   │   ├── review/                     ← /review
│   │   ├── review-deep/                ← /review-deep
│   │   ├── ship/                       ← /ship
│   │   ├── refactor/                   ← /refactor
│   │   ├── test/                       ← /test
│   │   ├── tdd/                        ← /tdd
│   │   ├── security/                   ← /security
│   │   ├── debug/                      ← /debug
│   │   ├── perf/                       ← /perf
│   │   ├── handoff/                    ← /handoff
│   │   ├── boot/                       ← /boot
│   │   ├── sync-memory/                ← /sync-memory
│   │   ├── loop-recovery/              ← /loop-recovery
│   │   ├── compact/                    ← /compact
│   │   ├── dispatch/                   ← /dispatch
│   │   ├── explore/                    ← /explore
│   │   ├── contextualize/              ← /contextualize
│   │   ├── brainstorm/                 ← /brainstorm
│   │   ├── agent-memory/               ← /agent-memory
│   │   └── task-tracking/              ← /task-tracking
│   └── rules/
│       ├── python.md                   ← ativado em *.py
│       ├── typescript.md               ← ativado em *.ts/*.tsx/*.js/*.jsx
│       ├── go.md                       ← ativado em *.go
│       ├── sql.md                      ← ativado em *.sql
│       ├── security.md                 ← ativado em todos os arquivos
│       └── testing.md                  ← ativado em arquivos de teste
├── docs/
│   ├── ARCHITECTURE.md                 ← arquitetura completa com diagramas
│   ├── audit/                          ← auditorias do estado do repo
│   └── decisions/                      ← ADRs (ruah, mempalace, TurboQuant)
├── config/
│   ├── ruff.toml                       ← linter Python
│   ├── .sqlfluff                       ← linter SQL
│   └── golangci.yml                    ← linter Go
└── shell/
    └── .bashrc_extras                  ← aliases (dotfiles-update, lint-check)
```

---

## Como contribuir

- **Reportar problemas ou sugestões:** abra uma [Issue](https://github.com/vini-haa/dotfiles/issues)
- **Novos agentes, skills ou rules:** PRs bem-vindos
- **Mudanças no core** (memory_bridge, hooks, install.sh): abra Issue primeiro para alinhar abordagem
