# Technical Analysis: TurboQuant

**Date:** 2026-04-10
**Status:** Decided — use it only for sync/export, not as primary storage
**Packages tested:** `turboquant-py` v0.1.0, `turboquant-vectors` v0.3.0

---

## Packages tested

### turboquant-py v0.1.0

Installs without error, but fails on import:

```
ModuleNotFoundError: No module named 'turboquant_py'
```

The package is published under the name `turboquant-py` on PyPI, but its internal module uses a different name. There is no clear documentation on the correct import name. **Discarded.**

### turboquant-vectors v0.3.0

Installs and imports correctly. This is the package used in the benchmarks below.

---

## Benchmark: turboquant-vectors

Test configuration: 100 vectors, 1536 dimensions, 4-bit quantization.

### Memory and compression results

| Metric | Value | Note |
|---|---|---|
| `compression_ratio` | 0.065 | Means 6.5% of the original size in packed form |
| `original_bytes` | 614,400 (600 KB) | 100 × 1536 dims × 4 bytes (float32) |
| `packed_memory_bytes` | 77,200 (75.4 KB) | ~8x compression in packed form |
| `memory_bytes` (in-process) | 9,514,448 (~9 MB) | Larger because it includes the codebook, rotation, and indices |
| Manual serialization (indices + codebook + norms) | 154,064 bytes (~150 KB) | ~4x compression vs the original |

The gap between `packed_memory_bytes` (~75 KB) and `memory_bytes` (~9 MB) exists because the in-memory object carries auxiliary structures: a float32[16] codebook, a rotation matrix, and per-vector norms. The packed size represents only the compressed uint8 indices.

### Speed results

| Operation | Time (100 vectors, 1536 dims) |
|---|---|
| Compression (fit + transform) | ~5,500 ms |
| Search (query) | ~3,630 ms |

These times are **slow** for 100 vectors. For context, ChromaDB completes a search over similar collections in tens of milliseconds. The slowness suggests pure-Python overhead or the absence of SIMD optimization — not investigated further because the use case changed.

### Problem on Windows: `.save()` is broken

```python
index.save("./tq_test.bin")
# Runs without error, but the file is not created
```

The `.save()` method silences the write error on Windows. There is no exception and no file. That rules out the native `.save()` for persistence. Manual serialization worked:

```python
np.savez("tq_test.bin", 
    indices=index.indices,      # uint8
    codebook=index.codebook,    # float32[16]
    norms=index.norms           # float32[N]
)
```

The `tq_test.bin.npz` file at the repository root is the artifact from this test.

---

## Dimension mismatch with our stack

Our memory stack uses ChromaDB with the `all-MiniLM-L6-v2` model — **384 dimensions**. The TurboQuant benchmark was run with 1536 dims (the typical size of OpenAI `text-embedding-ada-002` embeddings).

TurboQuant works with any dimension, but the cost/benefit changes. At 384 dims the compression overhead is smaller in absolute terms, and ChromaDB's speed is already adequate for our expected collections (< 100k vectors).

---

## Usage decision

**ChromaDB is primary.** It handles storage, search, and persistence. There is no reason to add a compression layer on the critical search path.

**turboquant-vectors as an optional sync/export layer.** The only justifiable use case is compressing ChromaDB index snapshots for transfer between machines (e.g. syncing compressed snapshots via git). In that scenario:

1. Export vectors from ChromaDB → serialize with TurboQuant → commit the `.npz` snapshot
2. On a new machine → load the `.npz` → rebuild the ChromaDB collection

This shrinks the snapshot by ~4x to ~8x, depending on the serialization method used.

### Complete fallback flow

```
ChromaDB (primary)
  ↓ installation or runtime failure
numpy cosine similarity + manual .npz (fallback)
  ↓ needs syncing between machines
turboquant-vectors compressed into .npz (optional, for export)
```

---

## Internal structure of the TurboQuant index

For future reference when implementing manual serialization:

| Attribute | Type | Description |
|---|---|---|
| `indices` | `uint8[N, M]` | Quantized indices of the vectors |
| `codebook` | `float32[16]` | Codebook centroids (PQ) |
| `norms` | `float32[N]` | L2 norm of each original vector |
| `rotation` | `float32[D, D]` | Pre-applied random rotation matrix |

Approximately reconstructing an original vector goes through: dequantize via the codebook → apply the inverse rotation → rescale by the norm.

---

## Test artifact

The `/tq_test.bin.npz` file at the repository root is the output of the manual benchmark. It contains the indices, codebook, and norms of the 100 test vectors (1536 dims, 4-bit). It can be used to validate serialization in other environments.

---

## References

- `turboquant-vectors` v0.3.0: https://pypi.org/project/turboquant-vectors/
- `turboquant-py` v0.1.0: discarded (broken import)
- ChromaDB: https://docs.trychroma.com/
- all-MiniLM-L6-v2: 384 dims, Apache 2.0, via sentence-transformers
