# YPCB DDR3 Frozen Shell Strategy

## Goal

Make DDR3 development deterministic enough to continue from a known-good
hardware-calibrating design while new functionality is added around it.

The open nextpnr-xilinx flow does not currently provide a Vivado-style routed
checkpoint that can be reopened, preserved, and incrementally routed around.
The practical substitute is a frozen DDR3 shell:

1. preserve a known-good synthesized DDR3/JTAG rowstream design artifact,
2. extract BEL locks from the routed JSON that calibrated on hardware,
3. keep the DDR3 shell interface stable,
4. add new RTL outside that boundary,
5. apply shell locks during PNR,
6. hardware-test calibration and rowstream read/write after every change.

## Clock Discipline

The RTL PLL and nextpnr timing constraints must describe the same clocks.

For the AMD/Xilinx Kintex-7 DDR3 external-memory-interface guidance, the DDR3
memory clock must be at least 400 MHz so the Phaser block is used in 1:1 mode.
The exact-400 MHz experiment was built and tested as a clean baseline, but it
failed before calibration started. Because the AMD/Xilinx note permits 400 MHz
or higher, the frozen shell uses the known hardware-passing 500 MHz operating
point:

| Clock | Frequency | Period |
| --- | ---: | ---: |
| `ddr3_clk` | 500 MHz | 2 ns |
| `ddr3_clk_90` | 500 MHz | 2 ns |
| `controller_clk` | 125 MHz | 8 ns |
| `ref_clk` | 200 MHz | 5 ns |

With the 50 MHz board clock, the frozen-shell PLL is:

| PLL output | Divide | Frequency |
| --- | ---: | ---: |
| VCO | `50 MHz * 20` | 1000 MHz |
| `CLKOUT0` | 2 | 500 MHz |
| `CLKOUT1` | 2 | 500 MHz, 90 deg |
| `CLKOUT2` | 8 | 125 MHz |
| `CLKOUT3` | 5 | 200 MHz |

Any build whose RTL PLL and `addClock` constraints disagree is not a valid
timing experiment.

## Frozen Boundary

The initial shell boundary is the current rowstream top:

`task6_ypcb_uberddr3_bist_rowstream_loader_top`

It contains:

- PLL and BUFGs,
- `ddr3_top` / UberDDR3 PHY and controller,
- the boot/readback probe,
- JTAG command and debug scan chains,
- the low-byte and dense-byte rowstream command interface.

The external, stable development interface is the rowstream command protocol:

| Opcode | Meaning |
| ---: | --- |
| `0x03` | write one low byte |
| `0x04` | read one low byte |
| `0x05` | write one dense byte into a 512-bit beat |
| `0x06` | read one dense 512-bit beat |

New test and application logic should first talk to DDR3 through this command
surface. Only after this path is stable should we split out a wider local bus.

The currently preserved passing shell exposes the old 512-bit JTAG debug scan.
That scan includes a 128-bit readback window at debug bit 336, so it can
hardware-validate dense byte lanes 0 through 15 without regenerating the DDR3
shell. A later frozen-shell revision must expose either four selectable
128-bit chunks or the full 512-bit beat before the full 64-byte readback
contract can be accepted.

Rowstream USER2 commands must be sent with `--command-repeats 2`. The loader
accepts every other command event; using one repeat can make alternating
write/read commands look like data-lane failures.

The preserved-shell dense-byte experiment showed that one-hot byte writes are
not a sound contract for this YPCB configuration. With repeated commands and
calibration passing, lanes 0, 2, 3, 4, 6, 7, 8, 10, 11, 12, 14, and 15 in the
first 128-bit window can read back correctly, but lanes 1, 5, 9, and 13 remain
at the existing pattern bytes. This matches the earlier no-DM board evidence:
partial byte-write masking cannot be the foundation for 64-byte correctness.

The 2026-05-14 hardware run confirmed the same conclusion on the preserved
seed-3 v44 artifact:

- `write-lowbyte` followed by `read-lowbyte` still reaches `DONE_CALIBRATE` and
  round-trips the low byte.
- dense-byte `memtest64` now uses the correct legacy dense-read opcode `0x06`;
  the command gate passes and `ack_count` advances, but the 64-byte data compare
  fails because one-hot byte writes are not a valid no-DM memory contract.
- fresh v64 fullbeat RTL builds, both loader-only and BIST-shell variants, fail
  before calibration even with `--timing-allow-fail`. The failure happens before
  any host fullbeat command is issued, so this is a placement/timing/calibration
  perturbation from the fresh RTL shape, not a fullbeat command semantics
  failure.

The minimal v45 fullbeat rowstream shell implements the intended command
contract directly in the historically calibrating v44 top:

