#!/usr/bin/env python3
"""Probe nextpnr's chipdb graph for the locked PLL-to-PHASER_REF route."""

from collections import deque


SOURCE_PATTERNS = [
    "PLLE2_ADV_X0Y1/CLKOUT0",
    "CMT_TOP_R_UPPER_T_PLLE2_CLKOUT0",
]
TARGET_PATTERNS = [
    "PHASER_REF_X0Y0/CLKIN",
    "CMT_PHASER_REF_CLKIN",
]
INTERESTING = (
    "PLLE2_CLKOUT0",
    "PLLOUT_CLK_FREQ_BB",
    "PLL_CLK_FREQ",
    "CMT_FREQ_BB_PREF_IN3",
    "CMT_FREQ_PHASER_REFMUX_0",
    "CMT_PHASER_REF_CLKIN",
    "PHASER_REF_X0Y0/CLKIN",
)


def text(obj):
    return str(obj)


def find_wires(patterns):
    found = []
    for wire in ctx.getWires():
        name = text(wire)
        if any(pattern in name for pattern in patterns):
            found.append(wire)
    return found


def describe_wire(wire):
    print("WIRE", text(wire))
    aliases = list(ctx.getWireAliases(wire))
    for alias in aliases[:12]:
        print("  ALIAS", text(alias))
    pins = list(ctx.getWireBelPins(wire))
    for pin in pins[:12]:
        print("  BELPIN", text(pin))
    print("  DOWNHILL")
    for pip in ctx.getPipsDownhill(wire):
        name = text(pip)
        try:
            avail = ctx.checkPipAvail(pip)
        except Exception as exc:
            avail = "<avail-error:{}>".format(exc)
        try:
            dst = ctx.getPipDstWire(pip)
            dst_name = text(dst)
        except Exception as exc:
            dst = None
            dst_name = "<dst-error:{}>".format(exc)
        if any(token in name or token in dst_name for token in INTERESTING):
            print("   ", name, "=>", dst_name, "avail", avail)
    print("  UPHILL")
    for pip in ctx.getPipsUphill(wire):
        name = text(pip)
        try:
            avail = ctx.checkPipAvail(pip)
        except Exception as exc:
            avail = "<avail-error:{}>".format(exc)
        try:
            src = ctx.getPipSrcWire(pip)
            src_name = text(src)
        except Exception as exc:
            src_name = "<src-error:{}>".format(exc)
        if any(token in name or token in src_name for token in INTERESTING):
            print("   ", name, "<=", src_name, "avail", avail)


def bfs(source, targets, limit=200000):
    target_set = {text(wire) for wire in targets}
    queue = deque([source])
    parent = {text(source): (None, None)}
    seen = {text(source)}
    steps = 0
    while queue and steps < limit:
        wire = queue.popleft()
        steps += 1
        wire_name = text(wire)
        if wire_name in target_set:
            path = []
            while parent[wire_name][0] is not None:
                prev, pip = parent[wire_name]
                path.append((prev, pip, wire_name))
                wire_name = prev
            path.reverse()
            return path
        for pip in ctx.getPipsDownhill(wire):
            try:
                if not ctx.checkPipAvail(pip):
                    continue
            except Exception:
                continue
            try:
                dst = ctx.getPipDstWire(pip)
            except Exception:
                continue
            dst_name = text(dst)
            if dst_name in seen:
                continue
            seen.add(dst_name)
            parent[dst_name] = (text(wire), text(pip))
            queue.append(dst)
    return None


sources = find_wires(SOURCE_PATTERNS)
targets = find_wires(TARGET_PATTERNS)
print("SOURCES", len(sources))
for wire in sources:
    describe_wire(wire)
print("TARGETS", len(targets))
for wire in targets:
    describe_wire(wire)

for source in sources:
    path = bfs(source, targets)
    print("BFS_FROM", text(source), "FOUND", bool(path))
    if path:
        for prev, pip, dst in path:
            if any(token in prev or token in pip or token in dst for token in INTERESTING):
                print("  STEP", prev, "--", pip, "->", dst)
        break
