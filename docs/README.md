# Documentation

## Structure

```
docs/
├── README.md              ← this file
├── audit/                 ← audits of the repository state
│   └── 00-initial-state.md
├── decisions/             ← ADRs (Architecture Decision Records)
│   ├── 01-ruah-analysis.md
│   ├── 02-mempalace-analysis.md
│   └── 03-turboquant-analysis.md
└── ARCHITECTURE.md        ← architecture overview
```

## Conventions

- **audit/** — snapshots of the repository state at specific points in time
- **decisions/** — technical decisions with context, alternatives, and rationale
- Markdown files, kebab-case names with a numeric prefix
- Content in English, code/commands in English
