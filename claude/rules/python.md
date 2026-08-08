---
paths:
  - "**/*.py"
---

# Python

## 🔴 Required (blocks review if violated)
- Use type hints on every function signature.
- Specific exceptions — never a bare `except Exception` without re-raising.
- Use `dataclasses` or `pydantic` for data structures, not nested dicts.
- Organized imports: stdlib → third-party → local (ruff/isort handles this).

## 🟡 Expected (must fix unless justified)
- Prefer f-strings over `.format()` or `%`.
- Use `pathlib.Path` instead of `os.path` for path manipulation.
- Google-style docstrings (`Args:`, `Returns:`, `Raises:`).
- Use context managers (`with`) for I/O.
- Prefer list/dict comprehensions when readable; avoid nested comprehensions.

## 🔵 Recommended (improvement suggestion)
- Tooling: `ruff` for lint + format (config in `ruff.toml`).
- Consider `__slots__` on high-frequency dataclasses.
- Use `functools.lru_cache` for pure functions called repeatedly.
