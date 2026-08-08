---
paths:
  - "**/*.sql"
---

# SQL

## 🔴 Required (blocks review if violated)
- Avoid `SELECT *` — list the columns explicitly.
- Migrations: always reversible (up + down).
- Use prepared statements / parameterized queries — never concatenation.
- Name your constraints (`CONSTRAINT pk_users_id PRIMARY KEY`).

## 🟡 Expected (must fix unless justified)
- Keywords in UPPERCASE (`SELECT`, `FROM`, `WHERE`).
- One column per line in queries with more than 3 columns.
- Use CTEs (`WITH`) instead of nested subqueries for readability.
- Always qualify columns with a table alias in JOINs.
- Prefer explicit `JOIN` over implicit joins in the `WHERE` clause.
- Indexing: every frequent `WHERE`, `JOIN ON`, and `ORDER BY` needs an index.

## 🔵 Recommended (improvement suggestion)
- 4-space indentation.
- Tooling: `sqlfluff` with dialect auto-detection (config in `.sqlfluff`).
- Consider partitioning for tables over 10M rows with range queries.
