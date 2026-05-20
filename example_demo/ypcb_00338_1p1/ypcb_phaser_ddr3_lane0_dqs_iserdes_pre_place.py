# YPCB physical DDR3 lane-0 DQS placement.
# The DQS pin is IOB_X0Y20 in the bottom-left IO/CMT region. Its dedicated
# tileconn path reaches the DB/B-side PHASER_IN, so this proof must use
# PHASER_IN_PHY_X0Y1 rather than the regenerated SYSTEST lane-A X0Y8 placement.

LOCKS = {
    "phaser_ref_i": "PHASER_REF_X0Y0/PHASER_REF",
    "phy_control_i": "PHY_CONTROL_X0Y0/PHY_CONTROL",
    "phaser_in_i": "PHASER_IN_PHY_X0Y1/PHASER_IN_PHY",
    "phaser_out_i": "PHASER_OUT_PHY_X0Y0/PHASER_OUT_PHY",
}

OPTIONAL_LOCKS = {
    "phaser_pll_i": "PLLE2_ADV_X0Y1/PLLE2_ADV",
    "in_fifo_i": "IN_FIFO_X0Y0/IN_FIFO",
    "out_fifo_i": "OUT_FIFO_X0Y0/OUT_FIFO",
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
    raise RuntimeError("YPCB PHASER DDR3 lane-0 DQS pre-place missing cells: " + repr(missing))

for cell_name, bel in OPTIONAL_LOCKS.items():
    if cell_name in ctx.cells:
        ctx.cells[cell_name].setAttr("BEL", bel)
        applied += 1

print("YPCB PHASER DDR3 lane-0 DQS pre-place: applied {} locks".format(applied))
