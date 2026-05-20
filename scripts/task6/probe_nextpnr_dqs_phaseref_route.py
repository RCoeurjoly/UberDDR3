#!/usr/bin/env python3
"""Probe the exact YPCB lane-0 DQS-to-PHASER_IN_PHY_X0Y1 chipdb chain."""

WIRE_NAMES = (
    "SITEWIRE/IOB_X0Y20/INBUF_EN_OUT",
    "SITEWIRE/IOB_X0Y20/I",
    "LIOB33_X0Y19/IOB_IBUF0",
    "LIOI3_TBYTESRC_X0Y19/LIOI_I0",
    "LIOI3_TBYTESRC_X0Y19/LIOI_ILOGIC0_D",
    "SITEWIRE/ILOGIC_X0Y20/D",
    "SITEWIRE/ILOGIC_X0Y20/O",
    "LIOI3_TBYTESRC_X0Y19/IOI_ILOGIC0_O",
    "INT_L_X0Y19/INT_DQS_IOTOPHASER",
    "INT_R_X1Y19/INT_DQS_IOTOPHASER",
    "IO_INT_INTERFACE_L_X2Y19/L_INT_INTER_DQS_IOTOPHASER",
    "L_TERM_INT_X3Y19/L_TERM_INT_DQS_IOTOPHASER",
    "LIOI3_TBYTESRC_X4Y18/LIOI_I2GCLK_TOP0",
    "CMT_FIFO_R_X7Y20/FIFO_DQS_IOTOPHASER_1",
    "CMT_TOP_R_LOWER_T_X8Y18/CMT_PHASER_DOWN_DQS_TO_PHASER_B",
    "CMT_TOP_R_LOWER_T_X8Y18/CMT_PHASERREF_DOWN_PHASERIN_B",
    "CMT_TOP_R_LOWER_T_X8Y18/CMT_PHASER_IN_DB_PHASEREFCLK",
    "SITEWIRE/PHASER_IN_PHY_X0Y1/PHASEREFCLK",
)


def s(obj):
    return str(obj)


def safe_list(fn):
    try:
        return list(fn())
    except Exception as exc:
        return ["<error:{}>".format(exc)]

wanted = set(WIRE_NAMES)
wires = {}
for wire in ctx.getWires():
    name = s(wire)
    if name in wanted:
        wires[name] = wire

print("FOUND_WIRES", len(wires), "OF", len(WIRE_NAMES))
for name in WIRE_NAMES:
    wire = wires.get(name)
    print("WIRE", name, "FOUND", wire is not None)
    if wire is None:
        continue
    for label, getter in (("DOWN", ctx.getPipsDownhill), ("UP", ctx.getPipsUphill)):
        pips = safe_list(lambda getter=getter, wire=wire: getter(wire))
        print("  {}_COUNT {}".format(label, len(pips)))
        for pip in pips[:40]:
            print("  {} {}".format(label, s(pip)))
