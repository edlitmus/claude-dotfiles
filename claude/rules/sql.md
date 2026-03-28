---
paths:
  - "**/*.sql"
---

# SQL

- Keywords em UPPERCASE (`SELECT`, `FROM`, `WHERE`).
- Indentação de 4 espaços.
- Uma coluna por linha em queries com mais de 3 colunas.
- Use CTEs (`WITH`) em vez de subqueries aninhadas para legibilidade.
- Sempre qualifique colunas com alias de tabela em JOINs.
- Prefira `JOIN` explícito sobre joins implícitos no `WHERE`.
- Indexação: todo `WHERE`, `JOIN ON` e `ORDER BY` frequente deve ter índice.
- Migrations: sempre reversíveis (up + down).
- Evite `SELECT *` — liste as colunas explicitamente.
- Nomeie constraints (`CONSTRAINT pk_users_id PRIMARY KEY`).
- Ferramentas: `sqlfluff` com auto-detecção de dialeto (config em `.sqlfluff`).
