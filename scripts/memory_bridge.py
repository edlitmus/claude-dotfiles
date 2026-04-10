#!/usr/bin/env python3
"""
memory_bridge.py — Ponte de memória semântica para Claude Code.

Comandos:
    store   --text "..." --tags "t1,t2" --project "nome"
    query   --text "..." --top-k 8 --project "nome" [--format plain|markdown|json]
    rebuild [--incremental]
    sync
    status
"""

import argparse
import hashlib
import io
import json
import logging
import os
import subprocess
import sys
from datetime import datetime, timezone

# Fix Windows encoding for UTF-8 output
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuração
# ---------------------------------------------------------------------------

MEMORY_DIR = Path.home() / "memory"
EMBEDDINGS_DIR = MEMORY_DIR / ".embeddings"
INDEX_FILE = EMBEDDINGS_DIR / "index.json"
CHROMADB_DIR = EMBEDDINGS_DIR / "chromadb"
LOG_FILE = EMBEDDINGS_DIR / "bridge.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stderr)],
)
log = logging.getLogger("memory_bridge")

# ---------------------------------------------------------------------------
# Backend abstraction
# ---------------------------------------------------------------------------

_backend = None


def _get_backend():
    """Retorna o backend de vetores disponível (ChromaDB ou numpy fallback)."""
    global _backend
    if _backend is not None:
        return _backend

    try:
        import chromadb

        CHROMADB_DIR.mkdir(parents=True, exist_ok=True)
        client = chromadb.PersistentClient(path=str(CHROMADB_DIR))
        _backend = ("chromadb", client)
        return _backend
    except Exception as e:
        log.warning("ChromaDB indisponível (%s) — usando fallback numpy", e)

    _backend = ("numpy", None)
    return _backend


def _get_collection(client):
    """Retorna (ou cria) a collection de memórias no ChromaDB."""
    return client.get_or_create_collection(
        name="memories",
        metadata={"hnsw:space": "cosine"},
    )


# ---------------------------------------------------------------------------
# Numpy fallback helpers
# ---------------------------------------------------------------------------

_np_index = None


def _load_numpy_index():
    """Carrega o índice numpy do disco."""
    global _np_index
    if _np_index is not None:
        return _np_index

    if INDEX_FILE.exists():
        with open(INDEX_FILE, "r", encoding="utf-8") as f:
            _np_index = json.load(f)
    else:
        _np_index = {"entries": [], "version": 1}
    return _np_index


def _save_numpy_index(index):
    """Salva o índice numpy no disco."""
    EMBEDDINGS_DIR.mkdir(parents=True, exist_ok=True)
    with open(INDEX_FILE, "w", encoding="utf-8") as f:
        json.dump(index, f, ensure_ascii=False, indent=2)


def _cosine_similarity(a, b):
    """Similaridade cosseno entre dois vetores (listas Python)."""
    import math

    dot = sum(x * y for x, y in zip(a, b))
    norm_a = math.sqrt(sum(x * x for x in a))
    norm_b = math.sqrt(sum(x * x for x in b))
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return dot / (norm_a * norm_b)


def _simple_embedding(text):
    """Embedding simplificado para fallback numpy — bag of char-trigrams."""
    text = text.lower().strip()
    dim = 384
    vec = [0.0] * dim
    for i in range(len(text) - 2):
        trigram = text[i : i + 3]
        h = int(hashlib.md5(trigram.encode()).hexdigest(), 16) % dim
        vec[h] += 1.0
    # Normaliza
    import math

    norm = math.sqrt(sum(x * x for x in vec))
    if norm > 0:
        vec = [x / norm for x in vec]
    return vec


# ---------------------------------------------------------------------------
# store
# ---------------------------------------------------------------------------


