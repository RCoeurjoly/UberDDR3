LOCKS = {
    "phaser_ref_i": "PHASER_REF_X0Y0/PHASER_REF",
    "phaser_pll_i": "PLLE2_ADV_X0Y1/PLLE2_ADV",
}

missing = []
for cell, bel in LOCKS.items():
    if cell not in ctx.cells:
        missing.append(cell)
        continue
    ctx.cells[cell].setAttr("BEL", bel)

if missing:
    raise RuntimeError("YPCB PHASER_REF diag pre-place missing cells: " + repr(missing))

print("YPCB PHASER_REF diag pre-place: applied {} locks".format(len(LOCKS)))
