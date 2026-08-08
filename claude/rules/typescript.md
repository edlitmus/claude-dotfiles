---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---

# TypeScript / JavaScript

## 🔴 Required (blocks review if violated)
- Avoid `any` — use `unknown` and narrow, or use generics.
- Use `const` by default; `let` when reassignment is needed; never `var`.
- Prefer TypeScript over JavaScript whenever the project supports it.
- React: function components + hooks; avoid `useEffect` for business logic.

## 🟡 Expected (must fix unless justified)
- Use `interface` for public contracts; `type` for unions/intersections.
- Async/await over `.then()` chains — except in functional composition.
- Destructure in moderation — if you need more than 4 fields, extract a type.
- Absolute import paths (`@/` aliases) when the project has them configured.
- React: prefer server components (Next.js App Router) where applicable.

## 🔵 Recommended (improvement suggestion)
- Tooling: `eslint` + `prettier` (project configs, not global ones).
- Use `satisfies` for type validation without widening.
- Prefer `Map`/`Set` over objects when keys are dynamic.
