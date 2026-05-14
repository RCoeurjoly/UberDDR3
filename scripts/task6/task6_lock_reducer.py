#!/usr/bin/env python3
"""Generate reduction candidates from a passing BEL-lock oracle."""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from datetime import datetime
import json
from pathlib import Path
from typing import Any


HIGH_RISK_TYPES = {
    "BSCAN",
    "BUFGCTRL",
    "IDELAYCTRL_IDELAYCTRL",
    "IDELAYE2_IDELAYE2",
    "INVERTER",
    "IOB33M_INBUF_EN",
    "IOB33M_OUTBUF",
    "IOB33S_OUTBUF",
    "IOB33_INBUF_EN",
    "IOB33_OUTBUF",
    "ISERDESE2_ISERDESE2",
    "OSERDESE2_OSERDESE2",
    "PAD",
    "PLLE2_ADV_PLLE2_ADV",
}


def load_locks(path: Path) -> list[dict[str, str]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    locks = []
    for lock in payload["locks"]:
        locks.append({
            "cell": str(lock["cell"]),
            "bel": str(lock["bel"]),
            "type": str(lock.get("type", "")),
            "scope": str(lock.get("scope", "")),
        })
    return sorted(locks, key=lambda lock: (lock["scope"], lock["type"], lock["cell"]))


def sanitize(value: str) -> str:
    out = "".join(ch if ch.isalnum() else "_" for ch in value.lower()).strip("_")
    while "__" in out:
        out = out.replace("__", "_")
    return out or "empty"


def category(lock: dict[str, str]) -> str:
    name = lock["cell"].lower()
    cell_type = lock["type"]
    if cell_type in HIGH_RISK_TYPES:
        return "clock_io_phy_primitives"
    if "ddr3_phy" in name:
        return "ddr3_phy_soft_logic"
    if "ddr3_controller" in name:
        return "ddr3_controller_soft_logic"
    if "uberddr3" in name:
        return "uberddr3_other_soft_logic"
    if "jtag_" in name:
        return "jtag_soft_logic"
    return "other_soft_logic"


def group_key(lock: dict[str, str], mode: str) -> str:
    if mode == "category":
        return category(lock)
    if mode == "type":
        return f"type:{lock['type']}"
    if mode == "scope":
        return f"scope:{lock['scope']}"
    if mode == "category-type":
        return f"{category(lock)}__type:{lock['type']}"
    raise ValueError(mode)


def summarize(locks: list[dict[str, str]]) -> dict[str, Any]:
    return {
        "lock_count": len(locks),
        "category_counts": dict(sorted(Counter(category(lock) for lock in locks).items())),
        "type_counts": dict(sorted(Counter(lock["type"] for lock in locks).items())),
        "scope_counts": dict(sorted(Counter(lock["scope"] for lock in locks).items())),
    }


def write_locks(
    path: Path,
    *,
    source: Path,
    label: str,
    locks: list[dict[str, str]],
    removed: list[dict[str, str]],
) -> None:
    payload = {
        "format": "task6.nextpnr-lock-reduction-candidate.v1",
        "generated": datetime.now().astimezone().isoformat(),
        "label": label,
        "source_locks_json": str(source),
        "removed_summary": summarize(removed),
        "summary": summarize(locks),
        "locks": locks,
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def generate_complements(args: argparse.Namespace) -> dict[str, Any]:
    locks = load_locks(args.locks_json)
    groups: dict[str, list[dict[str, str]]] = defaultdict(list)
    for lock in locks:
        groups[group_key(lock, args.group_by)].append(lock)

    args.out_dir.mkdir(parents=True, exist_ok=True)
    manifest = {
        "generated": datetime.now().astimezone().isoformat(),
        "source_locks_json": str(args.locks_json),
        "group_by": args.group_by,
        "baseline": summarize(locks),
        "variants": [],
    }
    for group, removed in sorted(groups.items(), key=lambda item: (-len(item[1]), item[0])):
        kept = [lock for lock in locks if group_key(lock, args.group_by) != group]
        label = f"without-{sanitize(group)}"
        path = args.out_dir / f"{label}.json"
        write_locks(path, source=args.locks_json, label=label, locks=kept, removed=removed)
        manifest["variants"].append({
            "label": label,
            "path": str(path),
            "kept": len(kept),
            "removed": len(removed),
            "removed_group": group,
        })

    manifest_path = args.out_dir / "task6-lock-reduction-manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return manifest


def generate_addbacks(args: argparse.Namespace) -> dict[str, Any]:
    if args.base_without_category is None:
        raise SystemExit("--mode addback requires --base-without-category")

    locks = load_locks(args.locks_json)
    required_groups = set(args.addback_required_group)
    base = [
        lock
        for lock in locks
        if category(lock) != args.base_without_category
        or group_key(lock, args.group_by) in required_groups
    ]
    removed = [lock for lock in locks if category(lock) == args.base_without_category]
    candidates = [lock for lock in removed if group_key(lock, args.group_by) not in required_groups]
    required = [lock for lock in removed if group_key(lock, args.group_by) in required_groups]
    groups: dict[str, list[dict[str, str]]] = defaultdict(list)
    for lock in candidates:
        groups[group_key(lock, args.group_by)].append(lock)

    args.out_dir.mkdir(parents=True, exist_ok=True)
    manifest = {
        "generated": datetime.now().astimezone().isoformat(),
        "source_locks_json": str(args.locks_json),
        "mode": "addback",
        "base_without_category": args.base_without_category,
        "base": summarize(base),
        "removed_pool": summarize(removed),
        "required_addback_groups": sorted(required_groups),
        "required_addback": summarize(required),
        "group_by": args.group_by,
        "variants": [],
    }
    if required:
        label = "base-without-" + sanitize(args.base_without_category)
        for group in sorted(required_groups):
            label += "_with-" + sanitize(group)
        path = args.out_dir / f"{label}.json"
        write_locks(path, source=args.locks_json, label=label, locks=base, removed=candidates)
        manifest["variants"].append({
            "label": label,
            "path": str(path),
            "kept": len(base),
            "addback": len(required),
            "addback_group": ",".join(sorted(required_groups)),
        })
    for group, addback in sorted(groups.items(), key=lambda item: (-len(item[1]), item[0])):
        candidate = sorted(
            base + addback,
            key=lambda lock: (lock["scope"], lock["type"], lock["cell"]),
        )
        label = f"base-without-{sanitize(args.base_without_category)}"
        for required_group in sorted(required_groups):
            label += f"_with-{sanitize(required_group)}"
        label += f"_add-{sanitize(group)}"
        path = args.out_dir / f"{label}.json"
        write_locks(path, source=args.locks_json, label=label, locks=candidate, removed=removed)
        manifest["variants"].append({
            "label": label,
            "path": str(path),
            "kept": len(candidate),
            "addback": len(addback),
            "addback_group": group,
        })

    manifest_path = args.out_dir / "task6-lock-addback-manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--locks-json", required=True, type=Path)
    parser.add_argument("--out-dir", required=True, type=Path)
    parser.add_argument(
        "--mode",
        choices=("complement", "addback"),
        default="complement",
    )
    parser.add_argument(
        "--base-without-category",
        help="For addback mode, start from oracle minus this category and add groups back.",
    )
    parser.add_argument(
        "--addback-required-group",
        action="append",
        default=[],
        help="For addback mode, always include this group key in the base before adding one more group.",
    )
    parser.add_argument(
        "--group-by",
        choices=("category", "category-type", "scope", "type"),
        default="category",
    )
    args = parser.parse_args()

    manifest = generate_addbacks(args) if args.mode == "addback" else generate_complements(args)
    print(json.dumps({
        "group_by": manifest["group_by"],
        "variant_count": len(manifest["variants"]),
        "largest_variants": manifest["variants"][:8],
    }, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