| Opcode | Meaning |
| ---: | --- |
| `0x01` | stage one 128-bit write chunk; chunk 3 commits all 64 byte lanes |
| `0x02` | read one complete 512-bit beat |
| `0x03` | legacy low-byte write |
| `0x04` | legacy low-byte read |
| `0x05` | diagnostic dense-byte write |
| `0x06` | diagnostic dense-beat read |

The hardware implementation is intentionally full-beat only at commit time:
`LOADER_OP_WRITE_CHUNK` updates a 512-bit staging register for chunks 0..3 and
only chunk 3 issues the Wishbone write with `loader_sel_q = {WB_SEL_BITS{1'b1}}`.
This is the correct YPCB memory contract because it does not rely on absent or
unproven DDR3 DM byte masks.

However, the v45 shell is not yet a usable hardware base. A PNR-only sweep from
one v45 synth JSON, with the 411-lock v40 physical pre-place constraints and
`--timing-allow-fail`, failed calibration for all historically useful seeds:

| Seed | Version | Calibration State | `ack_count` | Result |
| ---: | ---: | --- | ---: | --- |
| 0 | 45 | `IDLE` | 0 | fail before command gate |
| 3 | 45 | `IDLE` | 0 | fail before command gate |
| 16 | 45 | `IDLE` | 0 | fail before command gate |
| 40 | 45 | `IDLE` | 0 | fail before command gate |
| 44 | 45 | `IDLE` | 0 | fail before command gate |

The control test immediately after the sweep reprogrammed the preserved v44
artifact and reached `DONE_CALIBRATE` with `calibration=pass` and `ack_count=9`.
That isolates the regression to the new RTL shape and resulting placement, not
to board state, JTAG programming, or the hardware session.

The full 64-byte path must therefore be full-beat based:

1. stage a 512-bit write beat through JTAG or a local producer,
2. commit it to DDR3 with `i_wb_sel = {64{1'b1}}`,
3. read back the 512-bit beat,
4. expose the beat as four 128-bit chunks or one 512-bit debug payload,
5. compare all 64 bytes in software.

The v53 diagnostic shell narrowed the current failure. Hardware with the
calibrating seed-0 bitstream reaches `DONE_CALIBRATE`, accepts rowstream
commands, and the debug window proves that a host write-chunk payload is staged
correctly in FPGA fabric. A direct staged write of bytes `00..0f` reports the
same `00..0f` in the diagnostic `read_window128_bytes`. The transport and JTAG
command packing are therefore not the immediate blocker.

The same v53 shell still fails real memory writes:

| Test | Address | Result |
| --- | ---: | --- |
| fullbeat `memtest64` | `0x0` | command ack passes, readback is existing DDR3/test pattern |
| fullbeat `memtest64` | `0x40` | command ack passes, readback is unrelated memory contents |
| dense-byte `memtest64` | `0x40` | command ack passes, many lanes become `0x00`; nonzero byte values do not reliably stick |
| low-byte write/read `0x5a` | `0x40` | write command reports ack, read returns existing pattern byte |

This means the next bug is at or below the rowstream-to-Wishbone DDR3 command
boundary: write data, write strobes, stale acknowledgements, or the
BIST-mode/user-port interaction. It is not a host packing problem.

The v54 command-pulse experiment changed the wrapper to register commands for
one controller cycle and drop `cyc` after command completion. That is a cleaner
Wishbone contract, but it perturbed placement enough that both seed 0 and seed
3 failed calibration in `READ_DATA`. A direct all-BEL transplant from the
calibrating v53 seed-0 routed JSON matched only 9,266 of 34,097 locks against
the v54 netlist; 24,831 locks were missing, mostly unstable generated packer
cell names. The partial over-lock also produced post-placement validity errors
and a stalled route. Full-cell locks are therefore only useful when the
synthesis identity is preserved; they are not a general cross-RTL transplant.

The v55 accepted-request diagnostic narrowed the failure further. With the same
RTL build, seeds 0 and 3 still fail calibration in `READ_DATA`, but seed 16
reaches `DONE_CALIBRATE` with `ack_count=9`. On that seed, a fresh hardware
programming run shows low-byte DDR3 writes are real: writing and reading `0xa5`
at beat addresses `0, 64, 128, 192, 256, 512, 1024` returns `0xa5` at each
address. Some of those reads still trip the older command-gate/integrity
decoder, so the observed byte and decoded calibration state are the decisive
signals for this diagnostic shell.

The same v55 seed-16 hardware run does not make the 64-byte contract pass:

| Test | Address | Accepted Request | Result |
| --- | ---: | --- | --- |
| low-byte write/read `0x5a` | `0x40` | `we=1`, `sel[0]=1`, low data `0x005a` | pass |
| fullbeat `memtest64 increment` | `0x0` | `we=1`, low 15 `sel` bits set, low data `0x0100` | fail |
| dense-byte `memtest64 increment` | `0x80` | one-hot commands accepted | fail |
| dense-byte lane 0 direct `0x5a` | `0x180` | accepted low data becomes `0x002d` | fail |
| dense-byte lane 0 direct `0xb4` | `0x180` | accepted low data becomes `0x005a` | fail |

