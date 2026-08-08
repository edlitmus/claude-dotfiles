---
paths:
  - "**/*.go"
---

# Go

## 🔴 Required (blocks review if violated)
- Errors: always check them; return an `error` instead of panicking.
- Goroutines: always have a cancellation strategy (`context.Context`).
- Follow idiomatic Go conventions — Effective Go is the reference.
- Interfaces: define them on the consumer side, not the provider side.

## 🟡 Expected (must fix unless justified)
- Naming: short and contextual (`r` for reader, `ctx` for context).
- Structs: exported fields in PascalCase, private ones in camelCase.
- Small interfaces (1-3 methods) — composition over inheritance.
- Channels: prefer directional ones (`chan<-`, `<-chan`) in signatures.
- Use table-driven tests to cover multiple scenarios.

## 🔵 Recommended (improvement suggestion)
- Tooling: `gofmt` for formatting, `golangci-lint` for linting (config in `golangci.yml`).
- Consider `errgroup` for parallel goroutines that can fail.
- Use `sync.Once` for thread-safe lazy initialization.