def store_memory(text, tags, project, quiet=False):
    """Armazena uma memória no backend."""
    mem_id = hashlib.sha256(
        f"{text}{datetime.now(timezone.utc).isoformat()}".encode()
    ).hexdigest()[:12]

    timestamp = datetime.now(timezone.utc).isoformat()
    metadata = {
        "tags": tags,
        "project": project,
        "timestamp": timestamp,
        "source": "memory_bridge",
    }

    backend_type, client = _get_backend()

    if backend_type == "chromadb":
        collection = _get_collection(client)
        collection.add(
            documents=[text],
            ids=[mem_id],
            metadatas=[metadata],
        )
    else:
        index = _load_numpy_index()
        embedding = _simple_embedding(text)
        index["entries"].append(
            {
                "id": mem_id,
                "text": text,
                "embedding": embedding,
                "metadata": metadata,
            }
        )
        _save_numpy_index(index)

    # Persiste como arquivo markdown no repo de memória
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
        print(f"✓ Memória armazenada: {mem_id} ({backend_type})")
        log.info("Stored memory %s for project %s [%s]", mem_id, project, backend_type)

    return mem_id


# ---------------------------------------------------------------------------
# query
# ---------------------------------------------------------------------------


def query_memory(text, top_k=8, project=None, fmt="plain"):
    """Busca memórias semanticamente similares."""
    backend_type, client = _get_backend()
    results = []

    if backend_type == "chromadb":
        collection = _get_collection(client)
        count = collection.count()
        if count == 0:
            if fmt == "json":
                print("[]")
            else:
                print("Nenhuma memória indexada.")
            return []

        where = {"project": project} if project else None
        n = min(top_k, count)

        query_result = collection.query(
            query_texts=[text],
            n_results=n,
            where=where,
        )

        for i, doc in enumerate(query_result["documents"][0]):
            meta = query_result["metadatas"][0][i] if query_result["metadatas"] else {}
            dist = query_result["distances"][0][i] if query_result["distances"] else 0
            results.append(
                {
                    "id": query_result["ids"][0][i],
                    "text": doc,
                    "score": round(1.0 - dist, 4),
                    "project": meta.get("project", ""),
                    "tags": meta.get("tags", ""),
                    "timestamp": meta.get("timestamp", ""),
                }
            )
    else:
        index = _load_numpy_index()
        query_emb = _simple_embedding(text)

        scored = []
        for entry in index["entries"]:
            if project and entry["metadata"].get("project") != project:
                continue
            score = _cosine_similarity(query_emb, entry["embedding"])
            scored.append((score, entry))

        scored.sort(key=lambda x: x[0], reverse=True)

        for score, entry in scored[:top_k]:
            results.append(
                {
                    "id": entry["id"],
                    "text": entry["text"],
                    "score": round(score, 4),
                    "project": entry["metadata"].get("project", ""),
                    "tags": entry["metadata"].get("tags", ""),
                    "timestamp": entry["metadata"].get("timestamp", ""),
                }
            )

    # Output
    if fmt == "json":
        print(json.dumps(results, ensure_ascii=False, indent=2))
    elif fmt == "markdown":
        if not results:
            print("Nenhum resultado encontrado.")
        else:
            for r in results:
                print(f"### [{r['score']}] {r['project']} — {r['tags']}")
                print(f"> {r['text'][:200]}")
                print()
    else:  # plain
        if not results:
            print("Nenhum resultado encontrado.")
        else:
            for r in results:
                print(f"[{r['score']}] ({r['project']}) {r['text'][:150]}")

    return results


# ---------------------------------------------------------------------------
# rebuild
# ---------------------------------------------------------------------------


