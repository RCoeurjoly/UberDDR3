# Channel-0, phy-group-2, byte-lane A placements from the Vivado MIG oracle.
# Runs under nextpnr-xilinx --pre-place after packing and before placement.

LOCKS = {
    "phaser_ref_i": "PHASER_REF_X0Y0/PHASER_REF",
    "phy_control_i": "PHY_CONTROL_X0Y0/PHY_CONTROL",
    "phaser_in_i": "PHASER_IN_PHY_X0Y0/PHASER_IN_PHY",
    "phaser_out_i": "PHASER_OUT_PHY_X0Y0/PHASER_OUT_PHY",
    "in_fifo_i": "IN_FIFO_X0Y0/IN_FIFO",
    "out_fifo_i": "OUT_FIFO_X0Y0/OUT_FIFO",
}

OPTIONAL_LOCKS = {
    "phaser_pll_i": "PLLE2_ADV_X0Y1/PLLE2_ADV",
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
    raise RuntimeError("YPCB PHASER byte-lane diag pre-place missing cells: " + repr(missing))

for cell_name, bel in OPTIONAL_LOCKS.items():
    if cell_name in ctx.cells:
        ctx.cells[cell_name].setAttr("BEL", bel)
        applied += 1

print("YPCB PHASER byte-lane diag pre-place: applied {} locks".format(applied))
