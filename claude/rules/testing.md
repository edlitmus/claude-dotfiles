---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/*_test.*"
  - "**/test_*"
  - "**/tests/**"
  - "**/__tests__/**"
---

# Testes

- Nomeie testes descrevendo comportamento: `should return 404 when user not found`.
- Estrutura AAA: Arrange → Act → Assert.
- Um assert lógico por teste (pode ter múltiplos asserts se validam a mesma coisa).
- Prefira testes de integração sobre mocks para I/O real (DB, HTTP).
- Mocks apenas para dependências externas não-controladas (APIs terceiras).
- Fixtures: use factories/builders em vez de dados hardcoded repetidos.
- Teste edge cases: null, vazio, limites, concorrência.
- Testes devem ser independentes — sem dependência de ordem de execução.
- Testes devem ser rápidos — se demorar, mova para suite de integração.
- Coverage não é métrica de qualidade — cubra comportamentos, não linhas.