def rebuild_index(incremental=True):
    """Reconstroi o índice de embeddings a partir dos arquivos .md em ~/memory/."""
    backend_type, client = _get_backend()
    stats = {"added": 0, "skipped": 0, "errors": 0}

    if backend_type == "chromadb":
        collection = _get_collection(client)
        existing_ids = set(collection.get()["ids"]) if incremental else set()

        if not incremental:
            try:
                client.delete_collection("memories")
            except Exception:
                pass
            collection = _get_collection(client)

        # Percorre todos os .md em ~/memory/
        for md_file in MEMORY_DIR.rglob("*.md"):
            if ".embeddings" in str(md_file) or md_file.name == "README.md":
                continue

            content = md_file.read_text(encoding="utf-8", errors="replace")
            file_id = hashlib.sha256(str(md_file).encode()).hexdigest()[:12]

            if incremental and file_id in existing_ids:
                stats["skipped"] += 1
                continue

            # Extrai metadados do frontmatter se existir
            project = md_file.parent.name if md_file.parent != MEMORY_DIR else "global"
            tags = ""
            if content.startswith("---"):
                parts = content.split("---", 2)
                if len(parts) >= 3:
                    for line in parts[1].strip().split("\n"):
                        if line.startswith("tags:"):
                            tags = line.split(":", 1)[1].strip()
                        elif line.startswith("project:"):
                            project = line.split(":", 1)[1].strip()
                    content = parts[2].strip()

            try:
                collection.add(
                    documents=[content[:2000]],
                    ids=[file_id],
                    metadatas=[
                        {
                            "project": project,
                            "tags": tags,
                            "source": str(md_file.relative_to(MEMORY_DIR)),
                            "timestamp": datetime.now(timezone.utc).isoformat(),
                        }
                    ],
                )
                stats["added"] += 1
            except Exception as e:
                log.warning("Erro ao indexar %s: %s", md_file, e)
                stats["errors"] += 1
    else:
        # Numpy fallback rebuild
        index = (
            {"entries": [], "version": 1} if not incremental else _load_numpy_index()
        )
        existing_ids = {e["id"] for e in index["entries"]} if incremental else set()

        for md_file in MEMORY_DIR.rglob("*.md"):
            if ".embeddings" in str(md_file) or md_file.name == "README.md":
                continue

            content = md_file.read_text(encoding="utf-8", errors="replace")
            file_id = hashlib.sha256(str(md_file).encode()).hexdigest()[:12]

            if incremental and file_id in existing_ids:
                stats["skipped"] += 1
                continue

            project = md_file.parent.name if md_file.parent != MEMORY_DIR else "global"
            tags = ""
            if content.startswith("---"):
                parts = content.split("---", 2)
                if len(parts) >= 3:
                    for line in parts[1].strip().split("\n"):
                        if line.startswith("tags:"):
                            tags = line.split(":", 1)[1].strip()
                        elif line.startswith("project:"):
                            project = line.split(":", 1)[1].strip()
                    content = parts[2].strip()

            embedding = _simple_embedding(content[:2000])
            index["entries"].append(
                {
                    "id": file_id,
                    "text": content[:2000],
                    "embedding": embedding,
                    "metadata": {
                        "project": project,
                        "tags": tags,
                        "source": str(md_file.relative_to(MEMORY_DIR)),
                        "timestamp": datetime.now(timezone.utc).isoformat(),
                    },
                }
            )
            stats["added"] += 1

        _save_numpy_index(index)

    mode = "incremental" if incremental else "full"
    print(f"✓ Rebuild {mode} concluído ({backend_type})")
    print(f"  Adicionados: {stats['added']}")
    print(f"  Ignorados:   {stats['skipped']}")
    print(f"  Erros:       {stats['errors']}")

    log.info("Rebuild %s: %s", mode, stats)
    return stats


# ---------------------------------------------------------------------------
# sync (com Obsidian)
# ---------------------------------------------------------------------------


def sync_with_obsidian():
    """Sincroniza memórias com vault Obsidian (se configurado)."""
    obsidian_vault = os.environ.get("OBSIDIAN_VAULT")
    if not obsidian_vault:
        # Tenta locais comuns
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
        print("⚠ Vault Obsidian não encontrado.")
        print(
            "  Configure OBSIDIAN_VAULT ou coloque o vault em ~/Documents/Obsidian Vault/"
        )
        return {"synced": 0, "vault": None}

    vault_path = Path(obsidian_vault)
    memory_vault_dir = vault_path / "claude-memory"
    memory_vault_dir.mkdir(parents=True, exist_ok=True)

    stats = {"synced": 0, "vault": str(vault_path)}

    # Copia memórias de projetos para o vault
    projects_dir = MEMORY_DIR / "projects"
    if projects_dir.exists():
        for md_file in projects_dir.rglob("*.md"):
            relative = md_file.relative_to(MEMORY_DIR)
            dest = memory_vault_dir / relative
            dest.parent.mkdir(parents=True, exist_ok=True)

            # Só copia se mais recente
            if not dest.exists() or md_file.stat().st_mtime > dest.stat().st_mtime:
                dest.write_text(md_file.read_text(encoding="utf-8"), encoding="utf-8")
                stats["synced"] += 1

    # Importa notas do vault que tenham tag #claude-memory
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

    print("✓ Sync com Obsidian concluído")
    print(f"  Vault: {vault_path}")
    print(f"  Sincronizados: {stats['synced']}")

    return stats