That evidence changes the active hypothesis: the low-byte rowstream user port
is capable of writing and reading DDR3 on the seed-16 shell, but dense one-hot
byte writes and full 64-byte writes are not correct. Dense-byte remains a
diagnostic path only. The next useful RTL diagnostics should expose complete
fullbeat accepted fields and readback chunks, then isolate whether the
fullbeat failure is staging, byte-lane/select handling, or controller write
semantics.

The v63 opt-in debug experiments showed that controller-side instrumentation is
not a neutral diagnostic on this shell. The default v63 seed-16 bitstream, with
WB2 debug disabled and controller BIST disabled, reaches `DONE_CALIBRATE`,
advances `ack_count`, and still passes low-byte write/read. Its fullbeat
`memtest64` accepts commands but reads back calibration-pattern-like data
instead of the written `00..3f` byte stream.

Two v63 diagnostic variants failed before useful fullbeat evidence:

| Variant | Build knobs | Hardware result |
| --- | --- | --- |
| WB2 + bounded BIST | `ENABLE_WB2_DEBUG=1`, `CONTROLLER_BIST_ADDR_BITS=8` | fails calibration in `READ_DATA` / `ANALYZE_DATA_LOW_FREQ`, `ack_count=0` |
| bounded BIST only | `CONTROLLER_BIST_ADDR_BITS=8` | fails calibration in `READ_DATA`, `ack_count=0`, BIST counters remain zero |

The bounded-BIST-only bitstream was:

```sh
artifacts/manual-seed/fullbeat-v63-bist-debug1/seed16/rowstream-v63-bist-debug1-seed16.bit
```

Its routed JSON was:

```sh
artifacts/manual-seed/fullbeat-v63-bist-debug1/seed16/nextpnr-routed.json
```

The diagnostic conclusion is that adding the controller BIST datapath, even
without WB2 debug, perturbs the calibrated shell enough to fail before BIST
traffic starts. Until placement stability improves, higher-level DDR3
diagnostics should stay outside the controller shell or use the default
calibrating rowstream path.

The v64 clock-discipline correction changed the active rowstream shell to the
documented 500 MHz DDR3 / 125 MHz controller PLL and matching UberDDR3 timing
parameters. The build used seed 16 and the existing 411-lock v40 PHY pre-place
constraints:

```sh
artifacts/manual-seed/fullbeat-v64-500mhz/seed16/rowstream-v64-500mhz-seed16.bit
```

nextpnr routed the design legally, but the controller clock did not meet the
125 MHz target; post-route reported about 85.7 MHz max for
`bist_top.controller_clk`. Hardware programming confirmed the risk: JTAG was
alive and reported `version=64`, but calibration failed in `READ_DATA` with
`ack_count=0`.

That result means the high-speed direction needs either a lower AMD-compliant
controller rate, a smaller controller critical path, or stronger placement for
the controller-side logic. The next hardware experiment should use the
minimum AMD-compliant 400 MHz DDR3 clock and a 100 MHz controller clock before
attempting controller retiming.

The v75 calibration-only baseline moved to the minimum AMD-compliant clocking:
400 MHz DDR3, 100 MHz controller, and 200 MHz reference. It uses the same
411-lock v40 PHY pre-place constraints and appends the YPCB internal-VREF
features. A seed sweep over seeds 0..4 did not reach `DONE_CALIBRATE`, but it
did show two repeatable failure classes:

| Seed | Version | Calibration State | `debug1` | Result |
| ---: | ---: | --- | ---: | --- |
| 0 | 75 | `ANALYZE_DQS` | `0x000015a4` | fail |
| 1 | 75 | `IDLE` | `0x00001420` | fail |
| 2 | 75 | `IDLE` | `0x00001420` | fail |
| 3 | 75 | `IDLE` | `0x00001420` | fail |
| 4 | 75 | `ANALYZE_DQS` | `0x000015a4` | fail |

That makes the active blocker narrower than generic reset or IDELAY startup:
the better class reaches MPR/DQS analysis with `sys_rstn=true` and
`idelay_ready=true`, but does not find the expected DQS training pattern.

The v80-v84 calibration-only experiments tested the first board-specific
MIG-style knobs against seed 4:

