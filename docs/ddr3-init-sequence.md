# YPCB DDR3 init sequence and simulation target

This note maps the UberDDR3 reset/init ROM to the failure signatures seen in
YPCB hardware sweeps. It is intentionally practical: the goal is to know what
the controller should be doing when hardware reports an init-family failure, and
to have a simulation target that reaches the same milestone.

## Sequence map

The init sequencer lives in `rtl/ddr3_controller.v`. It uses
`instruction_address` to read a 28-bit ROM instruction from
`read_rom_instruction`. Important instruction bits are:

- `RST_DONE` bit 27: latches `reset_done` when instruction 21 executes.
- `USE_TIMER` bit 26: makes the sequencer wait for the instruction delay.
- `CLOCK_EN` bit 24: drives DDR3 CKE.
- `RESET_N` bit 23: drives DDR3 RESET#.
- `DDR3_CMD` bits 22:19: DDR3 command slot.
- bits 18:0: either delay count or MRS payload.

The expected YPCB sequence is:

| Address | Meaning |
| --- | --- |
| 0 | Hold DDR3 reset active and CKE low. `MICRON_SIM=1` shortens the delay. |
| 1 | Deassert reset while keeping CKE low. |
| 2 | Raise CKE and wait `tXPR`. |
| 3 | Program MR2. |
| 4 | Program MR3 with MPR disabled. |
| 5 | Program MR1 with DLL enabled and write leveling disabled. |
| 6 | Program MR0 and reset the DDR3 DLL. |
| 7 | Wait `tMOD`. |
| 8 | Issue ZQCL and wait `tZQinit`. |
| 9 | Precharge all banks before MPR calibration. |
| 10 | Program MR3 with MPR enabled. |
| 11 | Wait `tMOD`. |
| 12 | Wait `CALIBRATION_DELAY` before read calibration. |
| 13 | Program MR3 with MPR disabled after read calibration starts. |
| 14 | Program MR1 with write leveling enabled. |
| 15 | Wait `tWLMRD`. |
| 16 | Wait `CALIBRATION_DELAY` before write calibration. |
| 17 | Program MR1 with write leveling disabled. |
| 18 | Wait `tMOD`. |
| 19 | Precharge all banks before refresh. |
| 20 | Issue refresh and wait `tRFC`. |
| 21 | Latch `reset_done`; refresh interval starts. |
| 22 | Normal pre-refresh idle delay; calibration/BIST traffic can run. |
| 23..26 | Self-refresh entry/exit path. |

## What the observed init failure means

The hardware init-family failures usually report:

- `instruction_address` stuck around 1 or 2.
- `state_calibrate == 0` (`IDLE`).
- `reset_done == 0`.
- top-level reset released and PHY ready.

`reset_done == 0` is expected before instruction 21. The failure is not that
`reset_done` is false at address 1 or 2; the failure is that the sequencer does
not progress through the ROM far enough to reach calibration.

The first success milestone is therefore not BIST. It is:

- `instruction_address == 13`
- `state_calibrate != IDLE`

At that point the controller has passed the early reset/CKE/MRS/ZQCL path and
has started read calibration.

## Simulation target

The package `ypcb-ddr3-rtl-init-icarus` runs a pure RTL Icarus simulation with
the Micron DDR3 model and `MICRON_SIM=1`.

The testbench:

- instantiates `ddr3_top` with the YPCB 2-byte-lane, 333 MHz DDR3 settings;
- uses `BIST_MODE=0`, because this target only tests the init path to
  calibration entry;
- prints `INIT_TRACE` lines when key init signals change;
- succeeds on `INIT_SUCCESS reached_instruction_13_and_calibration_started`;
- times out on `INIT_TIMEOUT did_not_reach_instruction_13_calibration_start`.

Build command:

```sh
nix build .#ypcb-ddr3-rtl-init-icarus
```

The trace is in:

```text
result/init_trace.log
```

## Reproduction ladder

Use this order when trying to reproduce a hardware init-family failure:

1. Run `ypcb-ddr3-rtl-init-icarus` and confirm the golden RTL trace reaches
   instruction 13.
2. Run seed-specific gate/no-SDF simulation for a hardware failing seed, but do
   not use `+fast_init`; that option bypasses the 0/1/2 init path we need.
3. Run seed-specific SDF simulation if gate/no-SDF does not reproduce.
4. Only after golden traces exist, add fault injection for specific hypotheses:
   stalled `init_advance_now`, delayed `delay_counter_is_zero`, unstable
   `init_advance_pending`, or unstable `i_phy_idelayctrl_rdy`.

If pure RTL reaches instruction 13 while hardware does not, that is evidence
against a simple RTL protocol bug in the early init sequence. It points instead
at post-PNR timing, reset/CDC behavior, primitive modeling, or routing-sensitive
implementation.
