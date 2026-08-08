---
description: Rules framework — formal hierarchy and definition schema.
---

# Rules Framework

## Rule hierarchy (3 tiers)

### Tier 1 — Commandments (🔴 Required)
- **Force**: Block review. A violation is an automatic FAIL.
- **Override**: Impossible. No justification is valid.
- **Example**: "Never hardcode secrets", "Use prepared statements".

### Tier 2 — Edicts (🟡 Expected)
- **Force**: Need a visible justification to be ignored.
- **Override**: Possible WITH a documented justification. Without one, it is a blocker.
- **Example**: "Use environment variables for credentials", "Explicit CORS".

### Tier 3 — Counsel (🔵 Recommended)
- **Force**: Improvement suggestions. NEVER block review.
- **Override**: Free. Informational warnings only.
- **Example**: "Security headers", "Rate limiting".

## Rule schema

### Frontmatter (required)
```yaml
---
paths:
  - "**/*.py"        # activation glob pattern
---
```

### Body (required)
```markdown
# Rule Name

## 🔴 Required (blocks review if violated)
- [tier 1 rules]

## 🟡 Expected (must fix unless justified)
- [tier 2 rules]

## 🔵 Recommended (improvement suggestion)
- [tier 3 rules]
```

## Principles

- **A rule that needs multiple pages is probably a skill.** Rules are short, verifiable constraints.
- **Rules are loaded on demand.** Claude loads them automatically when reading files that match `paths`.
- **Findings must be traceable.** Every review finding MUST point to a documented rule. A finding with no rule behind it is a note (tier 3), never a blocker.

## Existing rules

| Rule | Paths | Focus |
|------|-------|-------|
| `python.md` | `**/*.py` | Type hints, f-strings, pathlib |
| `typescript.md` | `**/*.ts/*.tsx/*.js/*.jsx` | Interface vs type, const, React |
| `go.md` | `**/*.go` | Error handling, interfaces, tests |
| `sql.md` | `**/*.sql` | Uppercase keywords, CTEs, indexes |
| `security.md` | `**/*` | OWASP, sanitization, secrets |
| `testing.md` | Test files | AAA, naming, fixtures |