| Version | Change | Build Result | Hardware Result |
| ---: | --- | --- | --- |
| 80 | Enable DDR3 TDQS mode | routed, timing passed at 100 MHz | regressed to `IDLE`, `instruction=1`, `debug1=0x00001420` |
| 81 | TDQS plus MIG MR1 drive/termination (`DIC=RZQ/7`, `RTT_NOM=RZQ/4`) | routed, timing passed at 100 MHz | regressed to `IDLE`, `instruction=1`, `debug1=0x00001420` |
| 82 | MIG MR1 drive/termination without TDQS | routed, timing passed at 100 MHz | regressed to `IDLE`, `instruction=1`, `debug1=0x00001420` |
| 83 | Swap top-level DQS P/N wiring | nextpnr assertion before bitstream | no hardware result |
| 84 | Shift capture clock phase from 90 to 270 degrees | routed, post-route `controller_clk` failed at about 95.45 MHz | still `ANALYZE_DQS`, `instruction=13`, `debug1=0x000015a4` |
| 85 | Baseline phase, but skip appended YPCB internal-VREF FASM features | routed, post-route `controller_clk` passed at about 107.69 MHz | changed failure point to `MPR_READ`, `instruction=13`, `debug1=0x000015a2` |

These trials rule out the first obvious MR1 knob set as a fix. TDQS and
MIG-style output drive/termination make the calibration-only shell fail
earlier, while the 270-degree capture phase does not move past DQS analysis.
Removing the explicit VREF append does not make calibration pass, but it does
move the failure earlier from DQS analysis back to MPR read. The next
controlled experiments should return to the VREF-enabled v75 source shape and
expose the MPR/DQS sampled training data directly, then use that visibility to
test DQS lane/order and placement/timing variants that preserve the
400 MHz/100 MHz clock discipline.

The v65 minimum-rate AMD-compliant experiment changed the active rowstream
shell to 400 MHz DDR3 / 100 MHz controller with matching UberDDR3 timing
parameters and nextpnr clock constraints. The build used seed 16 and the same
v40 PHY pre-place constraints:

```sh
artifacts/manual-seed/fullbeat-v65-400mhz/seed16/rowstream-v65-400mhz-seed16.bit
```

nextpnr routed the design legally, but still did not meet the controller clock;
post-route reported about 76.3 MHz max for `bist_top.controller_clk` against
the 100 MHz target. Hardware programming confirmed this is not a usable shell:
JTAG was alive and reported `version=65`, but calibration failed in
`READ_DATA` with `ack_count=0`.

The v65 timing report points at controller-side debug/readback fanout, including
wide `jtag_debug_payload` paths. The next targeted RTL change is to snapshot the
debug payload on `controller_clk` and keep live `wb_data`/readback paths out of
the asynchronous BSCAN capture cone.

The v70 high-speed experiment corrected a major DDR3 mode error: the YPCB
400 MHz shell was still instantiating UberDDR3 with `DLL_OFF=1`. That is only
the low-frequency path. With `DLL_OFF=0`, nextpnr timing improved materially
for seed 16, but hardware still did not reach `DONE_CALIBRATE`. The visible
state changed from a read-data failure to an apparent early-init state:
`state=IDLE`, `instruction=2`, `ack_count=0`.

The v71 diagnostic build proved that this was not a permanent init-ROM stall.
It exposed the init delay counter in `debug1` for one build only. Repeated
hardware samples showed the FSM reaching DLL-on read calibration
(`instruction=13`, `state=ANALYZE_DQS`, `pause_counter=1`) and then returning
to early reset/init. The current high-speed failure is therefore a calibration
retry/reset loop, not a dead init sequencer. The same hardware session then
reprogrammed the older v63 seed-16 low-speed artifact and reached
`DONE_CALIBRATE` with `ack_count=9`, confirming that the board, DDR3, and JTAG
path were still healthy.

The v72 ODELAY experiment compared YPCB against the closest
`qmtech_kintex_7` example, which uses `ODELAY_SUPPORTED=1`. Enabling that on
YPCB did not reach hardware: nextpnr/OpenXC7 failed during packing with:

```text
ERROR: ODELAYE2 'bist_top.uberddr3.ddr3_phy_inst.genblk4.ODELAYE2_clk' has DATAOUT connected to unsupported cell type IOB33M_OUTBUF
```

So `ODELAY_SUPPORTED=1` is not an available YPCB knob in the current open flow.
It may be an upstream/tooling project, but the active YPCB shell must remain
`ODELAY_SUPPORTED=0` unless the pin/bank mapping or nextpnr/OpenXC7 support
changes. v73 restored the buildable no-ODELAY shell.

The v73 seed sweep with v40 PHY locks kept failing calibration. Seed 3 routed
at about 84.9 MHz against the 100 MHz controller target, seed 16 at about
82.1 MHz, and seed 40 at about 96.6 MHz. Hardware testing seed 40 still
reported `version=73`, `state=IDLE`, `instruction=2`, and `ack_count=0`.

The next isolation step is v74: keep the AMD-compliant 400 MHz DDR3 / 100 MHz
controller clocks and the no-ODELAY YPCB PHY mode, but instantiate UberDDR3
with `BIST_MODE=0`. The rowstream shell is host-driven, so built-in BIST is not
part of the final contract. Removing it should reduce controller-domain timing
load while still requiring the same DLL-on read calibration path to pass before
JTAG Wishbone commands are accepted.

