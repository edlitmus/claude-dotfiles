# Technical Analysis: mempalace (v3.1.0)

**Date:** 2026-04-10
**Status:** Decided — use ChromaDB directly (no mempalace)
**Repository:** github.com/milla-jovovich/mempalace v3.1.0

---

## What it is

mempalace is a memory system for AI agents that uses ChromaDB as its vector backend. It organizes content in a hierarchical structure inspired by the method of loci (a memorization technique): palaces > wings > halls > rooms. Each "room" stores one indexed semantic fragment.

The project reports 96.6% recall@5 on the LongMemEval benchmark — a relevant number for evaluating long-term memory systems.

---

## Exposed interface

### CLI

```bash
mempalace init            # initializes a local palace (~/.mempalace/)
mempalace mine            # extracts and indexes conversations/documents
mempalace search <query>  # semantic search in the palace
```

### Python API

```python
# layers.py
from mempalace.layers import search
results = search(query="JWT authentication", top_k=5)

# knowledge_graph.py
from mempalace.knowledge_graph import add_entity, query_entity
add_entity(name="ruah", type="tool", description="worktree orchestrator")
query_entity(name="ruah")
```

### MCP server

mempalace includes a built-in MCP server, which would allow direct integration with Claude Code without a subprocess. This was an initial point of interest.

### Embeddings

Uses `all-MiniLM-L6-v2` via ONNX locally — no external API call. Dimension: 384. Suitable for offline use and environments without internet access.

---

## Installation problem on Windows

```
pip install mempalace
```

Fails while compiling `chroma-hnswlib`, a transitive dependency of the ChromaDB used internally by mempalace:

```
error: Microsoft Visual C++ 14.0 or greater is required.
Get it with "Microsoft C++ Build Tools"
```

`chroma-hnswlib` is a C++ extension that must be compiled. On Windows it requires the MSVC toolchain to be installed, which is not a reasonable assumption in the target environment.

**Contrast:** `pip install chromadb` works because ChromaDB ships pre-compiled binary wheels for Windows (Python 3.14 x64). mempalace pins a specific ChromaDB version that has no wheel available for our Python/OS combination.

---

## Decision: use ChromaDB directly

mempalace's "palace" structure is conceptually a useful abstraction, but it adds an unnecessary layer of complexity for our use case. What we need is:

1. Persistent vector storage
2. Semantic similarity search
3. Metadata filtering (project, date, type)
4. Local embeddings (no API)

ChromaDB delivers all four natively.

### What we gain by using ChromaDB directly

| Capability | ChromaDB directly | via mempalace |
|---|---|---|
| Installation on Windows | Works (binary wheel) | Fails (compiles C++) |
| Local embeddings | all-MiniLM-L6-v2 (built-in) | Same model via mempalace |
| Semantic search | `collection.query()` | `search()` |
| Metadata filtering | `where={"project": "dotfiles"}` | Equivalent |
| Persistence | `PersistentClient(path)` | Automatic |
| Control over the collection | Full | Abstracted away |

### What we lose

- The organizational metaphor (palace/wings/halls/rooms) — we will not use it
- The built-in MCP server — we can use ChromaDB via a subprocess or build our own wrapper
- `mempalace mine` for automatic conversation extraction — replaceable by our own script

---

## Fallback strategy

If ChromaDB also causes problems (future incompatibility, a wheel regression), we have a fallback that is implementable with numpy:

```python
import numpy as np

def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))

def search_top_k(query_vec, stored_vecs, stored_metas, k=5):
    scores = [cosine_similarity(query_vec, v) for v in stored_vecs]
    top_indices = np.argsort(scores)[-k:][::-1]
    return [(stored_metas[i], scores[i]) for i in top_indices]
```

No external dependencies. No compilation. Works in any Python >= 3.9 environment.

The downsides are speed (an O(n) linear scan) and the lack of native persistence — the vectors would have to be saved manually to `.npz` or similar.

---

## Implementation path

```
~/.dotfiles-memory/
  chroma/          ← ChromaDB PersistentClient lives here
    chroma.sqlite3
    <uuid>/
```

Collections to create:

| Collection | Content | Key metadata |
|---|---|---|
| `conversations` | Summaries of agent sessions | `date`, `project`, `agent` |
| `decisions` | Technical decisions (like this file) | `date`, `topic`, `verdict` |
| `code_context` | Codebase snippets and patterns | `file`, `language`, `project` |

---

## References

- ChromaDB docs: https://docs.trychroma.com/
- Embedding model: `all-MiniLM-L6-v2` (384 dims, Apache 2.0)
- mempalace repo: github.com/milla-jovovich/mempalace
- LongMemEval benchmark: the metric used to evaluate long-term memory recall
