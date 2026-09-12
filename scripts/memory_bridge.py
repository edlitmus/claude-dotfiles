#!/usr/bin/env python3
"""
memory_bridge.py — Semantic memory bridge for Claude Code.

Stores memories as .md files in ~/memory/ and maintains a vector index that is
git-syncable in ~/memory/.embeddings/ (numpy + JSON).

Commands:
    store   --text "..." --tags "t1,t2" --project "name"
    query   --text "..." --top-k 8 --project "name" [--format plain|markdown|json]
    rebuild [--incremental]
    sync
    status
"""

import argparse
import hashlib
import io
import json
import logging
import math
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

# Fix Windows encoding for UTF-8 output
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

MEMORY_DIR = Path.home() / "memory"
EMBEDDINGS_DIR = MEMORY_DIR / ".embeddings"
INDEX_FILE = EMBEDDINGS_DIR / "index.json"
VECTORS_FILE = EMBEDDINGS_DIR / "vectors.npy"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stderr)],
)
log = logging.getLogger("memory_bridge")


class _HFWarningFilter(logging.Filter):
    """Filters out noisy warnings from the HuggingFace Hub."""

    def filter(self, record: logging.LogRecord) -> bool:
        return "unauthenticated requests" not in record.getMessage()


for _h in logging.root.handlers:
    _h.addFilter(_HFWarningFilter())

# Silence noisy dependency logs
for _noisy in (
    "httpx",
    "httpcore",
    "urllib3",
    "sentence_transformers",
    "huggingface_hub",
    "transformers",
    "torch",
    "filelock",
):
    logging.getLogger(_noisy).setLevel(logging.ERROR)

# Suppress HuggingFace warnings and transformers progress bars
os.environ.setdefault("HF_HUB_DISABLE_TELEMETRY", "1")
os.environ.setdefault("HF_HUB_DISABLE_PROGRESS_BARS", "1")
os.environ.setdefault("HF_HUB_DISABLE_IMPLICIT_TOKEN", "1")
os.environ.setdefault("TRANSFORMERS_VERBOSITY", "error")
os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")
import warnings  # noqa: E402

warnings.filterwarnings("ignore", message=".*unauthenticated requests.*")
warnings.filterwarnings("ignore", message=".*UNEXPECTED.*")

EMBEDDING_DIM = 384  # all-MiniLM-L6-v2 dimension

# ---------------------------------------------------------------------------
# Embedding functions (ONNX > char-trigram fallback)
# ---------------------------------------------------------------------------

_embedder = None


def _get_embedder():
    """Returns the embedding function. Tries sentence-transformers, falls back to char-trigram."""
    global _embedder
    if _embedder is not None:
        return _embedder

    # Try sentence-transformers (all-MiniLM-L6-v2, runs locally, no API)
    try:
        # Suppress HuggingFace warnings while importing and loading the model
        _prev_level = logging.root.level
        logging.root.setLevel(logging.ERROR)
        _stderr = sys.stderr
        sys.stderr = io.StringIO()

        from sentence_transformers import SentenceTransformer

        model = SentenceTransformer("all-MiniLM-L6-v2")

        def st_embed(text: str) -> list[float]:
            return model.encode(text).tolist()

        test = st_embed("test")

        sys.stderr = _stderr
        logging.root.setLevel(_prev_level)

        if len(test) == EMBEDDING_DIM:
            _embedder = ("sentence-transformers", st_embed)
            return _embedder
    except Exception as e:
        sys.stderr = _stderr
        logging.root.setLevel(_prev_level)
        log.debug("sentence-transformers unavailable: %s", e)

    # Fallback: char-trigram hashing
    def trigram_embed(text: str) -> list[float]:
        text = text.lower().strip()
        vec = [0.0] * EMBEDDING_DIM
        for i in range(len(text) - 2):
            trigram = text[i : i + 3]
            h = int(hashlib.md5(trigram.encode()).hexdigest(), 16) % EMBEDDING_DIM
            vec[h] += 1.0
        norm = math.sqrt(sum(x * x for x in vec))
        if norm > 0:
            vec = [x / norm for x in vec]
        return vec

    _embedder = ("trigram", trigram_embed)
    return _embedder


