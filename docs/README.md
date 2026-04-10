# Documentacao

## Estrutura

```
docs/
├── README.md              ← este arquivo
├── audit/                 ← auditorias do estado do repositorio
│   └── 00-estado-inicial.md
├── decisions/             ← ADRs (Architecture Decision Records)
│   ├── 01-ruah-analysis.md
│   ├── 02-mempalace-analysis.md
│   └── 03-turboquant-analysis.md
└── ARCHITECTURE.md        ← visao geral da arquitetura
```

## Convencoes

- **audit/** — snapshots do estado do repositorio em momentos especificos
- **decisions/** — decisoes tecnicas com contexto, alternativas e justificativa
- Arquivos em Markdown, nomes em kebab-case com prefixo numerico
- Conteudo em portugues, codigo/comandos em ingles
