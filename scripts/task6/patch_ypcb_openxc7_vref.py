#!/usr/bin/env python3

from __future__ import annotations

import argparse
import os
import re
import shlex
import subprocess


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
YPCB_VREF_FEATURES = os.path.join(ROOT, "example_demo", "ypcb_00338_1p1", "ypcb_vref.features")


def read_vref_features(path: str = YPCB_VREF_FEATURES) -> tuple[list[str], set[str]]:
    with open(path, encoding="utf-8") as handle:
        features = [line.strip() for line in handle if line.strip() and not line.lstrip().startswith("#")]
    sites = {feature.split(".", 1)[0] for feature in features}
    return features, sites


def patch_openxc7_vref_fasm(gateware_dir: str) -> dict[str, object]:
    fasm_path = os.path.join(gateware_dir, "ypcb_00338_1p1.fasm")
    features, sites = read_vref_features()
    with open(fasm_path, encoding="utf-8") as handle:
        original = handle.read().splitlines()

    vref_re = re.compile(r"^(" + "|".join(re.escape(site) for site in sorted(sites)) + r")\.VREF\.V_")
    patched = [line for line in original if not vref_re.match(line)]
    removed = len(original) - len(patched)
    present = set(patched)
    added = 0
    for feature in features:
        if feature not in present:
            patched.append(feature)
            added += 1

    if patched != original:
        with open(fasm_path, "w", encoding="utf-8") as handle:
            handle.write("\n".join(patched) + "\n")
    return {"fasm": fasm_path, "removed": removed, "added": added, "features": features}


def build_script_lines(gateware_dir: str) -> list[str]:
    script_path = os.path.join(gateware_dir, "build_ypcb_00338_1p1.sh")
    with open(script_path, encoding="utf-8") as handle:
        return [line.strip() for line in handle if line.strip() and not line.lstrip().startswith("#")]


def regenerate_openxc7_bitstream_from_fasm(gateware_dir: str) -> dict[str, str]:
    lines = build_script_lines(gateware_dir)
    fasm2frames = next(line for line in lines if line.startswith("fasm2frames "))
    xc7frames2bit = next(line for line in lines if line.startswith("xc7frames2bit "))

    fasm_command, frames_name = fasm2frames.split(">", 1)
    frames_path = os.path.join(gateware_dir, frames_name.strip())
    with open(frames_path, "w", encoding="utf-8") as frames:
        subprocess.run(shlex.split(fasm_command), cwd=gateware_dir, check=True, stdout=frames)
    subprocess.run(shlex.split(xc7frames2bit), cwd=gateware_dir, check=True)
    return {"frames": frames_path, "bitstream": os.path.join(gateware_dir, "ypcb_00338_1p1.bit")}


def patch_openxc7_vref_bitstream(output_dir: str) -> dict[str, object]:
    gateware_dir = os.path.join(output_dir, "gateware")
    patch = patch_openxc7_vref_fasm(gateware_dir)
    regen = regenerate_openxc7_bitstream_from_fasm(gateware_dir)
    return {**patch, **regen}


def main() -> int:
    parser = argparse.ArgumentParser(description="Patch YPCB 0.750 VREF features into an OpenXC7 LiteDRAM bitstream.")
    parser.add_argument("output_dir", help="LiteX/LiteDRAM build output directory containing gateware/")
    args = parser.parse_args()
    result = patch_openxc7_vref_bitstream(args.output_dir)
    print(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
