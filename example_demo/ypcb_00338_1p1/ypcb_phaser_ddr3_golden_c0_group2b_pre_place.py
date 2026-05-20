# YPCB Vivado golden DDR3 c0.group2.B placement tuple.
#
# Extracted from:
#   artifacts/task6/vivado-golden/ypcb-00338-1p1-systest-2026-05-16/
#     reverse-engineering/golden-hardmacro-summary.json
#
# This keeps the lane-0 DQS PHASEREF path on PHASER_IN_PHY_X0Y1, but aligns
# PHASER_OUT and optional FIFO instances to the same complete golden byte lane.

LOCKS = {
    "phaser_ref_i": "PHASER_REF_X0Y0/PHASER_REF",
    "phy_control_i": "PHY_CONTROL_X0Y0/PHY_CONTROL",
    "phaser_in_i": "PHASER_IN_PHY_X0Y1/PHASER_IN_PHY",
    "phaser_out_i": "PHASER_OUT_PHY_X0Y1/PHASER_OUT_PHY",
}

OPTIONAL_LOCKS = {
    "phaser_pll_i": "PLLE2_ADV_X0Y1/PLLE2_ADV",
    "in_fifo_i": "IN_FIFO_X0Y1/IN_FIFO",
    "out_fifo_i": "OUT_FIFO_X0Y1/OUT_FIFO",
}

missing = []
applied = 0
for cell_name, bel in LOCKS.items():
    if cell_name not in ctx.cells:
        missing.append(cell_name)
        continue
    ctx.cells[cell_name].setAttr("BEL", bel)
    applied += 1

if missing:
    raise RuntimeError(
        "YPCB PHASER DDR3 golden c0.group2.B pre-place missing cells: "
        + repr(missing)
    )

for cell_name, bel in OPTIONAL_LOCKS.items():
    if cell_name in ctx.cells:
        ctx.cells[cell_name].setAttr("BEL", bel)
        applied += 1

print("YPCB PHASER DDR3 golden c0.group2.B pre-place: applied {} locks".format(applied))
