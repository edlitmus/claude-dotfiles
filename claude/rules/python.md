---
paths:
  - "**/*.py"
---

# Python

- Use type hints em todas as assinaturas de função.
- Prefira f-strings sobre `.format()` ou `%`.
- Use `pathlib.Path` em vez de `os.path` para manipulação de caminhos.
- Docstrings no padrão Google (`Args:`, `Returns:`, `Raises:`).
- Imports organizados: stdlib → third-party → local (o ruff/isort cuida disso).
- Use context managers (`with`) para I/O.
- Prefira list/dict comprehensions quando legíveis; evite comprehensions aninhadas.
- Use `dataclasses` ou `pydantic` para estruturas de dados, não dicts aninhados.
- Exceções específicas — nunca `except Exception` genérico sem re-raise.
- Ferramentas: `ruff` para lint+format (config em `ruff.toml`).