def get_embedding(text: str) -> list[float]:
    """Generates an embedding for a text."""
    _, embed_fn = _get_embedder()
    return embed_fn(text)


# ---------------------------------------------------------------------------
# Index management (numpy vectors + JSON metadata)
# ---------------------------------------------------------------------------

_index_cache: dict | None = None
_vectors_cache = None  # numpy array or None


def _load_index() -> dict:
    """Loads the metadata index from disk."""
    global _index_cache
    if _index_cache is not None:
        return _index_cache

    if INDEX_FILE.exists():
        with open(INDEX_FILE, "r", encoding="utf-8") as f:
            _index_cache = json.load(f)
    else:
        _index_cache = {"version": 2, "embedding_model": "unknown", "entries": []}
    return _index_cache


def _load_vectors():
    """Loads the numpy vectors from disk."""
    global _vectors_cache
    if _vectors_cache is not None:
        return _vectors_cache

    try:
        import numpy as np

        if VECTORS_FILE.exists():
            _vectors_cache = np.load(str(VECTORS_FILE))
            return _vectors_cache
    except Exception as e:
        log.warning("Failed to load vectors.npy: %s", e)

    return None


def _save_index(index: dict, vectors) -> None:
    """Saves the index and vectors to disk."""
    global _index_cache, _vectors_cache
    EMBEDDINGS_DIR.mkdir(parents=True, exist_ok=True)

    with open(INDEX_FILE, "w", encoding="utf-8") as f:
        json.dump(index, f, ensure_ascii=False, indent=2)
    _index_cache = index

    if vectors is not None:
        import numpy as np

        np.save(str(VECTORS_FILE), np.array(vectors, dtype=np.float32))
        _vectors_cache = np.array(vectors, dtype=np.float32)


def _append_to_index(entry: dict, embedding: list[float]) -> None:
    """Appends an entry to the index along with its vector."""
    index = _load_index()
    vectors_np = _load_vectors()

    import numpy as np

    emb_array = np.array([embedding], dtype=np.float32)

    if vectors_np is not None and len(vectors_np) > 0:
        vectors_np = np.vstack([vectors_np, emb_array])
    else:
        vectors_np = emb_array

    index["entries"].append(entry)
    model_name, _ = _get_embedder()
    index["embedding_model"] = model_name
    _save_index(index, vectors_np)


# ---------------------------------------------------------------------------
# Search (numpy cosine similarity)
# ---------------------------------------------------------------------------


def _cosine_search(
    query_vec: list[float], top_k: int, project: str | None
) -> list[tuple[int, float]]:
    """Finds the top_k most similar vectors. Returns [(idx, score), ...]."""
    import numpy as np

    vectors = _load_vectors()
    index = _load_index()

    if vectors is None or len(vectors) == 0:
        return []

    q = np.array(query_vec, dtype=np.float32)
    q_norm = np.linalg.norm(q)
    if q_norm == 0:
        return []
    q = q / q_norm

    # Project filter
    if project:
        mask = np.array(
            [e.get("project") == project for e in index["entries"]],
            dtype=bool,
        )
        if not mask.any():
            return []
    else:
        mask = np.ones(len(index["entries"]), dtype=bool)

    # Normalize vectors and compute similarity
    norms = np.linalg.norm(vectors[mask], axis=1, keepdims=True)
    norms = np.where(norms == 0, 1, norms)
    normalized = vectors[mask] / norms
    scores = normalized @ q

    # Map the filtered indices back to global indices
    global_indices = np.where(mask)[0]

    # Top-k
    k = min(top_k, len(scores))
    top_indices = np.argpartition(scores, -k)[-k:]
    top_indices = top_indices[np.argsort(scores[top_indices])[::-1]]

    return [(int(global_indices[i]), float(scores[i])) for i in top_indices]


# ---------------------------------------------------------------------------
# store
# ---------------------------------------------------------------------------


