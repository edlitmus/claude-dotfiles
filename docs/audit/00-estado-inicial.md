# Auditoria do Estado Inicial — dotfiles

**Data:** 2026-04-10
**Repositório:** https://github.com/vini-haa/dotfiles.git
**Branch:** main
**Último commit:** ba6b708 — feat: add confidence score and anti-prompt-injection to /review skill

---

## 1. Ambiente

| Ferramenta | Versão | Caminho |
|---|---|---|
| Node.js | v24.13.1 | /c/Program Files/nodejs/node |
| npm | 11.10.1 | /c/Program Files/nodejs/npm |
| Python | 3.14.3 | WindowsApps/python3 |
| pip | 25.3 | Python 3.14 |
| Git | 2.53.0.windows.1 | /mingw64/bin/git |

**Plataforma:** Windows 11 Pro 10.0.26200 (Git Bash)

---

## 2. Estrutura do Repositório

```
dotfiles/
├── README.md
├── install.sh
├── claude-kit.zip
├── config/
│   ├── ruff.toml
│   ├── .sqlfluff
│   └── golangci.yml
├── scripts/
│   └── check_deps.sh
├── shell/
│   └── .bashrc_extras
└── claude/
    ├── CLAUDE.md
    ├── settings.json
    ├── .mcp.json
    ├── keybindings.json
    ├── hooks/
    │   └── lint_hook.sh
    ├── agents/
    │   ├── architect.md
    │   ├── backend.md
    │   ├── database.md
    │   ├── devops.md
    │   ├── frontend.md
    │   └── security.md
    ├── skills/
    │   ├── debug/SKILL.md
    │   ├── handoff/SKILL.md
    │   ├── loop-recovery/SKILL.md
    │   ├── refactor/SKILL.md
    │   ├── review/SKILL.md
    │   ├── security/SKILL.md
    │   ├── ship/SKILL.md
    │   └── test/SKILL.md
    └── rules/
        ├── python.md
        ├── typescript.md
        ├── go.md
        ├── sql.md
        ├── security.md
        └── testing.md
```

---

## 3. Componentes Existentes

### 3.1 Hooks (1 total)

| Hook | Arquivo | Função |
|---|---|---|
| Lint universal | `lint_hook.sh` | Roda linter/formatter após Write/Edit por extensão (.py→ruff, .ts/.js→eslint+prettier, .go→gofmt+golangci-lint, .sql→sqlfluff) |

### 3.2 Agentes (6 total)

| Agente | Modelo | Função |
|---|---|---|
| architect | opus | Decisões de arquitetura, design de sistemas |
| backend | sonnet | APIs, auth, lógica de negócio |
| database | sonnet | SQL, modelagem, migrations, performance |
| devops | sonnet | CI/CD, Docker, K8s, IaC |
| frontend | sonnet | UI, componentes, CSS, acessibilidade |
| security | opus | Auditoria OWASP, read-only (plan mode) |

### 3.3 Skills (8 total)

| Skill | Comando | Função |
|---|---|---|
| debug | /debug | Investigação de bugs: reproduce → isolate → diagnose → fix |
| handoff | /handoff | Gera documento de handoff para nova sessão |
| loop-recovery | /loop-recovery | Detecta e escapa loops improdutivos |
| refactor | /refactor | Refatoração sem mudança de comportamento |
| review | /review | Code review com veredicto formal (PASS/FAIL) |
| security | /security-audit | Auditoria de segurança completa |
| ship | /ship | Pipeline: lint → test → build → commit |
| test | /test | Gera ou roda testes |

### 3.4 Rules (6 total)

| Rule | Escopo | Globs |
|---|---|---|
| python | Padrões Python | *.py |
| typescript | Padrões TS/JS | *.ts, *.tsx, *.js, *.jsx |
| go | Padrões Go | *.go |
| sql | Padrões SQL | *.sql |
| security | Segurança geral | Todos os arquivos |
| testing | Padrões de teste | *test*, *spec*, __tests__ |

### 3.5 settings.json — Hooks Registrados

| Tipo | Trigger | Ação |
|---|---|---|
| PreToolUse | Edit/Write/MultiEdit | Bloqueia arquivos sensíveis (.env, .pem, .key, credentials, secrets) |
| PostToolUse | Write/Edit/MultiEdit | Executa lint_hook.sh (timeout 30s) |
| SessionStart | — | Injeta contexto: hooks ativos, agentes, skills, PT-BR |
| PreCompact | — | Reforça configuração após compactação |
| UserPromptSubmit | A cada 5 prompts | Reforça regras: PT-BR, 3 arquivos, anti-racionalização |
| Stop | — | Detecta TODO/FIXME na resposta final |

### 3.6 install.sh

Instalador idempotente com 7 etapas:
1. Cria diretórios ~/.claude/{hooks,agents,skills,rules}
2. Instala arquivos principais via symlink (fallback: cópia)
3. Instala lint_hook.sh com chmod +x
4. Instala agentes (symlinks recursivos)
5. Instala skills (symlinks recursivos)
6. Instala rules (symlinks recursivos)
7. Configura shell (source .bashrc_extras)
8. Executa scripts/check_deps.sh

---

## 4. Gaps Identificados

### 4.1 Memória
- **Sem sistema de memória persistente** — cada sessão parte do zero
- **Sem integração entre máquinas** — contexto não viaja
- **Sem embeddings** — busca semântica inexistente
- O diretório `~/.claude/projects/*/memory/` existe (auto memory do Claude Code) mas é primitivo (arquivos .md sem busca semântica)

### 4.2 Coordenação
- **Sem suporte a sessões paralelas** — cada sessão é isolada
- **Sem file claiming** — risco de conflito em projetos grandes
- **Sem DAG de merge** — merge manual entre branches paralelas

### 4.3 Infraestrutura
- **Sem repositório de memória centralizado** — ~/memory/ não existe
- **Sem compressão de vetores** — não usa TurboQuant ou similar
- **Sem sincronização com Obsidian** — vaults não conectados
- **Sem skill /boot** — mencionada no plano mas não existe ainda
- **Sem skill /sync-memory** — reconciliação de memória não existe

### 4.4 Agentes
- **Sem agente fadex-context** — conhecimento FADEX não formalizado
- **Sem agente data-analyst** — análise de dados manual

---

## 5. Riscos Antecipados

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| ruah não disponível ou incompatível com Windows | Alta | Médio | Implementar fallback com git worktree nativo |
| mempalace não existe como repo público | Alta | Alto | Usar chromadb ou vector store próprio |
| TurboQuant não tem builds para Windows/Python 3.14 | Média | Baixo | Fallback numpy puro é aceitável |
| Anthropic API para embeddings tem custo | Baixa | Baixo | sentence-transformers local como alternativa |
| Python 3.14 muito recente — incompatibilidades | Média | Médio | Verificar cada lib antes de instalar |
| install.sh assume Linux/Mac — ajustar para Windows | Média | Alto | Testar cada alteração no Git Bash |

---

## 6. Próximos Passos

→ **FASE 1:** Análise dos 3 sistemas externos (ruah, mempalace, TurboQuant)
