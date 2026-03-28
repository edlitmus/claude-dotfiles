---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---

# TypeScript / JavaScript

- Prefira TypeScript sobre JavaScript sempre que o projeto suportar.
- Use `interface` para contratos públicos; `type` para unions/intersections.
- Evite `any` — use `unknown` e faça narrowing, ou genéricos.
- Use `const` por padrão; `let` quando reatribuição for necessária; nunca `var`.
- Async/await sobre `.then()` chains — exceto em composição funcional.
- Desestruturação moderada — se precisar de mais de 4 campos, extraia um tipo.
- Imports com caminho absoluto (aliases `@/`) quando o projeto tiver configurado.
- React: componentes funcionais + hooks; evite `useEffect` para lógica de negócio.
- React: prefira server components (Next.js App Router) quando aplicável.
- Ferramentas: `eslint` + `prettier` (configs no projeto, não globais).