def store_memory(text: str, tags: str, project: str, quiet: bool = False) -> str:
    """Stores a memory in the vector index and as a .md file."""
    mem_id = hashlib.sha256(
        f"{text}{datetime.now(timezone.utc).isoformat()}".encode()
    ).hexdigest()[:12]

    timestamp = datetime.now(timezone.utc).isoformat()

    # Generate the embedding
    embedding = get_embedding(text)

    # Add it to the vector index
    entry = {
        "id": mem_id,
        "text": text[:500],
        "project": project,
        "tags": tags,
        "timestamp": timestamp,
        "source": "memory_bridge",
    }
    _append_to_index(entry, embedding)

    # Persist it as a markdown file in the memory repo
    project_dir = MEMORY_DIR / "projects" / project
    project_dir.mkdir(parents=True, exist_ok=True)

    md_file = project_dir / f"{mem_id}.md"
    md_file.write_text(
        f"---\n"
        f"id: {mem_id}\n"
        f"tags: {tags}\n"
        f"project: {project}\n"
        f"timestamp: {timestamp}\n"
        f"---\n\n"
        f"{text}\n",
        encoding="utf-8",
    )

    if not quiet:
        model_name, _ = _get_embedder()
        print(f"✓ Memory stored: {mem_id} (embeddings: {model_name})")
        log.info("Stored memory %s for project %s", mem_id, project)

    return mem_id


# ---------------------------------------------------------------------------
# query
# ---------------------------------------------------------------------------


def query_memory(
    text: str, top_k: int = 8, project: str | None = None, fmt: str = "plain"
) -> list[dict]:
    """Searches for semantically similar memories."""
    index = _load_index()
    if not index["entries"]:
        if fmt == "json":
            print("[]")
        else:
            print("No memories indexed.")
        return []

    query_vec = get_embedding(text)
    matches = _cosine_search(query_vec, top_k, project)

    results = []
    for idx, score in matches:
        entry = index["entries"][idx]
        results.append(
            {
                "id": entry["id"],
                "text": entry["text"],
                "score": round(score, 4),
                "project": entry.get("project", ""),
                "tags": entry.get("tags", ""),
                "timestamp": entry.get("timestamp", ""),
            }
        )

    # Output
    if fmt == "json":
        print(json.dumps(results, ensure_ascii=False, indent=2))
    elif fmt == "markdown":
        if not results:
            print("No results found.")
        else:
            for r in results:
                print(f"### [{r['score']}] {r['project']} — {r['tags']}")
                print(f"> {r['text'][:200]}")
                print()
    else:  # plain
        if not results:
            print("No results found.")
        else:
            for r in results:
                print(f"[{r['score']}] ({r['project']}) {r['text'][:150]}")

    return results


# ---------------------------------------------------------------------------
# rebuild
# ---------------------------------------------------------------------------


