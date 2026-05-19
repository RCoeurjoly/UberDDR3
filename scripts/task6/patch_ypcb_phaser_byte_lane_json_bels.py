#!/usr/bin/env python3
"""Apply YPCB PHASER byte-lane hard-macro BEL locks to a synthesized JSON."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

LOCKS = {
    "phaser_ref_i": "PHASER_REF_X0Y7/PHASER_REF",
    "phy_control_i": "PHY_CONTROL_X0Y7/PHY_CONTROL",
    "phaser_in_i": "PHASER_IN_PHY_X0Y30/PHASER_IN_PHY",
    "phaser_out_i": "PHASER_OUT_PHY_X0Y30/PHASER_OUT_PHY",
    "phaser_pll_i": "PLLE2_ADV_X0Y7/PLLE2_ADV",
}

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("json_path", type=Path)
    args = parser.parse_args()

    data = json.loads(args.json_path.read_text())
    modules = data.get("modules", {})
    module = modules.get("ypcb_phaser_byte_lane_diag")
    if module is None:
        top_modules = [name for name, value in modules.items() if value.get("attributes", {}).get("top") in ("1", 1)]
        if len(top_modules) != 1:
            raise SystemExit(f"could not identify top module; candidates={top_modules!r}")
        module = modules[top_modules[0]]
    cells = module.setdefault("cells", {})
    missing = []
    for cell_name, bel in LOCKS.items():
        cell = cells.get(cell_name)
        if cell is None:
            missing.append(cell_name)
            continue
        cell.setdefault("attributes", {})["BEL"] = bel
    if missing:
        raise SystemExit("missing cells: " + repr(missing))
    args.json_path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
    print(f"{args.json_path}: applied {len(LOCKS)} PHASER BEL locks")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
