#!/usr/bin/env python3
"""Generate scoped/type BEL-lock variants for nextpnr matrix sweeps."""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path
from typing import Any


def load_lock_payload(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict) or "locks" not in payload:
        raise ValueError(f"missing locks array in {path}")
    return payload


def normalize_lock(record: dict[str, Any], source: str) -> dict[str, str]:
    return {
        "cell": str(record["cell"]),
        "bel": str(record["bel"]),
        "type": str(record.get("type", "")),
        "scope": str(record.get("scope", "")),
        "source_file": source,
    }


def summarize_locks(locks: list[dict[str, str]]) -> dict[str, Any]:
    return {
        "lock_count": len(locks),
        "type_counts": dict(sorted(Counter(lock["type"] for lock in locks if lock["type"]).items())),
        "scope_counts": dict(sorted(Counter(lock["scope"] for lock in locks if lock["scope"]).items())),
    }


def write_variant(path: Path, source_files: list[str], locks: list[dict[str, str]], label: str) -> None:
    summary = summarize_locks(locks)
    payload = {
        "format": "task6.nextpnr-ddr3-soft-bel-locks.v1",
        "generated": datetime.now().astimezone().isoformat(),
        "label": label,
        "source_files": sorted(source_files),
        "lock_count": summary["lock_count"],
        "type_counts": summary["type_counts"],
        "scope_counts": summary["scope_counts"],
        "locks": locks,
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def sanitize_label(value: str) -> str:
    safe = "".join(ch if ch.isalnum() or ch == "_" else "_" for ch in value.lower())
    while "__" in safe:
        safe = safe.replace("__", "_")
    return safe.strip("_")


def variant_by_scopes(all_locks: list[dict[str, str]], source_files: list[str], out_dir: Path) -> list[tuple[str, Path]]:
    variants: list[tuple[str, Path]] = []
    for scope in sorted({lock["scope"] for lock in all_locks if lock["scope"]}):
        filtered = [lock for lock in all_locks if lock["scope"] == scope]
        label = f"scope-{sanitize_label(scope)}"
        out = out_dir / f"{label}.json"
        write_variant(out, source_files, filtered, label)
        variants.append((label, out))
    return variants


def variant_by_types(all_locks: list[dict[str, str]], source_files: list[str], out_dir: Path) -> list[tuple[str, Path]]:
    variants: list[tuple[str, Path]] = []
    for cell_type in sorted({lock["type"] for lock in all_locks if lock["type"]}):
        filtered = [lock for lock in all_locks if lock["type"] == cell_type]
        label = f"type-{sanitize_label(cell_type)}"
        out = out_dir / f"{label}.json"
        write_variant(out, source_files, filtered, label)
        variants.append((label, out))
    return variants


def variant_by_scope_type(
    all_locks: list[dict[str, str]], source_files: list[str], out_dir: Path
) -> list[tuple[str, Path]]:
    grouped = defaultdict(list)
    for lock in all_locks:
        grouped[(lock["scope"], lock["type"])].append(lock)
    variants: list[tuple[str, Path]] = []
    for scope, cell_type in sorted(grouped):
        filtered = grouped[(scope, cell_type)]
        label = f"scope-{sanitize_label(scope)}_type-{sanitize_label(cell_type)}"
        out = out_dir / f"{label}.json"
        write_variant(out, source_files, filtered, label)
        variants.append((label, out))
    return variants


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--locks-json",
        action="append",
        required=True,
        type=Path,
        help="Input BEL-lock JSON (repeatable).",
    )
    parser.add_argument("--out-dir", type=Path, required=True, help="Directory for generated variants.")
    parser.add_argument(
        "--split-by-scope",
        action="store_true",
        help="Generate one variant per scope.",
    )
    parser.add_argument(
        "--split-by-type",
        action="store_true",
        help="Generate one variant per BEL type.",
    )
    parser.add_argument(
        "--split-by-scope-type",
        action="store_true",
        help="Generate one variant per scope+type pair.",
    )
    parser.add_argument(
        "--only",
        action="append",
        default=[],
        help="Optional label prefix filter, repeatable (e.g. --only scope-ddr3_controller_soft).",
    )
    parser.add_argument(
        "--include-type",
        action="append",
        default=[],
        help="Keep only these BEL types before writing variants. Repeatable.",
    )
    parser.add_argument(
        "--exclude-type",
        action="append",
        default=[],
        help="Drop these BEL types before writing variants. Repeatable.",
    )
    parser.add_argument(
        "--include-scope",
        action="append",
        default=[],
        help="Keep only these lock scopes before writing variants. Repeatable.",
    )
    parser.add_argument(
        "--exclude-scope",
        action="append",
        default=[],
        help="Drop these lock scopes before writing variants. Repeatable.",
    )
    parser.add_argument(
        "--include-cell",
        action="append",
        default=[],
        help="Keep only these exact cell names before writing variants. Repeatable.",
    )
    parser.add_argument(
        "--exclude-cell",
        action="append",
        default=[],
        help="Drop these exact cell names before writing variants. Repeatable.",
    )
    args = parser.parse_args()

    source_files = [str(path) for path in args.locks_json]
    all_locks: list[dict[str, str]] = []
    for path in args.locks_json:
        payload = load_lock_payload(path)
        for lock in payload.get("locks", []):
            all_locks.append(normalize_lock(lock, str(path)))

    all_locks = sorted(
        {
            (lock["cell"], lock["bel"], lock["type"], lock["scope"]): lock
            for lock in all_locks
        }.values(),
        key=lambda lock: (lock["scope"], lock["type"], lock["cell"]),
    )
    include_types = set(args.include_type)
    exclude_types = set(args.exclude_type)
    include_scopes = set(args.include_scope)
    exclude_scopes = set(args.exclude_scope)
    include_cells = set(args.include_cell)
    exclude_cells = set(args.exclude_cell)
    all_locks = [
        lock
        for lock in all_locks
        if (not include_types or lock["type"] in include_types)
        and lock["type"] not in exclude_types
        and (not include_scopes or lock["scope"] in include_scopes)
        and lock["scope"] not in exclude_scopes
        and (not include_cells or lock["cell"] in include_cells)
        and lock["cell"] not in exclude_cells
    ]

    args.out_dir.mkdir(parents=True, exist_ok=True)
    full_label = "full"
    full_path = args.out_dir / f"{full_label}.json"
    write_variant(full_path, source_files, list(all_locks), full_label)

    variants: list[tuple[str, Path]] = [(full_label, full_path)]
    if args.split_by_scope:
        variants.extend(variant_by_scopes(list(all_locks), source_files, args.out_dir))
    if args.split_by_type:
        variants.extend(variant_by_types(list(all_locks), source_files, args.out_dir))
    if args.split_by_scope_type:
        variants.extend(variant_by_scope_type(list(all_locks), source_files, args.out_dir))

    filtered = variants
    if args.only:
        wanted = set(args.only)
        filtered = [item for item in variants if item[0] in wanted]
    manifest = {
        "generated": datetime.now().astimezone().isoformat(),
        "source_files": source_files,
        "count": len(filtered),
        "variants": [
            {"label": label, "path": str(path)} for label, path in sorted(filtered, key=lambda v: v[0])
        ],
    }

    manifest_path = args.out_dir / "task6-lock-variants.json"
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"wrote {len(filtered)} variants to {manifest_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