v74 did not improve the shell. Seed 40 routed at about 85.8 MHz against the
100 MHz controller target and hardware still failed before the command gate:
`version=74`, `state=IDLE`, `instruction=1`, `ack_count=0`. This makes
`BIST_MODE=0` useful for the final host-driven contract but not sufficient as a
calibration-stability knob. The next isolation step is a calibration-only
high-speed shell with the rowstream Wishbone command/readback logic removed
from synthesis; if that shell calibrates, the 64-byte driver path can be added
back in smaller timing-controlled blocks.

The v75 calibration-only shell removes the rowstream Wishbone command/readback
state machine but preserves the same DDR3 PHY clocks, `DLL_OFF=0`,
`ODELAY_SUPPORTED=0`, and v40 PHY BEL locks remapped from `bist_top` to
`calib_top`. The first seed-40 run appeared to meet timing, but the clock
constraint script only constrained `bist_top.*`; that build was invalid as a
timing experiment and hardware failed in early init.

After adding explicit `calib_top.*` clocks, seed 40 routed cleanly with
`controller_clk` reported at 106.30 MHz against the 100 MHz constraint while
the DDR3 clocks were constrained to 400 MHz. Hardware still did not reach
`DONE_CALIBRATE`: JTAG reported `version=75`, `state=ANALYZE_DQS`,
`instruction=13`, `idelay_ready=true`, `ack_count=0`, and `calibration=fail`.
That rules out rowstream driver timing as the sole root cause and confirms the
current high-speed no-ODELAY shell is failing inside the DLL-on DQS/read
calibration path. The next step is to find whether any placement/router/seed
combination on this smaller shell can pass calibration; if none does, the
project needs either an ODELAY-capable YPCB open-flow fix or a controller/PHY
calibration change instead of more rowstream wrapper work.

A short constrained PNR sweep reused the same v75 calibration-only synth JSON
and varied only nextpnr placement seed. Several candidates met or nearly met
the 100 MHz controller constraint, but none of the hardware-tested candidates
calibrated:

| Seed | Controller max | Hardware state | Instruction | `debug1` | Result |
| ---: | ---: | --- | ---: | ---: | --- |
| 0 | 104.49 MHz | `IDLE` | 2 | `0x00001440` | fail before command gate |
| 3 | 106.80 MHz | `IDLE` | 2 | `0x00001440` | fail before command gate |
| 4 | 100.05 MHz | `ANALYZE_DQS` | 13 | `0x000015a4` | fail before command gate |
| 40 | 106.30 MHz | `ANALYZE_DQS` | 13 | `0x000015a4` | fail before command gate |

Seeds 1 and 2 built at 93.81 MHz and 99.68 MHz respectively and were not
hardware-priority candidates. Seed 5 was stopped once the sweep already had
multiple timing-clean failures to compare.

This changes the next useful experiment. Closing the visible controller timing
constraint is necessary but not sufficient. The next build should expose DQS
calibration internals: reset cause, active lane, `data_start_index`,
`start_index_check`, lane early/late flags, and whether the expected write
pattern matched the read lane. That is the information needed to distinguish a
placement/timing reset loop from a missing PHY capability or a calibration
algorithm assumption that is wrong for the YPCB no-ODELAY path.

The v76/v77 debug attempts showed that this observability has to be treated as
a placement perturbation, not a passive probe. v76 exposed live per-lane DQS
search fields and built successfully, but the seed-4 hardware result regressed
from the v75 `ANALYZE_DQS` stop to `IDLE` / instruction 2. A trimmed v77 debug
word only exposed active lane, bitslip count, reset sources, and calibration
Wishbone handshake bits; seed 4 routed timing-clean at 111.96 MHz, but hardware
still failed earlier than v75: `version=77`, `state=IDLE`, `instruction=1`,
`debug1=0x00200420`, `calib_stall=true`, and no reset-source bits set.

Comparing the v75 seed-4 routed JSON with the v77 seed-4 routed JSON showed
all high-risk hard primitives remained fixed:

| Category | Stable cells |
| --- | ---: |
| clock/IO/PHY primitives | 539 / 539 |
| BUFGCTRL | 4 / 4 |
| IDELAYCTRL | 3 / 3 |
| IDELAYE2 | 72 / 72 |
| ISERDESE2 | 72 / 72 |
| OSERDESE2 | 97 / 97 |
| PAD/IOB primitives | all equal |

The regression therefore came from soft controller placement and timing shape,
not from moving the physical DDR3 I/O shell. The active calibration-only top
keeps the controller debug parameter available but disabled by default
(`version=78`) so future seed sweeps use the non-debug shell.

The v75 source was then restored again to remove the disabled debug hook shape
entirely. Rebuilding seed 4 reproduced the expected timing profile: placement
timing reported about 69.6 MHz for `controller_clk`, while post-route timing
reached about 100.05 MHz. Hardware status decoding was also fixed so
calibration-only images use their payload version, not the default rowstream
protocol selector, to decode `sys_rstn`.

