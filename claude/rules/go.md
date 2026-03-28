---
paths:
  - "**/*.go"
---

# Go

- Siga as convenções idiomáticas de Go — Effective Go é a referência.
- Erros: sempre verifique; retorne `error` em vez de usar panic.
- Nomeação: curta e contextual (`r` para reader, `ctx` para context).
- Structs: campos exportados em PascalCase, privados em camelCase.
- Interfaces: defina no consumidor, não no provedor.
- Interfaces pequenas (1-3 métodos) — composição sobre herança.
- Goroutines: sempre tenha estratégia de cancelamento (`context.Context`).
- Channels: prefira direcionais (`chan<-`, `<-chan`) nas assinaturas.
- Use `table-driven tests` para cobrir múltiplos cenários.
- Ferramentas: `gofmt` para format, `golangci-lint` para lint (config em `golangci.yml`).