def rebuild_index(incremental: bool = True) -> dict:
    """Rebuilds the embedding index from the .md files in ~/memory/."""
    import numpy as np

    stats = {"added": 0, "skipped": 0, "errors": 0}

    if incremental:
        index = _load_index()
        vectors_np = _load_vectors()
        existing_ids = {e["id"] for e in index["entries"]}
    else:
        index = {"version": 2, "embedding_model": "unknown", "entries": []}
        vectors_np = None
        existing_ids = set()

    new_entries: list[dict] = []
    new_vectors: list[list[float]] = []

    for md_file in MEMORY_DIR.rglob("*.md"):
        if ".embeddings" in str(md_file) or md_file.name == "README.md":
            continue

        content = md_file.read_text(encoding="utf-8", errors="replace")
        file_id = hashlib.sha256(str(md_file).encode()).hexdigest()[:12]

        if file_id in existing_ids:
            stats["skipped"] += 1
            continue

        # Extract metadata from the frontmatter
        project = md_file.parent.name if md_file.parent != MEMORY_DIR else "global"
        tags = ""
        text_content = content
        if content.startswith("---"):
            parts = content.split("---", 2)
            if len(parts) >= 3:
                for line in parts[1].strip().split("\n"):
                    if line.startswith("tags:"):
                        tags = line.split(":", 1)[1].strip()
                    elif line.startswith("project:"):
                        project = line.split(":", 1)[1].strip()
                text_content = parts[2].strip()

        try:
            embedding = get_embedding(text_content[:2000])
            new_entries.append(
                {
                    "id": file_id,
                    "text": text_content[:500],
                    "project": project,
                    "tags": tags,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "source": str(md_file.relative_to(MEMORY_DIR)),
                }
            )
            new_vectors.append(embedding)
            stats["added"] += 1
        except Exception as e:
            log.warning("Failed to index %s: %s", md_file, e)
            stats["errors"] += 1

    # Merge with the existing index
    if new_entries:
        index["entries"].extend(new_entries)
        model_name, _ = _get_embedder()
        index["embedding_model"] = model_name

        new_np = np.array(new_vectors, dtype=np.float32)
        if vectors_np is not None and len(vectors_np) > 0:
            vectors_np = np.vstack([vectors_np, new_np])
        else:
            vectors_np = new_np

    _save_index(index, vectors_np)

    mode = "incremental" if incremental else "full"
    print(f"✓ Rebuild {mode} complete (numpy)")
    print(f"  Added:   {stats['added']}")
    print(f"  Skipped: {stats['skipped']}")
    print(f"  Errors:  {stats['errors']}")

    # Show the size
    if VECTORS_FILE.exists():
        vsize = VECTORS_FILE.stat().st_size
        print(f"  vectors.npy: {vsize / 1024:.1f} KB")

    log.info("Rebuild %s: %s", mode, stats)
    return stats


# ---------------------------------------------------------------------------
# sync (with Obsidian)
# ---------------------------------------------------------------------------


def sync_with_obsidian() -> dict:
    """Syncs memories with the Obsidian vault (if configured)."""
    obsidian_vault = os.environ.get("OBSIDIAN_VAULT")
    if not obsidian_vault:
        candidates = [
            Path.home() / "Documents" / "Obsidian Vault",
            Path.home() / "Obsidian",
            Path.home() / "Documents" / "obsidian",
        ]
        for c in candidates:
            if c.exists():
                obsidian_vault = str(c)
                break

    if not obsidian_vault or not Path(obsidian_vault).exists():
        print("⚠ Obsidian vault not found.")
        print(
            "  Set OBSIDIAN_VAULT or put the vault in ~/Documents/Obsidian Vault/"
        )
        return {"synced": 0, "vault": None}

    vault_path = Path(obsidian_vault)
    memory_vault_dir = vault_path / "claude-memory"
    memory_vault_dir.mkdir(parents=True, exist_ok=True)

    stats = {"synced": 0, "vault": str(vault_path)}

    # Copy project memories into the vault
    projects_dir = MEMORY_DIR / "projects"
    if projects_dir.exists():
        for md_file in projects_dir.rglob("*.md"):
            relative = md_file.relative_to(MEMORY_DIR)
            dest = memory_vault_dir / relative
            dest.parent.mkdir(parents=True, exist_ok=True)

            if not dest.exists() or md_file.stat().st_mtime > dest.stat().st_mtime:
                dest.write_text(md_file.read_text(encoding="utf-8"), encoding="utf-8")
                stats["synced"] += 1

    # Import vault notes tagged #claude-memory
    for md_file in vault_path.rglob("*.md"):
        if "claude-memory" in str(md_file):
            continue
        try:
            content = md_file.read_text(encoding="utf-8", errors="replace")
            if "#claude-memory" in content:
                dest = MEMORY_DIR / "session" / f"obsidian-{md_file.stem}.md"
                if not dest.exists():
                    dest.write_text(content, encoding="utf-8")
                    stats["synced"] += 1
        except Exception:
            continue

    print("✓ Obsidian sync complete")
    print(f"  Vault: {vault_path}")
    print(f"  Synced: {stats['synced']}")

    return stats


# ---------------------------------------------------------------------------
# status
# ---------------------------------------------------------------------------


