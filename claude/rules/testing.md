---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/*_test.*"
  - "**/test_*"
  - "**/tests/**"
  - "**/__tests__/**"
---

# Tests

## 🔴 Required (blocks review if violated)
- Name tests after the behavior: `should return 404 when user not found`.
- Tests must be independent — no dependency on execution order.
- AAA structure: Arrange → Act → Assert.
- Mocks only for uncontrolled external dependencies (third-party APIs).

## 🟡 Expected (must fix unless justified)
- One logical assert per test (multiple asserts are fine if they validate the same thing).
- Prefer integration tests over mocks for real I/O (DB, HTTP).
- Test edge cases: null, empty, boundaries, concurrency.
- Fixtures: use factories/builders instead of repeated hardcoded data.

## 🔵 Recommended (improvement suggestion)
- Tests should be fast — if one is slow, move it to the integration suite.
- Coverage is not a quality metric — cover behaviors, not lines.
- Consider property-based testing for functions with a large input domain.