After that decoder fix, the current 400 MHz DDR3 / 100 MHz controller
calibration-only evidence is:

| Seed | Version | `sys_rstn` | `idelay_ready` | Calibration State | `debug1` | Result |
| ---: | ---: | --- | --- | --- | ---: | --- |
| 0 | 75 | true | true | `ANALYZE_DQS` | `0x000015a4` | fail |
| 1 | 75 | true | true | `IDLE` | `0x00001420` | fail |
| 2 | 75 | true | true | `IDLE` | `0x00001420` | fail |
| 3 | 75 | true | true | `IDLE` | `0x00001420` | fail |
| 4 | 75 | true | true | `ANALYZE_DQS` | `0x000015a4` | fail |

Seed 4 proves the controller reaches the first DQS/MPR training loop. It is
not held in reset and IDELAYCTRL is ready. The active failure is therefore
around MPR read capture, DQS polarity/lane mapping, phase, VREF/termination, or
mode-register configuration, before any rowstream or 64-byte write datapath can
matter.

The YPCB Vivado MIG project for channel 0 uses:

| MIG setting | Value |
| --- | --- |
| Memory device | `MT41K256M8XX-125` |
| Data width | 72 bits |
| Data mask | disabled |
| TDQS | enabled |
| MR1 RTT_NOM | `RZQ/4` |
| DIC | `RZQ/7` |
| DDR3 time period | 1875 ps |

LiteX models the same channel as 64 data bits plus an ECC lane and sets
internal VREF to 0.750 on banks 11 through 18. The current YPCB OpenXC7 flow
already appends 0.750 VREF features for those banks, but UberDDR3 previously
hard-coded MR1 `TDQS=0`. Since YPCB exposes no DM pins and MIG enables TDQS for
the x8 devices, the next narrow experiment is to make TDQS a controller
parameter and enable it only in the YPCB calibration-only top.

If TDQS does not move the failure, the next knobs should be tested in this
order while keeping the top small:

1. MR1 drive/termination to match MIG exactly: `DIC=RZQ/7`, `RTT_NOM=RZQ/4`.
2. VREF feature verification against bank/HCLK rows and a controlled no-VREF
   or alternate-VREF build.
3. DQS polarity swap for all lanes, then targeted lane-0 DQS/DQ mapping checks.
4. `ddr3_clk_90` phase sweep around the ODELAY-unsupported PHY path.
5. Only after calibration passes again, reintroduce the full-beat 64-byte
   rowstream contract around the stable shell.

## Artifact Policy

There are two different artifact classes:

- **Matching synth artifact**: a Yosys JSON whose cell names match a known-good
  routed placement.
- **Placement oracle**: routed JSON / extracted BEL-lock JSON from a
  hardware-passing build.

`oracle-all` is only meaningful when the synth artifact matches the extracted
lock names. Fresh synthesis can rename generated packer cells; this caused only
5,935 of 26,697 oracle locks to apply in a fresh build. For maximal-lock
experiments, use PNR-only from the matching synth JSON.

Current known matching synth JSON:

```sh
artifacts/task6/calibration-sweeps/ypcb-rowstream-oracle-all-seed0/2026-05-14T08-03-04+0200-oracle-all-seed0/build-artifacts/ypcb_00338_1p1_uberddr3_rowstream_loader.json
```

Current full placement oracle:

```sh
artifacts/task6/lock-experiments/seed3-all-bel-locks.json
```

## Execution Plan

Current priority: implement the DDR3 driver contract even while calibration
work remains unstable. The driver must make the desired memory semantics clear
and testable, so calibration and placement work can be treated as the transport
problem underneath it rather than mixed into the API definition.

1. Align RTL PLL, DDR3 timing parameters, and nextpnr `addClock` constraints to
   the frozen-shell 500/125/200 MHz clocks.
2. Rebuild a rowstream bitstream from current RTL and test hardware with no
   global `--freq`.
3. If fresh synthesis is unstable, create a preserved shell artifact and use
   PNR-only for placement/timing experiments. This is now the active path:
   fresh synthesis with only the physical locks does not reproduce calibration.
4. Find the smallest lock set that both:
   - reaches `DONE_CALIBRATE`, `integrity_pass`, `ack_count` advances, `err_count=0`,
   - meets nextpnr timing without `--timing-allow-fail`.
5. The v45 fullbeat command path exists, but it must not replace the preserved
   v44 calibration base until a seed or lock set reaches `DONE_CALIBRATE`.
6. Next implementation direction: keep the v44 shell intact and move the
   additional fullbeat staging/producer logic outside the calibration-critical
   region, or create a new full placement oracle from a v45 seed that
   calibrates. A fresh fullbeat shell with only the 411 physical locks is not
   enough.