def print_status() -> None:
    """Prints the memory system status."""
    print("=== Memory Bridge Status ===\n")

    # Repository
    if MEMORY_DIR.exists():
        print(f"✓ Repository: {MEMORY_DIR}")
        md_count = sum(
            1 for _ in MEMORY_DIR.rglob("*.md") if ".embeddings" not in str(_)
        )
        print(f"  .md files: {md_count}")
    else:
        print(f"✗ Repository not found: {MEMORY_DIR}")
        return

    # Index
    index = _load_index()
    n_entries = len(index.get("entries", []))
    model = index.get("embedding_model", "unknown")
    print(f"\n✓ Index: {n_entries} memories (model: {model})")

    if INDEX_FILE.exists():
        print(f"  index.json: {INDEX_FILE.stat().st_size / 1024:.1f} KB")
    if VECTORS_FILE.exists():
        vsize = VECTORS_FILE.stat().st_size
        print(f"  vectors.npy: {vsize / 1024:.1f} KB")

        # TurboQuant compression estimate
        try:
            from turboquant_vectors import compress as tq_compress  # noqa: F401

            print(f"  TurboQuant 4-bit estimate: ~{vsize / 1024 / 4:.1f} KB")
        except ImportError:
            pass

    # Embedder
    embedder_name, _ = _get_embedder()
    print(f"\n✓ Embeddings: {embedder_name}")

    # TurboQuant
    try:
        from turboquant_vectors import compress as tq_compress  # noqa: F401

        print("✓ TurboQuant: available (turboquant-vectors)")
    except ImportError:
        print("⚠ TurboQuant: unavailable")

    # Git status
    if (MEMORY_DIR / ".git").exists():
        try:
            result = subprocess.run(
                ["git", "log", "--oneline", "-1"],
                capture_output=True,
                text=True,
                cwd=MEMORY_DIR,
            )
            if result.returncode == 0:
                print(f"\n✓ Last commit: {result.stdout.strip()}")
        except Exception:
            pass

    # Obsidian
    obsidian_vault = os.environ.get("OBSIDIAN_VAULT", "")
    if obsidian_vault and Path(obsidian_vault).exists():
        print(f"\n✓ Obsidian: {obsidian_vault}")
    else:
        print("\n⚠ Obsidian: not configured")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Memory Bridge — semantic memory for Claude Code"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # store
    p_store = subparsers.add_parser("store", help="Store a memory")
    p_store.add_argument("--text", required=True, help="Memory text")
    p_store.add_argument("--tags", default="", help="Comma-separated tags")
    p_store.add_argument("--project", default="global", help="Project name")
    p_store.add_argument("--quiet", action="store_true", help="No output")

    # query
    p_query = subparsers.add_parser("query", help="Search for similar memories")
    p_query.add_argument("--text", required=True, help="Search text")
    p_query.add_argument("--top-k", type=int, default=8, help="Number of results")
    p_query.add_argument("--project", default=None, help="Filter by project")
    p_query.add_argument(
        "--format", dest="fmt", default="plain", choices=["plain", "markdown", "json"]
    )

    # rebuild
    p_rebuild = subparsers.add_parser("rebuild", help="Rebuild the embedding index")
    p_rebuild.add_argument(
        "--incremental", action="store_true", help="Incremental rebuild"
    )
    p_rebuild.add_argument("--quiet", action="store_true")

    # sync
    subparsers.add_parser("sync", help="Sync with Obsidian")

    # status
    subparsers.add_parser("status", help="Print the system status")

    args = parser.parse_args()

    # Make sure the memory directory exists
    if args.command != "status":
        MEMORY_DIR.mkdir(parents=True, exist_ok=True)
        EMBEDDINGS_DIR.mkdir(parents=True, exist_ok=True)

    if args.command == "store":
        store_memory(args.text, args.tags, args.project, quiet=args.quiet)
    elif args.command == "query":
        query_memory(args.text, args.top_k, args.project, fmt=args.fmt)
    elif args.command == "rebuild":
        rebuild_index(incremental=args.incremental)
    elif args.command == "sync":
        sync_with_obsidian()
    elif args.command == "status":
        print_status()


if __name__ == "__main__":
    main()
