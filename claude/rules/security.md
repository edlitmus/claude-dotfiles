---
paths:
  - "**/*"
---

# Segurança

- Nunca faça hardcode de secrets, tokens, senhas ou chaves de API.
- Use variáveis de ambiente ou secret managers para credenciais.
- Sanitize todo input de usuário — SQL injection, XSS, command injection.
- Use prepared statements / parameterized queries para SQL.
- Valide e escape output renderizado no frontend.
- CORS: configure explicitamente os domínios permitidos.
- Autenticação: use bcrypt/argon2 para senhas; nunca MD5/SHA1.
- Tokens JWT: prazo de expiração curto + refresh token rotativo.
- HTTPS obrigatório em produção.
- Dependências: mantenha atualizadas; rode `npm audit` / `pip audit` periodicamente.
- Logs: nunca logue dados sensíveis (senhas, tokens, PII).