# ---------------------------------------------------------------------------
# status
# ---------------------------------------------------------------------------


def print_status():
    """Exibe status do sistema de memória."""
    print("=== Memory Bridge Status ===\n")

    # Repositório
    if MEMORY_DIR.exists():
        print(f"✓ Repositório: {MEMORY_DIR}")
        md_count = sum(
            1 for _ in MEMORY_DIR.rglob("*.md") if ".embeddings" not in str(_)
        )
        print(f"  Arquivos .md: {md_count}")
    else:
        print(f"✗ Repositório não encontrado: {MEMORY_DIR}")
        return

    # Backend
    backend_type, client = _get_backend()
    print(f"\n✓ Backend: {backend_type}")

    if backend_type == "chromadb":
        collection = _get_collection(client)
        count = collection.count()
        print(f"  Memórias indexadas: {count}")

        # Tamanho no disco
        if CHROMADB_DIR.exists():
            total = sum(
                f.stat().st_size for f in CHROMADB_DIR.rglob("*") if f.is_file()
            )
            print(f"  Tamanho ChromaDB: {total / 1024:.1f} KB")
    else:
        index = _load_numpy_index()
        print(f"  Memórias indexadas: {len(index.get('entries', []))}")
        if INDEX_FILE.exists():
            print(f"  Tamanho índice: {INDEX_FILE.stat().st_size / 1024:.1f} KB")

    # TurboQuant
    try:
        from turboquant_vectors import compress  # noqa: F401

        print("\n✓ TurboQuant: disponível (turboquant-vectors)")
    except ImportError:
        print("\n⚠ TurboQuant: não disponível")

    # Git status do memory repo
    if (MEMORY_DIR / ".git").exists():
        try:
            result = subprocess.run(
                ["git", "log", "--oneline", "-1"],
                capture_output=True,
                text=True,
                cwd=MEMORY_DIR,
            )
            if result.returncode == 0:
                print(f"\n✓ Último commit: {result.stdout.strip()}")
        except Exception:
            pass

    # Obsidian
    obsidian_vault = os.environ.get("OBSIDIAN_VAULT", "")
    if obsidian_vault and Path(obsidian_vault).exists():
        print(f"\n✓ Obsidian: {obsidian_vault}")
    else:
        print("\n⚠ Obsidian: não configurado")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser(
        description="Memory Bridge — memória semântica para Claude Code"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # store
    p_store = subparsers.add_parser("store", help="Armazena uma memória")
    p_store.add_argument("--text", required=True, help="Texto da memória")
    p_store.add_argument("--tags", default="", help="Tags separadas por vírgula")
    p_store.add_argument("--project", default="global", help="Nome do projeto")
    p_store.add_argument("--quiet", action="store_true", help="Sem output")

    # query
    p_query = subparsers.add_parser("query", help="Busca memórias similares")
    p_query.add_argument("--text", required=True, help="Texto de busca")
    p_query.add_argument("--top-k", type=int, default=8, help="Número de resultados")
    p_query.add_argument("--project", default=None, help="Filtrar por projeto")
    p_query.add_argument(
        "--format", dest="fmt", default="plain", choices=["plain", "markdown", "json"]
    )

    # rebuild
    p_rebuild = subparsers.add_parser("rebuild", help="Reconstroi índice de embeddings")
    p_rebuild.add_argument(
        "--incremental", action="store_true", help="Rebuild incremental"
    )
    p_rebuild.add_argument("--quiet", action="store_true")

    # sync
    subparsers.add_parser("sync", help="Sincroniza com Obsidian")

    # status
    subparsers.add_parser("status", help="Exibe status do sistema")

    args = parser.parse_args()

    # Garante que o diretório de memória existe
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
