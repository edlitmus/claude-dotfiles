---
paths:
  - "**/*"
---

# Security

## 🔴 Required (blocks review if violated)
- Never hardcode secrets, tokens, passwords, or API keys.
- Sanitize all user input — SQL injection, XSS, command injection.
- Use prepared statements / parameterized queries for SQL.
- Authentication: use bcrypt/argon2 for passwords; never MD5/SHA1.
- HTTPS is mandatory in production.
- Logs: never log sensitive data (passwords, tokens, PII).
- Path traversal: never use `path.normalize()` or `path.join()` alone to validate user-supplied paths. Use `path.resolve()` + a prefix check:
  ```
  const fullPath = path.resolve(baseDir, userInput)
  if (!fullPath.startsWith(baseDir + path.sep)) throw new Error('path traversal')
  ```
- Never trust filenames coming from the client — sanitize special characters and cap the length.

## 🟡 Expected (must fix unless justified)
- Use environment variables or secret managers for credentials.
- Validate and escape output rendered in the frontend.
- CORS: configure the allowed domains explicitly.
- JWT tokens: short expiry + rotating refresh token.
- Dependencies: keep them updated; run `npm audit` / `pip audit` periodically.

## 🔵 Recommended (improvement suggestion)
- Security headers: CSP, HSTS, X-Frame-Options, X-Content-Type-Options.
- Rate limiting on public endpoints.
- Implement a circuit breaker for calls to external services.
