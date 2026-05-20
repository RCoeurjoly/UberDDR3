#!/usr/bin/env python3
"""Summarize CMT_FIFO route keys required by OpenXC7 and seen in Vivado."""

from __future__ import annotations

import argparse
from collections import Counter
import json
import re
from pathlib import Path


OPEN_FASM_RE = re.compile(r"^(CMT_FIFO_R_X\d+Y\d+)\.([A-Za-z0-9_]+)\.([A-Za-z0-9_]+)$")
VIVADO_PIP_RE = re.compile(
    r"^\s*PIP\s+(CMT_FIFO_R_X\d+Y\d+)/CMT_FIFO_R\.([A-Za-z0-9_]+)->([A-Za-z0-9_]+)$"
)


def route_class(src: str, dst: str) -> str:
    text = f"{src} {dst}"
    if "CLK" in text:
        return "clock"
    if "RESET" in text or "RDEN" in text or "WREN" in text:
        return "control"
    if "_D" in text:
        return "data"
    if "EMPTY" in text or "FULL" in text or "LOGIC_OUTS" in text:
        return "status"
    return "other"


def segment_key(src: str, dst: str) -> str:
    return f"CMT_FIFO_R.{dst}.{src}"


def parse_open_fasm(path: Path) -> dict[str, dict[str, object]]:
    routes: dict[str, dict[str, object]] = {}
    for line_no, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw_line.split("#", 1)[0].strip()
        if not line:
            continue
        feature = line.split(None, 1)[0]
        match = OPEN_FASM_RE.match(feature)
        if not match:
            continue
        tile, dst, src = match.groups()
        key = segment_key(src, dst)
        routes[key] = {
            "key": key,
            "tile": tile,
            "src": src,
            "dst": dst,
            "class": route_class(src, dst),
            "line": line_no,
            "feature": feature,
        }
    return routes


def parse_vivado_routes(path: Path) -> dict[str, dict[str, object]]:
    routes: dict[str, dict[str, object]] = {}
    for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        match = VIVADO_PIP_RE.match(line)
        if not match:
            continue
        tile, src, dst = match.groups()
        key = segment_key(src, dst)
        item = routes.setdefault(
            key,
            {
                "key": key,
                "src": src,
                "dst": dst,
                "class": route_class(src, dst),
                "occurrences": 0,
                "example_tiles": [],
                "example_lines": [],
            },
        )
        item["occurrences"] = int(item["occurrences"]) + 1
        if len(item["example_tiles"]) < 8 and tile not in item["example_tiles"]:
            item["example_tiles"].append(tile)
        if len(item["example_lines"]) < 8:
            item["example_lines"].append(line_no)
    return routes


def write_json(path: Path, payload: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def write_markdown(path: Path, payload: dict[str, object]) -> None:
    lines = [
        "# CMT_FIFO Route Coverage",
        "",
        "## Summary",
        "",
    ]
    for key, value in payload["summary"].items():
        lines.append(f"- `{key}`: `{value}`")
    lines.extend(["", "## OpenXC7 Required Routes By Class", ""])
    for row in payload["open_required_by_class"]:
        lines.append(
            f"- `{row['class']}`: `{row['total']}` required, "
            f"`{row['vivado_backed']}` Vivado-backed, `{row['not_seen_in_vivado']}` not seen"
        )
    lines.extend(["", "## Required Routes Not Seen In Vivado Dump", ""])
    missing = payload["open_required_not_seen_in_vivado"]
    if missing:
        for item in missing:
            lines.append(f"- `{item['class']}` `{item['key']}` from `{item['feature']}`")
    else:
        lines.append("All OpenXC7-required CMT_FIFO route keys were observed in the Vivado route dump.")
    lines.extend(["", "## Vivado-Backed OpenXC7 Required Routes", ""])
    for item in payload["open_required_seen_in_vivado"]:
        lines.append(
            f"- `{item['class']}` `{item['key']}` "
            f"(Open line {item['line']}, Vivado occurrences {item['vivado_occurrences']})"
        )
    lines.extend(["", "## Notes", ""])
    lines.append(
        "- This compares normalized route keys only: `CMT_FIFO_R.<dst>.<src>`. "
        "Tile names are intentionally removed so a lane-A Vivado route can back "
        "the same tile-type route required by the reduced OpenXC7 FIFO diagnostic."
    )
    lines.append(
        "- A Vivado-backed route key is not a segbit row. Frame bits still need "
        "a reduced bitstream-delta oracle before adding database rows."
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--open-fasm", type=Path, required=True)
    parser.add_argument("--vivado-routes", type=Path, required=True)
    parser.add_argument("--json-out", type=Path, required=True)
    parser.add_argument("--md-out", type=Path, required=True)
    args = parser.parse_args()

    open_routes = parse_open_fasm(args.open_fasm)
    vivado_routes = parse_vivado_routes(args.vivado_routes)
    seen = []
    not_seen = []
    class_counts: Counter[tuple[str, bool]] = Counter()
    for key in sorted(open_routes):
        item = dict(open_routes[key])
        vivado_item = vivado_routes.get(key)
        if vivado_item:
            item["vivado_occurrences"] = vivado_item["occurrences"]
            item["vivado_example_tiles"] = vivado_item["example_tiles"]
            item["vivado_example_lines"] = vivado_item["example_lines"]
            seen.append(item)
            class_counts[(str(item["class"]), True)] += 1
        else:
            not_seen.append(item)
            class_counts[(str(item["class"]), False)] += 1

    classes = sorted({item["class"] for item in open_routes.values()})
    by_class = []
    for name in classes:
        backed = class_counts[(str(name), True)]
        missing = class_counts[(str(name), False)]
        by_class.append(
            {
                "class": name,
                "total": backed + missing,
                "vivado_backed": backed,
                "not_seen_in_vivado": missing,
            }
        )

    payload: dict[str, object] = {
        "inputs": {
            "open_fasm": str(args.open_fasm),
            "vivado_routes": str(args.vivado_routes),
        },
        "summary": {
            "open_required_cmt_fifo_routes": len(open_routes),
            "vivado_cmt_fifo_route_keys": len(vivado_routes),
            "open_required_seen_in_vivado": len(seen),
            "open_required_not_seen_in_vivado": len(not_seen),
        },
        "open_required_by_class": by_class,
        "open_required_seen_in_vivado": seen,
        "open_required_not_seen_in_vivado": not_seen,
    }
    write_json(args.json_out, payload)
    write_markdown(args.md_out, payload)
    print(f"wrote {args.json_out}")
    print(f"wrote {args.md_out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
