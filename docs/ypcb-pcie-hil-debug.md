# YPCB HIL debug architecture

UberDDR3/YPCB should use two debug planes:

- JTAG/BSCAN: minimal rescue/status and programming path.
- PCIe BAR MMIO: primary high-bandwidth trace and scope readout path.

UART is intentionally not part of the YPCB debug architecture. The board
reference exposes PCIe SMBus pins, but those are not a safe general-purpose
UART debug link when the board is used through the PCIe edge connector.

## JTAG rescue plane

Keep the existing USER1 BSCAN payload as the always-available status plane. It
is useful when PCIe does not enumerate or the host cannot read BAR0.

The JTAG payload should remain limited to:

- build/variant marker
- clock/reset health
- DDR init/calibration/BIST state
- sticky failure family
- trace frozen/available flags

USER2 trace readout may remain as a small fallback, but it should not be the
main trace transport.

## PCIe data plane

The PCIe data plane should terminate BAR0 AXI-Lite accesses in a debug CSR and
scope block. In the local `/home/roland/pcie_7x` reference, the replacement
point is the `axil_minimum` instance in:

```text
/home/roland/pcie_7x/src/aximm-minimal/pcie_7x_top_aximm.v
```

Replace that test memory with `ypcb_debug_axi_lite`, or instantiate an
equivalent AXI-Lite-native debug fabric.

The intended BAR0 map is:

```text
0x0000  global magic/version/status
0x0100  JTAG-equivalent status/control mirror
0x0010  128-bit synchronized status snapshot
0x4000  PCIe/link/user scope bank

DDR-domain trace banks should be added behind a dual-clock RAM or explicit
snapshot handshake before being exposed through BAR0.
```

Scope banks use the common `ypcb_debug_wb_scope` register map:

```text
0x00  magic
0x04  status/control
0x08  read index
0x0c  selected sample low 32 bits
0x10  selected sample high 32 bits
0x14  live sample low 32 bits
0x18  live sample high 32 bits
```

## CDC rule

Do not expose live multi-bit debug signals directly across clock domains.
Capture signals in their native clock domain, freeze/snapshot the captured
state, then read it through a bus-facing interface.

The current `ypcb_debug_axi_lite` is a first integration scaffold for global
status plus a PCIe-clock scope. DDR-controller trace banks must be connected
through a real dual-clock RAM or request/ack snapshot before BAR0 readout; do
not cross live DDR debug buses directly into the PCIe clock domain.

## HIL flow

The hardware sweep should:

1. Program the bitstream via JTAG.
2. Read the minimal JTAG status.
3. If PCIe enumerates, dump all BAR0 scope banks.
4. If PCIe does not enumerate, record only the JTAG rescue status.
5. Store the result as JSON/CSV with seed, repeat, variant, coarse family, and
   exact family.

This keeps instrumentation stable while allowing broad seed sweeps and detailed
per-family analysis.