7. Only after the 64-byte contract is deterministic, add higher-level DDR3
   functionality outside the frozen shell.

Immediate next strategy:

1. Keep the v53 calibrating diagnostic shell as the hardware base while
   investigating the rowstream-to-Wishbone contract.
2. Add the smallest possible diagnostics to observe the controller-side
   accepted request: accepted `we`, `sel`, `addr`, low data bytes, and whether
   the ack being consumed belongs to the issued command.
3. Build those diagnostics as PNR-only seed sweeps from one synth JSON. Do not
   treat a new RTL result as meaningful until at least one seed reaches
   `DONE_CALIBRATE`.
4. Once the accepted-request trace proves the bad field, fix that field with
   the smallest RTL change and immediately hardware-test low-byte, dense-byte,
   and fullbeat paths.
5. After one seed passes fullbeat read/write, extract a matching placement
   oracle from that exact routed JSON before attempting any seed-stability work.

## Driver Contract

The host-side driver lives at:

```sh
scripts/task6/ypcb_ddr3_driver.py
```

It is the explicit software contract for the YPCB DDR3 rowstream shell. It
assumes the FPGA has already been programmed with a rowstream bitstream and
that the DDR3 shell is calibrated. Calibration is still mandatory for hardware
success, but the driver implementation is intentionally separated from the
calibration search.

Primary contract:

1. `write-beat --method fullbeat` writes one complete 64-byte DDR3 beat using
   four 128-bit chunk commands and all byte lanes active in the hardware path.
2. `read-beat` reads one complete 64-byte beat when the debug payload exposes
   the full 512-bit readback. Older shells expose only the first 128-bit window,
   which the driver reports without pretending it is a full pass.
3. `memtest64` writes a 64-byte pattern, reads it back, and compares all
   reported bytes.

Diagnostic-only contract:

`write-beat --method dense-byte` issues 64 one-hot dense byte writes. This mode
is useful for probing lanes and command decoding, but it is not the target DDR3
driver semantics for YPCB because the board path has no reliable byte-mask
foundation. A dense-byte memtest failure is expected on YPCB unless the design
is changed to perform read-modify-write internally or the board exposes working
DM pins.

Useful dry-run command encoding:

```sh
nix develop .#default --command python3 scripts/task6/ypcb_ddr3_driver.py \
  encode --opcode 0x01 --addr 0 --chunk 0 --data128 0x0

nix develop .#default --command python3 scripts/task6/ypcb_ddr3_driver.py \
  --dry-run memtest64 --addr 0 --pattern increment --write-method fullbeat
```

Hardware examples, after programming a calibrated bitstream:

```sh
nix develop .#default --command python3 scripts/task6/ypcb_ddr3_driver.py status

nix develop .#default --command python3 scripts/task6/ypcb_ddr3_driver.py \
  memtest64 --addr 0 --pattern increment --write-method fullbeat
```

## Acceptance Criteria

A candidate is not considered usable for further DDR3 work unless hardware
reports:

- decoded state `DONE_CALIBRATE`,
- `calibration=pass`,
- `command_gate=pass`,
- `integrity=pass`,
- `ack_count` advances,
- `err_count=0`,
- readback matches expected data.

For the next milestone, the same criteria must pass for the dense 64-byte
write/readback path, not only low-byte rowstream commands. On YPCB this means a
full-beat write/readback test, not a byte-enable test.

## Current Evidence

- Exact-400 MHz RTL and constraints were tested and failed before calibration,
  even when hard DDR3 primitives were locked.
- The 500/125 MHz frozen-shell clock point remains compliant with the AMD/Xilinx
  guidance because it is above the 400 MHz minimum.
- Fresh 500/125 MHz synthesis with the 437-lock physical oracle is not enough:
  seed 3 fails timing at 125 MHz without `--timing-allow-fail`, and the
  diagnostic `--timing-allow-fail` dense-byte build still fails before
  calibration starts.
- Fresh v64 fullbeat command RTL was hardware-tested in two forms:
  `ypcb-rowstream-fullbeat-seed-3-freq-25-timing-allow-fail` and
  `ypcb-rowstream-seed-3-freq-25-timing-allow-fail`. Both programmed
  successfully but reported `state=IDLE`, `calibration=fail`, and
  `ack_count=0`.
- Minimal v45 fullbeat rowstream RTL was committed and hardware-tested through a
  PNR-only seed sweep over `0, 3, 16, 40, 44`. All five bitstreams programmed
  successfully and all five reported `state=IDLE`, `calibration=fail`, and
  `ack_count=0`.
- The preserved seed-3 v44 artifact from
  `artifacts/task6/calibration-sweeps/ypcb-rowstream-ffx-addback-pnr-only-build/2026-05-14T10-21-35+0200-oracle-all-seed3/`
  still reports `DONE_CALIBRATE`, `calibration=pass`, and advancing `ack_count`
  on the same hardware.
