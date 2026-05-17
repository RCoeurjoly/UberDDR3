#!/usr/bin/env python3
"""Compare the YPCB LiteDRAM pin map against the exported Vivado/MIG oracle."""

from __future__ import annotations

import argparse
import ast
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path


def load_litedram_pins(path: Path, channel: int) -> dict[str, object]:
    tree = ast.parse(path.read_text())
    for node in tree.body:
        if isinstance(node, ast.Assign):
            for target in node.targets:
                if isinstance(target, ast.Name) and target.id == "YPCB_DDRAM_PINS":
                    pins = ast.literal_eval(node.value)
                    return pins[channel]
    raise RuntimeError(f"YPCB_DDRAM_PINS not found in {path}")


def load_mig_pins(path: Path, controller: int) -> dict[str, str]:
    root = ET.parse(path).getroot()
    for controller_node in root.findall("Controller"):
        if int(controller_node.attrib["number"]) != controller:
            continue
        pin_selection = controller_node.find("PinSelection")
        if pin_selection is None:
            raise RuntimeError(f"Controller {controller} has no PinSelection")
        return {
            pin.attrib["name"]: pin.attrib["PADName"]
            for pin in pin_selection.findall("Pin")
            if "name" in pin.attrib and "PADName" in pin.attrib
        }
    raise RuntimeError(f"Controller {controller} not found in {path}")


def flatten_litedram_pins(pins: dict[str, object]) -> dict[str, str]:
    flat: dict[str, str] = {}
    for index, pad in enumerate(str(pins["a"]).split()):
        flat[f"ddr3_addr[{index}]"] = pad
    for index, pad in enumerate(str(pins["ba"]).split()):
        flat[f"ddr3_ba[{index}]"] = pad
    for signal in ("ras_n", "cas_n", "we_n", "reset_n"):
        flat[f"ddr3_{signal}"] = str(pins[signal])
    for signal in ("cs_n", "cke", "odt"):
        flat[f"ddr3_{signal}[0]"] = str(pins[signal])
    flat["ddr3_ck_p[0]"] = str(pins["clk_p"])
    flat["ddr3_ck_n[0]"] = str(pins["clk_n"])

    dq_groups = pins["dq"]
    for group_index, group in enumerate(dq_groups):
        for bit_index, pad in enumerate(str(group).split()):
            flat[f"ddr3_dq[{group_index * 8 + bit_index}]"] = pad
    for index, pad in enumerate(str(pins["dqs_p"]).split()):
        flat[f"ddr3_dqs_p[{index}]"] = pad
    for index, pad in enumerate(str(pins["dqs_n"]).split()):
        flat[f"ddr3_dqs_n[{index}]"] = pad
    return flat


def parse_xdc_properties(path: Path) -> dict[str, dict[str, str]]:
    properties: dict[str, dict[str, str]] = {}
    pattern = re.compile(r"set_property\s+(\S+)\s+(\S+)\s+\[get_ports\s+(?:\{([^}]+)\}|([^\]]+))\s*\]")
    for line in path.read_text(errors="replace").splitlines():
        match = pattern.search(line)
        if not match:
            continue
        prop, value, braced_port, plain_port = match.groups()
        port = braced_port if braced_port is not None else plain_port
        properties.setdefault(port.strip(), {})[prop] = value
    return properties


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--channel", type=int, default=0)
    parser.add_argument(
        "--litedram-source",
        type=Path,
        default=Path("scripts/task6/ypcb_litedram_bist.py"),
    )
    parser.add_argument(
        "--mig-prj",
        type=Path,
        default=Path("artifacts/task6/vivado-oracle/ypcb-systest/mig.prj"),
    )
    parser.add_argument(
        "--mig-xdc",
        type=Path,
        default=Path("artifacts/task6/vivado-oracle/ypcb-systest/top_mig_7series_0_0.xdc"),
    )
    parser.add_argument("--byte-groups", default="0,1,2,3")
    args = parser.parse_args()

    byte_groups = [int(item, 0) for item in args.byte_groups.split(",") if item.strip()]
    litedram_pins = flatten_litedram_pins(load_litedram_pins(args.litedram_source, args.channel))
    mig_pins = load_mig_pins(args.mig_prj, args.channel)
    xdc_props = parse_xdc_properties(args.mig_xdc)

    names = sorted(set(litedram_pins) | set(mig_pins))
    mismatches = [
        {
            "name": name,
            "litedram": litedram_pins.get(name),
            "mig": mig_pins.get(name),
        }
        for name in names
        if litedram_pins.get(name) != mig_pins.get(name)
    ]

    selected_names = []
    for name in names:
        dq_match = re.fullmatch(r"ddr3_dq\[(\d+)\]", name)
        dqs_match = re.fullmatch(r"ddr3_dqs_[pn]\[(\d+)\]", name)
        if dq_match and int(dq_match.group(1)) // 8 in byte_groups:
            selected_names.append(name)
        elif dqs_match and int(dqs_match.group(1)) in byte_groups:
            selected_names.append(name)
        elif not (dq_match or dqs_match):
            selected_names.append(name)

    selected_mismatches = [item for item in mismatches if item["name"] in selected_names]
    selected_mig_terms = {
        name: xdc_props.get(f"c{args.channel}_{name}", {}).get("IN_TERM")
        for name in selected_names
        if re.fullmatch(r"ddr3_(dq|dqs_[pn])\[\d+\]", name)
    }

    result = {
        "channel": args.channel,
        "byte_groups": byte_groups,
        "litedram_pin_count": len(litedram_pins),
        "mig_pin_count": len(mig_pins),
        "mismatch_count": len(mismatches),
        "selected_mismatch_count": len(selected_mismatches),
        "selected_mismatches": selected_mismatches,
        "selected_mig_in_terms": dict(sorted(selected_mig_terms.items())),
        "pass": not selected_mismatches,
    }
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
