# Initial State Audit — dotfiles

**Date:** 2026-04-10
**Repository:** https://github.com/vini-haa/dotfiles.git
**Branch:** main
**Last commit:** ba6b708 — feat: add confidence score and anti-prompt-injection to /review skill

---

## 1. Environment

| Tool | Version | Path |
|---|---|---|
| Node.js | v24.13.1 | /c/Program Files/nodejs/node |
| npm | 11.10.1 | /c/Program Files/nodejs/npm |
| Python | 3.14.3 | WindowsApps/python3 |
| pip | 25.3 | Python 3.14 |
| Git | 2.53.0.windows.1 | /mingw64/bin/git |

**Platform:** Windows 11 Pro 10.0.26200 (Git Bash)

---

## 2. Repository Structure

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

## 3. Existing Components

### 3.1 Hooks (1 total)

| Hook | File | Function |
|---|---|---|
| Universal lint | `lint_hook.sh` | Runs the linter/formatter after Write/Edit, by extension (.py→ruff, .ts/.js→eslint+prettier, .go→gofmt+golangci-lint, .sql→sqlfluff) |

### 3.2 Agents (6 total)

| Agent | Model | Function |
|---|---|---|
| architect | opus | Architecture decisions, system design |
| backend | sonnet | APIs, auth, business logic |
| database | sonnet | SQL, modeling, migrations, performance |
| devops | sonnet | CI/CD, Docker, K8s, IaC |
| frontend | sonnet | UI, components, CSS, accessibility |
| security | opus | OWASP audit, read-only (plan mode) |

### 3.3 Skills (8 total)

| Skill | Command | Function |
|---|---|---|
| debug | /debug | Bug investigation: reproduce → isolate → diagnose → fix |
| handoff | /handoff | Generates a handoff document for a new session |
| loop-recovery | /loop-recovery | Detects and escapes unproductive loops |
| refactor | /refactor | Refactoring without changing behavior |
| review | /review | Code review with a formal verdict (PASS/FAIL) |
| security | /security-audit | Complete security audit |
| ship | /ship | Pipeline: lint → test → build → commit |
| test | /test | Generates or runs tests |

### 3.4 Rules (6 total)

| Rule | Scope | Globs |
|---|---|---|
| python | Python standards | *.py |
| typescript | TS/JS standards | *.ts, *.tsx, *.js, *.jsx |
| go | Go standards | *.go |
| sql | SQL standards | *.sql |
| security | General security | All files |
| testing | Test standards | *test*, *spec*, __tests__ |

### 3.5 settings.json — Registered Hooks

| Type | Trigger | Action |
|---|---|---|
| PreToolUse | Edit/Write/MultiEdit | Blocks sensitive files (.env, .pem, .key, credentials, secrets) |
| PostToolUse | Write/Edit/MultiEdit | Runs lint_hook.sh (30s timeout) |
| SessionStart | — | Injects context: active hooks, agents, skills, PT-BR |
| PreCompact | — | Reinforces the configuration after compaction |
| UserPromptSubmit | Every 5 prompts | Reinforces the rules: PT-BR, 3-file rule, anti-rationalization |
| Stop | — | Detects TODO/FIXME in the final response |

### 3.6 install.sh

Idempotent installer with 7 stages:
1. Creates the ~/.claude/{hooks,agents,skills,rules} directories
2. Installs the main files via symlink (fallback: copy)
3. Installs lint_hook.sh with chmod +x
4. Installs the agents (recursive symlinks)
5. Installs the skills (recursive symlinks)
6. Installs the rules (recursive symlinks)
7. Configures the shell (source .bashrc_extras)
8. Runs scripts/check_deps.sh

---

## 4. Gaps Identified

### 4.1 Memory
- **No persistent memory system** — every session starts from scratch
- **No cross-machine integration** — context does not travel
- **No embeddings** — semantic search is nonexistent
- The `~/.claude/projects/*/memory/` directory exists (Claude Code's auto memory) but is primitive (.md files with no semantic search)

### 4.2 Coordination
- **No support for parallel sessions** — every session is isolated
- **No file claiming** — risk of conflicts in large projects
- **No merge DAG** — manual merges between parallel branches

### 4.3 Infrastructure
- **No centralized memory repository** — ~/memory/ does not exist
- **No vector compression** — does not use TurboQuant or similar
- **No Obsidian synchronization** — vaults are not connected
- **No /boot skill** — mentioned in the plan but does not exist yet
- **No /sync-memory skill** — memory reconciliation does not exist

### 4.4 Agents
- **No fadex-context agent** — FADEX knowledge is not formalized
- **No data-analyst agent** — data analysis is manual

---

## 5. Anticipated Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| ruah unavailable or incompatible with Windows | High | Medium | Implement a fallback with native git worktree |
| mempalace does not exist as a public repo | High | High | Use chromadb or a custom vector store |
| TurboQuant has no builds for Windows/Python 3.14 | Medium | Low | A pure-numpy fallback is acceptable |
| The Anthropic API for embeddings has a cost | Low | Low | Local sentence-transformers as an alternative |
| Python 3.14 is very recent — incompatibilities | Medium | Medium | Check each library before installing |
| install.sh assumes Linux/Mac — adjust for Windows | Medium | High | Test each change in Git Bash |

---

## 6. Next Steps

→ **PHASE 1:** Analysis of the 3 external systems (ruah, mempalace, TurboQuant)