- The known hardware-passing path is the PNR-only frozen artifact family derived
  from the matching synth JSON and extracted placement oracle. Further DDR3
  functionality must preserve that shell instead of relying on fresh synthesis.
- The v53 staged-data diagnostic proves host-to-FPGA rowstream packing is
  correct, but DDR3 user writes still do not stick. This is now the active
  functional blocker.
- The v54 command-pulse fix is logically attractive but is not yet a usable
  hardware base: seeds 0 and 3 both fail calibration in `READ_DATA`.
- All-cell BEL locks extracted from v53 are not portable across v54 synthesis:
  generated cell names changed too much, and the partial 9,266-lock application
  created an invalid/stalled placement.
- The v58 aux-contract fix restored the active rowstream wrapper to the
  controller contract: write commands use `i_aux[0]=0` and read commands use
  `i_aux[0]=1`. Hardware with seed 16 reached `DONE_CALIBRATE`, advanced
  `ack_count`, and passed the low-byte write/read smoke test.
- The v59 fullbeat staging fix latched the complete 512-bit write payload before
  issuing the final bus write. Hardware still failed `memtest64` fullbeat:
  commands were accepted, but readback remained calibration-pattern data. This
  proves the remaining issue is below host command packing.
- The v70/v71 high-speed DLL-on path reaches read calibration and then resets;
  it is not stuck forever in DDR3 init. The next useful calibration work should
  instrument or constrain the DLL-on DQS/read-leveling path, not the reset ROM.
- `ODELAY_SUPPORTED=1` matches the qmtech Kintex-7 example but is blocked on
  YPCB in the current open flow by an ODELAYE2-to-IOB33M_OUTBUF packing error.
- The v60 bounded controller BIST experiment enabled an internal all-lane BIST
  by setting `BIST_ADDR_BITS=8`. It did not reach `DONE_CALIBRATE`, which is
  useful evidence: the controller's own BIST catches the same full-lane failure
  that host `memtest64` sees.
- The default rowstream shell now keeps bounded BIST opt-in. With
  `BIST_ADDR_BITS=0`, the controller skips the post-calibration BIST and keeps
  the calibrated rowstream foothold usable for further hardware iteration.
- The v62 always-on WB2 debug attempt exposed the controller's second Wishbone
  debug path but broke calibration (`state=ISSUE_WRITE_1`, `ack_count=0`).
  Therefore WB2 debug is not part of the default shell.
- The v63 shell makes WB2/BIST debug build-time opt-in through
  `ENABLE_WB2_DEBUG` and `CONTROLLER_BIST_ADDR_BITS`. The default seed-16 v63
  bitstream reached `DONE_CALIBRATE` with `ack_count=9`; low-byte readback at
  address `0x40` returned `0x5a`; fullbeat `memtest64` still failed with
  calibration-pattern readback.
- The v66/v67/v68/v69 high-speed 400 MHz shell experiments all failed before
  calibration completed. Hardware reported `READ_DATA`, `debug1=0x000006cc`,
  and `ack_count=0`.
- v66 registered the 512-bit JTAG debug payload; v67 added a deeper debug
  snapshot pipeline; v68 narrowed the probe/debug readback to 32 bits; v69
  replaced the full 512-bit loader readback capture with a selected 128-bit
  chunk. None of those changes made the 400/100 MHz shell calibrate.
- The v68/v69 routed critical path remains rooted at the controller read-data
  mux: `ddr3_controller_inst.index_wb_data -> wb_data[...] -> downstream CE`.
  That rules out the top-level debug scan as the decisive blocker. The next
  high-speed work must either preserve a known-calibrating shell more strictly
  or change the controller/calibration read path itself.

## WB2/BIST Diagnostic Variant

The default shell must keep `ENABLE_WB2_DEBUG=0` and
`CONTROLLER_BIST_ADDR_BITS=0` so it remains a calibrated foothold. For a
diagnostic build that intentionally runs bounded BIST and exposes the
controller's WB2 debug registers, synthesize the rowstream target with:

```sh
ROWSTREAM_SYNTH_PRELUDE="chparam -set ENABLE_WB2_DEBUG 1 ypcb_00338_1p1_uberddr3_rowstream_loader; chparam -set CONTROLLER_BIST_ADDR_BITS 8 ypcb_00338_1p1_uberddr3_rowstream_loader;"
```

Then query WB2 registers with:

```sh
python3 scripts/task6/ypcb_ddr3_driver.py --timeout 20 --command-repeats 2 debug-wb2 --addr 15
python3 scripts/task6/ypcb_ddr3_driver.py --timeout 20 --command-repeats 2 debug-wb2 --addr 16
```

Addresses `15` and `16` expose `correct_read_data` and `wrong_read_data`.
Additional controller debug words are available through the WB2 register map in
`rtl/ddr3_controller.v`.
