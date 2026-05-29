# Seed-Dependent DDR3 Calibration SDF Investigation

This note is specific to the standalone YPCB UberDDR3 OpenXC7 build in this repo.
The current top-level uses `BYTE_LANES = 2` and `ODELAY_SUPPORTED(0)`, so the first-order SDF targets are DQ/DQS input, OSERDES/IOB output without ODELAY, IDELAYCTRL/reset release, clocking, and calibration control.


## Experiment Hygiene Doctrine

Every hardware experiment must be reproducible from git history, not from an uncommitted worktree. Treat each run as a tuple of RTL/debug variant, constraints/locks, tool flags, nextpnr seed, SDF/JSON artifacts, bitstream hash, and hardware result. Commit the source-side definition of that tuple before or immediately after running the experiment, then commit the result table update as part of the same logical experiment record.

Rules:

1. Do not leave RTL, constraints, scripts, flake targets, or documentation for an experiment uncommitted.
2. Do not treat generated `result-*` Nix symlinks as experiment records; record the derivation target, SDF/JSON path, bitstream hash, and hardware JSON/CSV rows instead.
3. If observability RTL changes, it is a new RTL/debug variant and needs its own committed experiment identity.
4. If a hardware result changes after only locks, constraints, or tool flags changed, preserve that exact change in git before interpreting SDF/JSON causality.
5. Keep cause/effect hypotheses separate from solution hypotheses in the ledger. A solution is only promoted after it changes the intended SDF/JSON signature and improves hardware pass/fail in the matrix.

## Current Hardware Matrix

Use the existing board results as the starting classification:

| Candidate | Hardware result | Key status |
| --- | --- | --- |
| `seed-1` | fail | `calib_complete=false`, `state_calibrate=0` |
| `seed-2` | fail | `calib_complete=false`, `state_calibrate=0` |
| `seed-3` | pass | `calib_complete=true`, `state_calibrate=23` |
| `seed-4` | pass | `calib_complete=true`, `state_calibrate=23` |
| `seed-5` | pass | `calib_complete=true`, `state_calibrate=23` |
| `seed-1-robust` | pass | `--no-tmdriv` plus reset-release LUT locks |
| `seed-2-robust` | pass | `--no-tmdriv` plus reset-release LUT locks |

Because the failing unrobust seeds stop at calibration state 0, do not start by assuming late read/write training failure. First compare reset release, IDELAYCTRL readiness, generated clocks, and controller startup paths. Then compare DQ/DQS IO timing.

## Emitting SDF

`nextpnr-xilinx --sdf <file>` emits the routed delay model. `--sdf-cvc` changes SDF formatting for CVC-style consumers; it should not affect placement, routing, FASM, or bitstream behavior. Use both when debugging parser issues. Prefer CVC SDF for `sdf-toolkit` checks in this repo.

The flake exports raw and CVC SDF targets for each existing candidate:

```bash
nix build .#ypcb-ddr3-cvc-sdf-seed-1 -o result-sdf-seed1-fail
nix build .#ypcb-ddr3-cvc-sdf-seed-3 -o result-sdf-seed3-pass
nix build .#ypcb-ddr3-cvc-sdf-seed-1-robust -o result-sdf-seed1-robust
```

The output contains both SDF and a same-run placed JSON:

```bash
ls result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf
ls result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.placed.json
```

Raw SDF targets use `ypcb-ddr3-sdf-seed-N`; robust raw targets use `ypcb-ddr3-sdf-seed-N-robust`.

## Sanity Checks

Run package-level parser checks first:

```bash
nix run .#sdf-toolkit -- stats result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf
nix run .#sdf-toolkit -- stats result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf
nix run .#sdf-toolkit -- diff \
  result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf \
  result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf
```

Then run the DDR-focused normalized comparator:

```bash
nix run .#uberddr3-sdf-compare -- \
  --good-sdf result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf \
  --bad-sdf result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf \
  --good-json result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.placed.json \
  --bad-json result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.placed.json \
  --label seed1-fail-vs-seed3-pass
```

Repeat the two most useful contrasts:

```bash
nix run .#uberddr3-sdf-compare -- \
  --good-sdf result-sdf-seed1-robust/ypcb_00338_1p1_ddr3.cvc.sdf \
  --bad-sdf result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf \
  --good-json result-sdf-seed1-robust/ypcb_00338_1p1_ddr3.placed.json \
  --bad-json result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.placed.json \
  --label seed1-fail-vs-seed1-robust

nix run .#uberddr3-sdf-compare -- \
  --good-sdf result-sdf-seed4-pass/ypcb_00338_1p1_ddr3.cvc.sdf \
  --bad-sdf result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf \
  --label seed2-fail-vs-seed4-pass
```

The comparator writes `artifacts/sdf-comparisons/<label>/summary.json`, `family_lane_metrics.csv`, and `largest_bad_slower_deltas.csv`.

## Path Families To Compare

Prioritize these families in this order for the current failing symptom:

1. `idelayctrl_reset_release`: `ddr3_phy_inst.delay_before_release_reset[*]` and its LUT/FF routing. Existing robust results already implicate this region.
2. `idelayctrl`: IDELAYCTRL placement, RDY routing, reset, and `i_ref_clk` path.
3. `reset_cdc` and `clocking`: `rst_n && clk_locked`, MMCM/PLL/BUFG paths from `clk_wiz`, `controller_clk`, `ddr3_clk`, `ref_clk`, `ddr3_clk_90`.
4. `dqs_input`: pad/IBUFDS to IDELAYE2 to ISERDESE2/controller observations for `genblk7[0]` and `genblk7[1]`.
5. `dq_input`: pad/IBUF to IDELAYE2 to ISERDESE2/controller observations for `genblk5[0..15]`, grouped as lane 0 and lane 1.
6. `dqs_output` and `dq_output`: OSERDESE2/IOB to pad. For this YPCB top, ODELAY paths are mostly not active because `ODELAY_SUPPORTED(0)`.
7. `idelay_control`: `CNTVALUEIN`, `LD`, `CE`, `INC`, bitslip, and per-lane delay update signals from controller to PHY.
8. `calibration_fsm`: `state_calibrate`, `bitslip`, `dqs_start`, `dqs_target`, `dqs_store`, MPR/write-leveling/read-test decision logic.

For each family, look at max delay, p95 delay, intra-lane spread, lane0-vs-lane1 spread, and bad-minus-good deltas. A single larger global max delay is less interesting than a stable separator that appears in both failing seeds and not in passing seeds.

## Actionable Outcomes

Treat SDF evidence as actionable only if it is stable across at least two failing seeds or appears in a fail-vs-robust comparison of the same seed.

If reset release or IDELAYCTRL paths separate pass from fail, keep the existing reset-release BEL locks and expand them only to the minimum set of adjacent reset/RDY/control LUTs or FFs. The existing robust lock file is `example_demo/ypcb_00338_1p1/constraints/ypcb_00338_1p1_ddr3_reset_release_locks.json`.

If DQ/DQS input skew separates pass from fail, generate pre-place BEL locks from a known-good placed JSON for the lane-local `IDELAYE2_data`, `ISERDESE2_data`, `IOBUF_data`, `IDELAYE2_dqs`, `OSERDESE2_dqs`, and `IOBUFDS_dqs` cells under `ddr3_top_inst.ddr3_phy_inst.genblk5[*]` and `genblk7[*]`. Lock only the active 16 DQ bits and 2 DQS lanes for this target.

If IDelay control routing separates pass from fail, place or lock the small control fanout feeding `i_controller_idelay_*_cntvaluein`, `i_controller_idelay_*_ld`, bitslip, and write-leveling control near the DDR PHY clock region. Prefer locking a small cone from a passing seed over whole-design locking.

If clocking differs, lock the MMCM/PLL/BUFG resources from a passing seed and audit generated clock constraints. The current XDC has an input `clk50` clock and nextpnr is also run with `--freq 83.333`; if nextpnr accepts more explicit generated clocks for this flow, add them for `controller_clk`, `ddr3_clk`, `ref_clk`, and `ddr3_clk_90`.

If the bad seed has worse DQ/DQS output delay or skew, first verify whether that path is actually active under `ODELAY_SUPPORTED(0)`. If ODELAY is later enabled, include `ODELAYE2_data`, `ODELAYE2_dqs`, and command/clock ODELAY cells in the lock set.

## Negative Result Interpretation

If SDF does not separate passing and failing seeds, the most likely interpretation is not that the hardware result is impossible. It means the variable is outside nextpnr's emitted digital delay model or hidden by model granularity. Suspects then include missing or inaccurate openXC7 timing arcs for IDELAY/IDELAYCTRL/ISERDES/OSERDES/IOB paths, DQS-specific analog behavior, bitstream feature emission differences in prjxray/FASM, clocking/reset startup behavior not represented as a simple path delay, PVT/board margin, or router behavior such as `tmdriv` affecting an unmodeled resource.

The goal is to replace seed sweeping with the smallest deterministic constraint that moves failing seeds into the passing cluster. If the SDF clusters are inseparable, keep the robust lock experiment as evidence and shift to bitstream/FASM feature diffs, placement legality audits, and hardware margin probes.


## DDR endpoint metric matrix

The preferred SDF workflow is now metric-first rather than full-file diff-first.
Generate or reuse CVC SDF artifacts, then run:

```bash
nix run .#uberddr3-sdf-metrics -- \
  --out-dir artifacts/sdf-metrics/cvc-seed-matrix \
  --sample seed1-fail:fail:result-sdf-seed1-fail \
  --sample seed2-fail:fail:result-sdf-seed2-fail \
  --sample seed3-pass:pass:result-sdf-seed3-pass \
  --sample seed1-robust:robust:result-sdf-seed1-robust \
  --sample seed2-robust:robust:result-sdf-seed2-robust
```

For a rerun after changing only the normalizer, reuse the cached first-stage
query JSON:

```bash
nix run .#uberddr3-sdf-metrics -- --reuse-cache \
  --out-dir artifacts/sdf-metrics/cvc-seed-matrix \
  --sample seed1-fail:fail:result-sdf-seed1-fail \
  --sample seed2-fail:fail:result-sdf-seed2-fail \
  --sample seed3-pass:pass:result-sdf-seed3-pass \
  --sample seed1-robust:robust:result-sdf-seed1-robust \
  --sample seed2-robust:robust:result-sdf-seed2-robust
```

The outputs to inspect first are:

- `candidate_strict_fail_slower.csv`: metrics where all failing seed values are above all passing seed values.
- `candidate_fail_slower.csv`: metrics where failing seed median is above passing seed median.
- `semantic_metrics.csv`: per-sample endpoint, lane spread, control fanout spread, and CNTVALUEIN bus skew metrics.
- `direct_entries.csv`: normalized first-stage query records with both readable pins and exact graph pins.
- `rank_path_fail_slower.sh`: exact `sdf-toolkit rank-paths` commands for the strict fail-slower endpoint candidates.

The rank-path scripts use `sdf-toolkit` as the executable name. Run them from an
environment where `sdf-toolkit` is on `PATH`, for example `nix develop`, or copy
one command and replace `sdf-toolkit` with `nix run .#sdf-toolkit --`.


## Current SDF Findings

The expanded pass/fail matrix includes failing seeds 1/2, passing seeds 3/4/5,
and robust seeds 1/2. The strict fail-slower population shrank from the initial
single-pass-seed matrix, but the surviving separators are still dominated by
IDELAY programming delivery:

```text
idelay_dqs_cntvaluein lane0 dqs0 ctrl=4  fail median 2092.5 ps, pass median 1350.0 ps
idelay_data_cntvaluein lane1 dq14 ctrl=3 fail median 1995.5 ps, pass median 1310.0 ps
idelay_data_cntvaluein lane1 dq8  ctrl=2 fail median 2141.0 ps, pass median 1473.0 ps
idelay_data_cntvaluein lane1 dq10 ctrl=2 fail median 1988.0 ps, pass median 1396.0 ps
idelay_data_cntvaluein lane1 dq12 ctrl=2 fail median 2002.5 ps, pass median 1488.0 ps
```

This keeps the leading hypothesis focused on calibration-to-IDELAY programming
paths, especially `CNTVALUEIN[*]`, rather than global SDF delay or generic
DQ/DQS datapath delay.

The robust-factor split matrix adds `--no-tmdriv` only and reset-locks-only
variants for failing seeds 1/2. Representative medians:

```text
metric                                    fail   pass   no-tmdriv  reset-only  robust
idelay_dqs_cntvaluein lane0 dqs0 ctrl=4   2092.5 1350.0 2067.0     2032.5      1343.0
idelay_data_cntvaluein lane1 dq14 ctrl=3  1995.5 1310.0 1224.5     1547.0      1602.0
idelay_data_cntvaluein lane1 dq8  ctrl=2  2141.0 1473.0 1291.5     1419.0      1443.5
idelay_data_cntvaluein lane0 dq4  ctrl=3  2318.0 1820.0 1314.5     1791.5      1638.5
idelay_data_cntvaluein lane0 dq1  ctrl=3  2313.5 1822.0 1229.5     1708.5      1595.5
idelay_ld               lane0 dq7         2305.5 1968.0 1805.5     2425.0      1310.5
```

Interpretation:

- `--no-tmdriv` improves many DQ `CNTVALUEIN` paths substantially.
- reset-locks-only is mixed and does not consistently move the metrics to the
  pass population.
- the top DQS `CNTVALUEIN[4]` separator is not fixed by either split alone, but
  is fixed in the combined robust build.
- therefore the robust behavior is not explained by one simple global delay
  shift; it is a placement/routing interaction.

The existing reset-release lock file is not currently a reliable physical lock.
A post-build checker reports mismatches for reset-locks-only and robust builds:

the lock file requests `SLICE_X0Y113`, while observed placements include
`SLICE_X0Y107`, `SLICE_X2Y118`, `SLICE_X0Y103`, and `SLICE_X0Y108` depending on
seed/variant. The `YPCB pre-place BEL locks: applied=...` log line is therefore
not sufficient evidence that final placement matches the requested BELs.

A seed3-derived narrow IDELAY lock file was generated for the 10 `CNTVALUEIN`
leaf LUTs and 2 `LD` source FFs. Locking all 12 cells, and then locking only the
10 `CNTVALUEIN` LUTs, both caused nextpnr-xilinx to abort after reporting that
all pre-place locks were applied:

```text
YPCB pre-place BEL locks: applied=10 missing=0 ...
Info: Placed 391 cells based on constraints.
terminate called after throwing an instance of 'std::out_of_range'
what(): unordered_map::at
```

So the absolute-BEL-lock approach is currently blocked for these synthesized
IDELAY-control LUTs by nextpnr-xilinx behavior. The next practical constraint
experiment should avoid exact BEL locks and instead try a softer region/site
locality constraint if the Python API supports it, or fix the pre-place locking
path upstream before relying on BEL locks as a deterministic solution.

## Hardware lock validation: 2026-05-27

The nextpnr BEL-lock crash was fixed by binding constrained macro children for fixed roots in `common/placer_heap.cc`, then carried into this repo as `patches/nextpnr-xilinx-heap-fixed-constrained-children.patch`. With that patch, absolute BEL lock experiments can complete P&R and bitstream generation.

Hardware matrix from `artifacts/hardware/idelay_lock_hardware_matrix.json`:

| Experiment | Seed | Result | Calibration state | Wrong reads | Notes |
|---|---:|---|---:|---:|---|
| baseline | 3 | pass | 23 | 0 | current unmodified control still passes |
| baseline | 5 | pass | 23 | 0 | current unmodified control still passes |
| CNTVALUEIN-only locks | 1 | pass | 23 | 0 | rescued known failing seed |
| CNTVALUEIN-only locks | 2 | pass | 23 | 0 | rescued known failing seed |
| CNTVALUEIN-only locks | 3 | fail | 17 | 1 | lock perturbation causes later BIST/calibration failure |
| CNTVALUEIN-only locks | 4 | pass | 23 | 0 | unaffected passing seed |
| CNTVALUEIN-only locks | 5 | fail | 0 | 0 | lock perturbation causes startup/calibration failure |
| CNTVALUEIN + LD-parent locks | 3 | fail | 0 | 0 | adding LD parent placement does not rescue seed 3 |
| CNTVALUEIN + LD-parent locks | 5 | pass | 23 | 0 | adding LD parent placement rescues seed 5 |

Conclusion: the SDF-derived CNTVALUEIN correlate is real enough to rescue seeds 1 and 2, but absolute locks copied from one passing placement are not yet a universal solution. They perturb the global placement/routing enough to break seed 3, even though current baseline seed 3 passes. The actionable direction is not to freeze isolated leaf LUT BELs as a final constraint. Instead, derive a bounded placement/floorplan rule around the whole IDELAY programming/startup cone, and add metrics for placement perturbation around reset, IDELAYCTRL ready/reset, LD/CE/INC, and calibration state-0 release paths.

A second tool finding matters: LD source FFs are constrained children of packed LUT/FF macros. Locking the FF child directly does not hold. The lock extractor now emits LD parent LUT locks and records the child FF source as metadata.


## Seed3 lock-damage SDF comparison: 2026-05-27

The decisive comparison is now `baseline seed3 pass` versus the two lock-perturbed seed3 failures, not original pass/fail seeds. The focused artifacts are under `artifacts/sdf-comparisons/seed3-lock-damage/` and were generated by `scripts/compare_seed3_lock_damage.py`.

Both lock experiments applied exactly as intended:

| Variant | Lock cells at expected BEL | Lock cells still matching baseline BEL |
|---|---:|---:|
| CNTVALUEIN-only seed3 fail | 10/10 | 10/10 |
| CNTVALUEIN + LD-parent seed3 fail | 12/12 | 12/12 |

That means the seed3 failures are not caused by the lock files putting the selected cells in the wrong place. The locks are copied from the passing seed3 placement and still match it. The failures come from collateral placement/routing changes introduced by constraining those cells.

Filtered SDF results use exact same-seed destination keys and exclude static `PACKER_GND/VCC` edges from the primary dynamic metrics:

| Variant | Family | Dynamic common paths | Median delta | P95 delta | Max delta | Paths >= +500 ps |
|---|---|---:|---:|---:|---:|---:|
| CNTVALUEIN-only seed3 fail | IDELAY programming | 108 | +122.5 ps | +755 ps | +824 ps | 25 |
| CNTVALUEIN-only seed3 fail | read/BIST state-17 | 18 | -97.5 ps | +330 ps | +330 ps | 0 |
| CNTVALUEIN-only seed3 fail | DQ/DQS input and IDELAY pins | 392 | 0 ps | +534 ps | +824 ps | 25 |
| CNTVALUEIN+LD seed3 fail | IDELAY programming | 108 | -209.5 ps | +296 ps | +464 ps | 0 |
| CNTVALUEIN+LD seed3 fail | read/BIST state-17 | 18 | -667.5 ps | -490 ps | -480 ps | 0 |
| CNTVALUEIN+LD seed3 fail | DQ/DQS input and IDELAY pins | 392 | 0 ps | +25 ps | +464 ps | 0 |

Interpretation:

- The CNTVALUEIN-only seed3 state-17 failure still has a credible SDF signature: dynamic IDELAY programming paths to IDELAYE2 CNTVALUEIN/LD and related DQ/DQS IDELAY pins are slower by roughly 0.5-0.8 ns on a large subset of paths. That is consistent with the earlier pass/fail population correlate and remains the best causal candidate for the state-17 wrong-read failure.
- The CNTVALUEIN+LD seed3 state-0 failure does not show the same dynamic SDF separation. IDELAY programming is not worse by the previous threshold, read/BIST paths are mostly faster, and the explicit IDELAYCTRL reset/RDY paths visible in SDF are not slower. This points away from simply adding more LD/CE/INC BEL locks as the next step.
- Placement movement is large in the read/calibration bookkeeping cone even when dynamic SDF paths do not get slower: `dqs_start_index*`, `dqs_start_index_stored*`, `stage2_bank_d`, `stage2_row_d`, read-pipe muxes, and BIST counters move by up to 27 tiles for CNTVALUEIN-only and 51 tiles for CNTVALUEIN+LD. The PHY reset-release counter LUTs also move, by 26 tiles and 17 tiles respectively.
- For the CNTVALUEIN+LD state-0 failure, SDF is not giving a clean dynamic-delay explanation. The likely missing surfaces are asynchronous reset recovery/removal, reset pulse/IDELAYCTRL analog readiness margin, clock-start ordering, or openXC7/nextpnr/prjxray modeling gaps around IDELAYCTRL/IOLOGIC behavior. This is exactly the case where SDF says "do not blindly add more absolute locks".

Actionable next constraint direction:

1. Do not extend the seed3 absolute BEL-lock set directly to CE/INC/reset. The full-lock seed3 result already shows that exact locks can preserve selected cells while damaging the surrounding implementation.
2. Convert the useful CNTVALUEIN evidence into a region/floorplan experiment: keep the IDELAY programming cone near the byte-lane IO/IDELAY columns and near its fanout, but avoid freezing every leaf BEL.
3. For state-0 failures, constrain and instrument the whole startup cone as a unit: IDELAYCTRL site/refclk/reset, `delay_before_release_reset`, `sync_rst`, controller `sync_rst_controller`, and the state-0 release into `state_calibrate`. The current SDF does not prove a dynamic-delay violation there, so the next experiment needs placement locality plus hardware observability, not just more SDF ranking.
4. Keep the comparator exact-key and constant-edge-filtered. The raw SDF diff is misleading here because static `PACKER_GND/VCC` edges and over-normalized `$abc` names can dominate the largest deltas without representing dynamic timing evidence.

## Instrumented seed3 lock hardware matrix: 2026-05-27

Artifacts:

- `artifacts/hardware/instrumented_seed3_lock_hardware_matrix.csv`
- `artifacts/hardware/instrumented_seed3_lock_hardware_matrix.json`
- raw runs:
  - `artifacts/hardware/instrumented-seed3-baseline.json`
  - `artifacts/hardware/instrumented-seed3-idelay-control-locked.json`
  - `artifacts/hardware/instrumented-seed3-idelay-control-full-locked.json`

Results:

| variant | pass | state | instruction | wrong reads | key sticky evidence |
| --- | --- | ---: | ---: | ---: | --- |
| baseline seed3 instrumented | yes | 23 | 22 | 0 | no reset reassertion, no tap mismatch |
| CNTVALUEIN-only lock instrumented | yes | 23 | 22 | 0 | no reset reassertion, no tap mismatch |
| CNTVALUEIN+LD-parent lock instrumented | no | 0 | 2 | 0 | reached state 13 gate, entered calibration, returned to IDLE, `reset_from_calibrate_ever=1`, sync/PHY reset reasserted, no tap mismatch |

Interpretation:

- The instrumentation did not break baseline seed3.
- The regenerated CNTVALUEIN-only lock no longer reproduces the earlier state-17 BIST failure. This means the old CNTVALUEIN-only failure is placement-sensitive enough that the debug payload / resynthesis moved it out of the failing margin.
- The CNTVALUEIN+LD-parent lock still reproduces a calibration-startup failure, but the new evidence separates it from IDELAY programming corruption: `CNTVALUEOUT` matches the loaded taps and both data/DQS mismatch masks are zero.
- The failing CNTVALUEIN+LD-parent bitstream reached the state-0 ready gate and left IDLE at least once, then asserted `reset_from_calibrate` and returned to IDLE while the reset ROM was back at instruction 2. That points at a calibration algorithm abort/reset path, not a BIST read-data failure and not an IDELAY tap-load failure.

Next targeted instrumentation:

Add a small calibration-abort reason code captured at each `reset_from_calibrate <= 1` site. The two current reset sites are in `ANALYZE_DATA` and `CHECK_STARTING_DATA`; capture reason, lane, `start_index_check`, `lane_write_dq_late`, `lane_read_dq_early`, `dq_target_index[lane]`, and `data_start_index[lane]`. This will distinguish whether the LD lock damages write/read alignment assumptions during `ANALYZE_DATA` or causes the `CHECK_STARTING_DATA` search to exhaust its valid start-index range.




## Causality and Solution Hypothesis Ledger

The experiment is not trying to prove that a seed number is good or bad. The seed is only a sampling mechanism that produces different placed/routed implementations from the same requested design. The explanatory variable we care about is a narrow SDF/JSON signature tied to specific cells, pins, locations, routes, or timing families. Hardware calibration plus BIST is the fast accept/reject test for each implementation.

Use two separate tables:

1. Cause/effect hypotheses: a proposed physical or timing signature in SDF/JSON that predicts hardware pass/fail.
2. Solution hypotheses: a proposed RTL, constraint, floorplan, tool-option, or physical-lock change that should remove the bad signature and make hardware pass.

A solution hypothesis is not allowed to become the conclusion until it changes the SDF/JSON signature in the intended direction and improves hardware pass/fail across the same RTL/debug variant matrix.

Artifacts:

- `artifacts/hardware/ddr3_hypothesis_ledger.csv`
- `artifacts/hardware/ddr3_hypothesis_ledger.json`

Current cause/effect hypotheses:

| ID | status | proposed SDF/JSON cause | hardware signature | narrow cells/paths | current evidence | next falsification test |
| --- | --- | --- | --- | --- | --- | --- |
| CE-001 | active, partially supported | IDELAY programming/control paths to DQ/DQS IDELAYE2 pins are too slow or skewed in failing implementations | state-17 wrong-read or calibration/BIST failure after startup | DQ/DQS IDELAYE2 `CNTVALUEIN`, `LD`, related control fan-in | pass/fail population produced strict fail-slower separators; seed3 CNTVALUEIN-only lock-damage comparison showed IDELAY programming p95 +755 ps and 25 dynamic paths >= +500 ps | same RTL/debug variant matrix over more seeds; failing rows must separate on exact-key IDELAY programming metrics, not raw seed |
| CE-002 | active, strengthened by baseline population | data-alignment search in `CHECK_STARTING_DATA` runs out of valid start-index candidates | first abort reason 2, mostly lane 0, `start_index_check=48`, `dq_target_index=33`, no tap mismatch | `dq_target_index`, `data_start_index`, `start_index_check`, `lane_write_dq_late`, `lane_read_dq_early`, read sample classification cone | 30-seed baseline/no-lock sweep produced 7 reason-2 failures and 22 clean passes; exact-abort seed3 CNTVALUEIN+LD-parent row also captures reason 2 with the same `start_index_check=48`, `dq_target_index=33`, `data_start_index=0`, write-late=1, read-early=0, and no tap mismatch | run SDF feature extraction on the 30-row baseline sweep and rank exact-key metrics for reason-2 failures versus clean passes |
| CE-003 | active, narrowed | startup/reset/IDELAYCTRL readiness ordering or reset recovery/removal margin causes true state-0 returns | state 0 without a captured calibration abort | IDELAYCTRL site/refclk/reset/RDY, `delay_before_release_reset`, `sync_rst`, `sync_rst_controller`, state-0 release cone | seed1/seed2 original pre-abort failures and payload-v2 CNTVALUEIN+LD seed3 failure matched this family before exact abort capture | in the 30-seed exact-abort baseline sweep, 7 apparent state-0 failures actually have first abort reason 2; only rows without an abort snapshot should be used for CE-003 |

Current solution hypotheses:

| ID | status | proposed fix | intended SDF/JSON change | current result | next test |
| --- | --- | --- | --- | --- | --- |
| SO-001 | diagnostic only | absolute BEL locks for selected CNTVALUEIN and LD-parent cells | force selected IDELAY programming leaf cells to good-reference BELs | mixed: rescues some rows, damages or changes others, passes reduced-v3 seed3 locks | keep as a perturbation tool; do not promote to final fix unless it passes a broad matrix and has a clear narrowed signature |
| SO-002 | proposed | soft floorplan/region constraint for the whole IDELAY programming plus calibration bookkeeping cone | reduce distance/skew for the cone without freezing every leaf BEL | not yet tested | define regions around byte-lane IO/IDELAY columns and compare exact-key metrics before hardware |
| SO-003 | proposed | RTL calibration robustness in `CHECK_STARTING_DATA` | tolerate or recover from narrow alignment windows rather than relying on one fragile placement-dependent outcome | not yet tested | first capture lane-0 window bounds and last accepted/rejected start-index candidates |
| SO-004 | proposed | explicit generated-clock/reset/CDC constraints and startup reset handling | remove unconstrained or under-modeled startup ordering sensitivity | not yet tested as a standalone fix | isolate state-0 failures and verify reset/IDELAYCTRL-ready timing/ordering observability |

## Payload-v3 abort instrumentation: 2026-05-27

Artifacts:

- canonical matrix: `artifacts/hardware/ddr3_causality_matrix.csv`
- canonical matrix JSON: `artifacts/hardware/ddr3_causality_matrix.json`
- raw runs:
  - `artifacts/hardware/v3-seed3-baseline.json`
  - `artifacts/hardware/v3-min-seed3-baseline.json`
  - `artifacts/hardware/v3-min-seed3-baseline-rerun.json`
  - `artifacts/hardware/v3-min-seed3-idelay-control-locked.json`
  - `artifacts/hardware/v3-min-seed3-idelay-control-full-locked.json`

Implementation:

- `rtl/ddr3_controller.v` now captures the first calibration-abort decision into `o_debug_calib_abort[63:0]` at the actual `reset_from_calibrate <= 1` sites, rather than inferring it one cycle later.
- The captured fields are: seen bit, reason code, lane, `state_calibrate`, reset-ROM `instruction_address`, `start_index_check`, `lane_write_dq_late`, `lane_read_dq_early`, `dq_target_index[lane]`, and `data_start_index[lane]`.
- Reason code `1` is `ANALYZE_DATA`, reason code `2` is `CHECK_STARTING_DATA`, and reason code `15` is any unexpected `reset_from_calibrate` state.
- The YPCB JTAG debug payload is now version `3`, and the board-test decoder emits an `abort_debug` object.

Hardware matrix slice:

| experiment | RTL/debug variant | locks | pass | state | instruction | wrong reads | abort evidence |
| --- | --- | --- | --- | ---: | ---: | ---: | --- |
| `v3-seed3-baseline` | payload-v3 wide 128-bit abort RTL | none | no | 4 | 13 | 0 | no abort captured |
| `v3-min-seed3-baseline` | payload-v3 reduced 64-bit abort RTL | none | no | 17 | 22 | 1 | reason 2, lane 0, `dq_target_index=35`, `data_start_index=0`, write-late=1, read-early=0 |
| `v3-min-seed3-baseline-rerun` | payload-v3 reduced 64-bit abort RTL | none | no | 0 | 2 | 2 | same first abort: reason 2, lane 0, `dq_target_index=35` |
| `v3-min-seed3-idelay-control-locked` | payload-v3 reduced 64-bit abort RTL | CNTVALUEIN-only | yes | 23 | 22 | 0 | no abort captured |
| `v3-min-seed3-idelay-control-full-locked` | payload-v3 reduced 64-bit abort RTL | CNTVALUEIN + LD-parent | yes | 23 | 22 | 0 | no abort captured |

Interpretation:

- The requested abort observer works: when calibration resets, it identifies the first failing calibration assumption rather than only the final state after the reset sequence has restarted.
- The wide payload was too intrusive for this design point. It made seed3 fail early in DQS calibration state 4 before any data-calibration abort was captured.
- The reduced payload is still placement/timing intrusive enough to turn the previously passing seed3 baseline into a deterministic failure, but it gives useful causality: the first captured abort is `CHECK_STARTING_DATA` exhaustion on lane 0 with `dq_target_index[0]=35` and `data_start_index[0]=0`.
- That signature is not an IDELAY tap-load failure. In the reduced payload-v3 runs, the data and DQS tap mismatch masks stay zero. The failing assumption is the controller's read/write alignment search, after the tap values were loaded as intended.
- The regenerated CNTVALUEIN-only and CNTVALUEIN+LD-parent lock variants pass under the same reduced observer. This means the lock-induced placement change can move the instrumented design back into a passing margin. It also means these absolute locks are not a universal fix by themselves; they are a lever that changes placement and routing enough to expose or hide the fragile margin.

Current causality model:

1. The original pass/fail population and the CNTVALUEIN-only seed3 lock-damage SDF still point to IDELAY programming/control delay as a real correlate for state-17 wrong-read failures.
2. The payload-v3 abort evidence exposes a second failure mode: lane-0 data-calibration search exhaustion in `CHECK_STARTING_DATA`, with no observed tap-load mismatch.
3. Absolute BEL locks copied from one good placement are therefore diagnostic, not final. They can rescue some seeds, damage others, and even rescue an observer-perturbed seed by changing collateral placement.
4. The fix should be promoted upward only after it survives the matrix: first algorithmic robustness and explicit observability, then soft physical locality constraints around whole cones, then narrow BEL locks only for cells proven to require exact sites.

Next experiment direction:

- Keep payload-v3 reduced abort capture; do not reintroduce the wide optional datapath fields.
- Build a larger seed matrix with the reduced observer for baseline, CNTVALUEIN-only locks, CNTVALUEIN+LD-parent locks, and a soft-region/floorplan variant.
- For every failing run, bucket by abort reason/state before looking at SDF. Compare state-17 wrong-read failures separately from `CHECK_STARTING_DATA` aborts and state-0 startup aborts.
- Add the next observer only around the lane-0 `CHECK_STARTING_DATA` decision: capture the candidate window bounds and the last accepted/rejected `start_index_check`. That should explain why `dq_target_index=35` cannot find a valid `data_start_index` in the failing placement.
- Translate fixes in this order: calibration search robustness in RTL, generated-clock/reset/CDC constraints, soft region constraints for IDELAY programming plus calibration bookkeeping, and only then minimal LOC/BEL locks if a specific primitive/site remains causal across the matrix.

## Exact-Abort Seed3 Lock Matrix: 2026-05-27

This is the first clean same-RTL matrix after moving the abort snapshot to the actual `reset_from_calibrate <= 1` decision sites.

Setup commit sequence:

- `7276a90` adds exact calibration-abort observability.
- `9bbfaba` regenerates the seed3 CNTVALUEIN and CNTVALUEIN+LD-parent lock files from the exact-abort seed3 baseline placement.

Artifacts:

- hardware slice: `artifacts/hardware/exact_abort_seed3_lock_matrix.csv`
- canonical matrix: `artifacts/hardware/ddr3_causality_matrix.csv`
- hypothesis ledger: `artifacts/hardware/ddr3_hypothesis_ledger.csv`
- focused SDF metrics: `artifacts/sdf-metrics/exact-abort-seed3-lock-matrix/`
- baseline SDF/JSON: `result-cvc-sdf-seed3-exact-abort-baseline/`
- CNTVALUEIN-lock SDF/JSON: `result-cvc-sdf-seed3-exact-abort-idelay-control-locked/`
- CNTVALUEIN+LD-lock SDF/JSON: `result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/`

Hardware results:

| RTL/debug variant | seed | locks | pass | final state | BIST wrong reads | first abort |
| --- | ---: | --- | --- | ---: | ---: | --- |
| exact-abort | 3 | none | yes | 23 | 0 | none |
| exact-abort | 3 | CNTVALUEIN-only | yes | 23 | 0 | none |
| exact-abort | 3 | CNTVALUEIN + LD-parent | no | 0 | 0 | reason 2, lane 0, `CHECK_STARTING_DATA`, `start_index_check=48`, `dq_target_index=33`, `data_start_index=0`, write-late=1, read-early=0 |

Important observations:

- The exact-abort no-lock baseline passes. That means the exact snapshot implementation is less perturbing than the earlier reduced-v3 baseline failure.
- CNTVALUEIN-only regenerated locks also pass.
- CNTVALUEIN+LD-parent regenerated locks fail and now give an exact abort-site snapshot: `CHECK_STARTING_DATA` search exhaustion on lane 0, with no data or DQS tap mismatch.
- Therefore the current same-RTL cause/effect evidence is not “seed3 is bad” and not “all absolute locks help”. It is: adding the LD-parent lock perturbation changes the exact placed/routed implementation enough to make lane-0 data-alignment calibration exhaust its search.

Focused SDF metrics for the pass/pass/fail matrix show strict fail-slower candidates in the failing CNTVALUEIN+LD row:

| metric family | endpoint | fail-pass median delta | strict separation |
| --- | --- | ---: | ---: |
| DQS IDELAY CNTVALUEIN | lane1 dqs1 ctrl=4 | +514 ps | +287 ps |
| DQS IDELAY CNTVALUEIN | lane0 dqs0 ctrl=4 | +467 ps | +75 ps |
| clocking | all endpoints | +464.5 ps | +60 ps |
| reset release | all endpoints | +406 ps | +406 ps |
| DQ IDELAY CNTVALUEIN | lane1 dq9 ctrl=3 | +408 ps | +347 ps |
| IDELAY LD | lane0 dqs0 | +347 ps | +9 ps |

Focused rank-path artifact: `artifacts/sdf-rankings/exact-abort-seed3-lock-matrix-focused/`.

The rank-path check validates the exact source/sink edge behind each selected semantic metric. Because these rows are direct SDF interconnect edges, `rank-paths` usually reports one graph edge rather than decomposing a route into lower-level wire fragments. The direct SDF delay remains the cross-sample statistic; the rank output is the proof of which endpoint pair produced that statistic.

| ranked candidate | baseline pass | CNTVALUEIN-only pass | CNTVALUEIN+LD fail | note |
| --- | ---: | ---: | ---: | --- |
| reset_release all | 584 ps | 584 ps | 990 ps | clean strict separator in this matrix |
| DQ IDELAY CNTVALUEIN lane1 dq9 ctrl=3 | 1396 ps | 1274 ps | 1743 ps | clean strict separator |
| DQ IDELAY CNTVALUEIN lane1 dq15 ctrl=3 | 1315 ps | 1194 ps | 1652 ps | clean strict separator |
| DQ IOLOGIC lane0 dq2 | 2069 ps | 2082 ps | 2365 ps | clean lane-0 datapath separator |
| DQS IDELAY CNTVALUEIN lane0 dqs0 ctrl=4 | 1282 ps | 2066 ps | 2141 ps | weak as a single cause because one passing row is close |
| IDELAY LD lane0 dqs0 | 2046 ps | 1370 ps | 2055 ps | weak as a single cause because baseline pass is close |

Interpretation:

- CE-002 is strengthened as a concrete hardware failure mode: the failing bitstream aborts exactly in lane-0 `CHECK_STARTING_DATA`, and the tap mismatch monitors stay clean.
- CE-001 remains relevant because the failing same-RTL row has slower IDELAY programming/control candidates, especially DQS CNTVALUEIN ctrl=4 and one LD endpoint. This does not yet prove direct tap-load corruption; it may be margin loss that later appears as calibration search exhaustion.
- CE-003 stays secondary for this row. Reset-release is slower by a strict +406 ps, and reset reassertion history is set after the abort, but the exact first cause observed by RTL is reason 2, not an unexplained startup state-0 return.
- SO-001 is again rejected as a final solution. CNTVALUEIN-only locks pass, but CNTVALUEIN+LD-parent locks fail under the same RTL/debug variant.

Next focused test:

Compare the exact-abort baseline pass against the exact-abort CNTVALUEIN+LD fail around the actual lane-0 `CHECK_STARTING_DATA` decision cone, not the whole design. The next observer should capture only candidate-match history and final comparison operands: which `start_index_check` values matched, final `read_lane_data_shifted`, final `write_pattern[31:0]`, and the lane-0 flags already captured here.

### Statistical Causality Phase

A statistical pass/fail analysis is the right next scale-up, but it must be treated as a designed experiment rather than a raw full-SDF mining exercise. The unit of observation is a committed bitstream experiment row, not a seed. Each row needs these covariates: RTL/debug variant, observer payload, lock set, constraint variant, seed, tool revisions, JSON/SDF/bitstream hashes, hardware pass/fail, final calibration state, abort reason, lane, BIST status, and any board/environment notes.

The derived feature table should be built from normalized DDR semantic metrics, not raw net names. Start with these feature families: DQ/DQS IDELAY `CNTVALUEIN` direct max and bus skew, IDELAY `LD/CE/INC` direct max and fanout spread, DQ/DQS IOLOGIC lane max and lane spread, reset-release max/spread, IDELAYCTRL/RDY paths, and generated-clock distribution to PHY endpoints. Keep exact source/sink pins as evidence, but train/correlate on stable semantic keys.

Analysis sequence:

1. Discovery: run many no-lock and low-observer seeds to estimate natural pass/fail variation. Rank features by strict separation, AUC, effect size, and bootstrap stability.
2. Stratified comparison: analyze variants separately first, then fit models with RTL/debug variant, observer payload, and lock set as covariates. Do not pool all variants blindly because instrumentation and locks are intentional interventions.
3. Multifeature check: use small regularized/logistic or tree-style models only after univariate ranking. The goal is to detect combined margins, such as `reset_release` plus lane-0 DQ IOLOGIC plus IDELAY programming, not to produce a black-box predictor.
4. Intervention: turn the strongest statistical cause hypothesis into one constraint or RTL change at a time, then test fresh seeds. A hypothesis becomes useful only if moving the feature moves the hardware pass rate on held-out seeds.
5. Promotion: solution hypotheses should prefer high-level fixes in this order: RTL robustness or calibration algorithm tolerance, clock/reset/CDC constraints, relative/soft floorplanning, targeted placement constraints, then absolute BEL locks only as diagnostics or last resort.

The key causality rule is: correlation proposes a cause/effect hypothesis; only an intervention validates it. If a delay metric predicts failure but constraining it does not improve held-out hardware outcomes, it is probably a proxy for another physical or tool-model effect.

Implemented statistical tooling:

- `scripts/uberddr3_build_sdf_feature_table.py` joins committed hardware experiment rows with one or more `artifacts/sdf-metrics/*/semantic_metrics.csv` directories. It emits `features_long.csv` for audit/ranking and `features_wide.csv` for modeling.
- `scripts/uberddr3_statistical_sdf_analysis.py` ranks semantic features by pass/fail separation, AUC, Cliff's delta, and strict separation. It also writes pass/fail strata summaries so seed, RTL/debug variant, observer payload, and lock set remain visible.

First committed statistical artifact:

- feature table: `artifacts/statistical-sdf/exact-abort-seed3-lock-matrix/`
- analysis: `artifacts/statistical-sdf/exact-abort-seed3-lock-matrix/analysis/`

This first artifact is only a pipeline smoke test: it has 3 experiments, 2 pass and 1 fail, all seed 3. It correctly reproduces the focused exact-abort candidates (`reset_release`, `idelay_data_cntvaluein`, DQS `CNTVALUEIN`, lane-0 DQ IOLOGIC), but it is not enough for statistical confidence or multifeature modeling. The next real data collection target is at least 3 pass and 3 fail rows per stratum before trusting pairwise/multifeature rankings.

Seed sweep setup:

- `flake.nix` exposes seed-based package attrs for seeds `1..30` through a shared `seedMatrix` binding.
- The first collection stratum should be baseline/no-lock exact-abort RTL across seeds `1..30`; diagnostic lock strata should be analyzed separately.

### Baseline No-Lock Seed 1-30 Hardware Sweep: 2026-05-27

Artifacts:

- build manifest: `artifacts/builds/baseline-no-lock-seed-1-30/manifest.csv`
- hardware run directory: `artifacts/hardware/baseline-no-lock-seed-1-30/`
- flattened hardware slice: `artifacts/hardware/baseline_no_lock_seed_1_30.csv`
- canonical matrix: `artifacts/hardware/ddr3_causality_matrix.csv`

Hardware results:

| run group | seeds tested | pass | fail | failing seeds | dominant first abort |
| --- | ---: | ---: | ---: | --- | --- |
| baseline/no-lock exact-abort RTL | 30 | 22 | 8 | 2, 6, 11, 12, 16, 20, 23, 27 | reason 2, `CHECK_STARTING_DATA` search exhausted |

Failure buckets:

| bucket | count | seeds | signature |
| --- | ---: | --- | --- |
| `CHECK_STARTING_DATA` exhaustion | 7 | 2, 6, 11, 12, 20, 23, 27 | `abort_state=14`, `abort_instruction=22`, `start_index_check=48`, `dq_target_index=33`, `data_start_index=0`, write-late=1, read-early=0, no IDELAY tap mismatch |
| early calibration stall/no abort snapshot | 1 | 16 | final `state_calibrate=3`, `instruction_address=13`, no captured abort, no wrong reads |

Interpretation:

- This is the first useful baseline population for statistical SDF work: 22 clean pass rows and 8 fail rows under the same RTL/debug payload, no locks, and seeds 1..30.
- The dominant failure is not simply “state 0”. Seven rows return to visible state 0 after `reset_from_calibrate`, but the exact abort snapshot says the first failure was reason 2 in `CHECK_STARTING_DATA`.
- The repeated reason-2 constants are now strong CE-002 evidence: `start_index_check=48`, `dq_target_index=33`, `data_start_index=0`, write-late=1, read-early=0, and clean IDELAY tap monitors.
- CE-003 should be tested only on rows that truly lack an abort snapshot. In this sweep, seed 16 is the only failing row without captured abort evidence.

Immediate next analysis:

Run the semantic SDF feature extractor on this 30-row stratum and compare:

1. all fails versus all passes,
2. reason-2 fails versus passes,
3. seed 16 separately versus the pass population.

The highest-value features to rank first are the previous IDELAY programming/control metrics, lane-0/lane-1 DQ IOLOGIC delay/spread, reset-release max/spread, and any metrics touching the `CHECK_STARTING_DATA` decision cone.

### Baseline No-Lock Repeatability Check: 2026-05-27

Artifacts:

- repeatability directory: `artifacts/hardware/baseline-no-lock-seed-1-30-repeatability/`
- observations: `artifacts/hardware/baseline-no-lock-seed-1-30-repeatability/repeatability_observations.csv`
- per-seed summary: `artifacts/hardware/baseline-no-lock-seed-1-30-repeatability/repeatability_summary.csv`

Method:

- Trial 1 is the original committed baseline/no-lock sweep over seeds 1..30.
- Trial 2 reprogrammed the same 30 bitstreams and used a longer board-test window: `--poll-count 300 --poll-interval 0.1`, about 30 seconds after programming.
- A third trial was started and then stopped at user request after five completed seeds. It is preserved only as partial audit data and is not used for the full-matrix determinism conclusion.

Result:

| comparison | seeds | pass/fail flips | stable passes | stable reason-2 failures | other stable failures |
| --- | ---: | ---: | ---: | ---: | ---: |
| trial 1 vs trial 2 | 30 | 0 | 22 | 7 | 1 |

Interpretation:

- Within this same board/session and repeated reprogramming method, the baseline/no-lock pass/fail labels are stable enough to use as binary labels for the next SDF correlation pass.
- The longer 30-second poll window did not rescue any failing bitstream, so the earlier failures were not just too-short test timeouts.
- The seven reason-2 failures repeated the same `CHECK_STARTING_DATA` exhaustion family, including `start_index_check=48` and `dq_target_index=33`.
- Seed 16 remained a no-abort early calibration failure, but its final visible state changed from 3 to 2. Treat seed 16 as a separate failure bucket rather than pooling it into reason-2 failures.
- This does not prove pass/fail determinism across cold power cycles, temperature, voltage, or board-to-board variation. If a future repeatability sweep shows flips, the analysis must switch from one binary label per bitstream to pass-rate/probabilistic labels per bitstream.

Statistical-analysis rule:

If a bitstream's pass/fail result is nondeterministic, the SDF analysis is not meaningless, but a single label is invalid. The row should become `(bitstream, n_trials, n_pass, failure_modes)` and the model should correlate SDF/JSON features with pass probability or failure-mode probability. For the current same-session baseline/no-lock data, no such relabeling is needed because the completed repeat trial had zero pass/fail flips.

### Baseline No-Lock Statistical SDF Analysis: 2026-05-27

Artifacts:

- SDF metrics: `artifacts/sdf-metrics/baseline-no-lock-seed-1-30/`
- all-fail feature table and analysis: `artifacts/statistical-sdf/baseline-no-lock-seed-1-30/`
- reason-2-only feature table and analysis: `artifacts/statistical-sdf/baseline-no-lock-seed-1-30-reason2/`
- seed16-only feature table and analysis: `artifacts/statistical-sdf/baseline-no-lock-seed-1-30-seed16/`
- filtered hardware slices: `artifacts/hardware/baseline_no_lock_seed_1_30_reason2_vs_pass.csv`, `artifacts/hardware/baseline_no_lock_seed_1_30_seed16_vs_pass.csv`
- selected audit values: `artifacts/statistical-sdf/baseline-no-lock-seed-1-30/analysis/selected_feature_values.csv`

Population results:

| comparison | rows | pass/fail | strict univariate separators | strongest univariate evidence | strongest two-feature evidence |
| --- | ---: | ---: | ---: | --- | --- |
| all baseline fails vs passes | 30 | 22/8 | 0 | DQS lane0 `CNTVALUEIN` bus skew/lane spread, fail-higher, AUC 0.75, median +305 ps | signed DQS lane0 `CNTVALUEIN` skew plus lane1 DQ15 `CNTVALUEIN` skew, AUC 0.903 |
| reason-2 fails vs passes | 29 | 22/7 | 0 | lane0 DQ `CNTVALUEIN` ctrl1 fanout spread, fail-lower, AUC 0.786; DQS lane0 `CNTVALUEIN` bus skew, fail-higher, AUC 0.721, median +298 ps | signed DQS lane0 `CNTVALUEIN` skew plus lane1 DQ15 `CNTVALUEIN` skew, AUC 0.903; lane0 ctrl4 fanout spread plus lane0 dq6 LD, AUC 0.883 |
| seed16 vs passes | 23 | 22/1 | 9 | IDELAYCTRL direct/lane spread fail-higher, and several DQ `CNTVALUEIN` ctrl0 paths fail-lower | skipped because only one failing row |

Interpretation:

- The 30-row baseline population does not support a single deterministic univariate SDF threshold for the dominant `CHECK_STARTING_DATA` failures. This weakens any theory that one isolated endpoint delay is the whole cause.
- The useful reason-2 signal is a combined-margin hypothesis around IDELAY programming skew and byte-lane alignment, not a simple "all failing paths are slower" hypothesis. DQS lane0 `CNTVALUEIN` bus skew is higher in failures, while several DQ `CNTVALUEIN` fanout/skew and LD metrics are lower in failures. The signs matter because the calibration failure is an alignment/search-window failure, so relative skew can be more important than absolute max delay.
- CE-001 remains active, but should be stated as IDELAY programming/control skew or placement-derived alignment margin, not just slow IDELAY programming paths.
- CE-002 is strengthened by the hardware labels and moderately supported by the SDF population: the dominant hardware failure is consistent and the top SDF features are in the DQS/DQ IDELAY programming families. However, the current SDF analysis does not yet prove the exact mechanism inside the `CHECK_STARTING_DATA` decision cone.
- Seed16 should stay in CE-003 as a separate startup/IDELAYCTRL bucket. Its strict separators are not population evidence because `n_fail=1`, but the IDELAYCTRL fail-higher result is a good target for future startup-failure rows.
- The initial `idelay_ce_inc` query family produced zero dynamic entries for every seed. Do not treat that as a causal negative by itself; the pin coverage diagnostic below explains that CE/INC/REGRST exist in SDF but are constant-driven in the current RTL.

Next tests:

1. Use `rank-paths` or a focused exact-pin extractor on the top signed pair: DQS lane0 `CNTVALUEIN` bus skew and lane1 DQ15 `CNTVALUEIN` bus skew. Confirm the exact source/sink pins and final placed cells behind the semantic features.
2. Add a small observer for the `CHECK_STARTING_DATA` candidate window: accepted/rejected `start_index_check` values, last compared `read_lane_data_shifted`, and the write-pattern slice that drives `lane_write_dq_late` and `lane_read_dq_early`.
3. Design the first intervention as a relative/locality constraint or RTL tolerance change, not an absolute BEL-lock workaround. The intervention should intentionally move the signed SDF features toward the passing population and then be tested on held-out seeds.
4. Improve the SDF/JSON feature extractor for IDELAY CE/INC/RST and exact calibration-decision cells before concluding that the current 200-feature table has exhausted the relevant surfaces.


### Baseline No-Lock Derived Skew Analysis: 2026-05-27

Artifacts:

- skew derivation script: `scripts/uberddr3_derive_skew_features.py`
- all-fail skew feature table and analysis: `artifacts/statistical-sdf/baseline-no-lock-seed-1-30-skew/`
- reason-2-only skew feature table and analysis: `artifacts/statistical-sdf/baseline-no-lock-seed-1-30-reason2-skew/`
- seed16-only skew feature table and analysis: `artifacts/statistical-sdf/baseline-no-lock-seed-1-30-seed16-skew/`
- selected skew audit values: `artifacts/statistical-sdf/baseline-no-lock-seed-1-30-skew/analysis/selected_skew_feature_values.csv`
- IDELAY pin coverage diagnostic: `artifacts/sdf-diagnostics/baseline-seed1-idelay-pin-coverage/`

Skew-only results:

| comparison | rows | pass/fail | strict univariate separators | strongest univariate skew evidence | strongest two-feature skew evidence |
| --- | ---: | ---: | ---: | --- | --- |
| all baseline fails vs passes | 30 | 22/8 | 0 | `abs(dqs1 - dq14)` on `CNTVALUEIN3`, AUC 0.841, fail median +221 ps | `abs(dqs1 - dq14)` on `CNTVALUEIN3` plus signed lane1 DQS-vs-DQ bus-skew delta, AUC 0.938 |
| reason-2 fails vs passes | 29 | 22/7 | 0 | `abs(dqs1 - dq14)` on `CNTVALUEIN3`, AUC 0.825, fail median +184 ps | same feature plus signed lane1 DQS-vs-DQ bus-skew delta, AUC 0.948 |
| seed16 vs passes | 23 | 22/1 | 16 | lane1 IOLOGIC DQ range and multiple IDELAY skew terms strictly separate the single seed16 row | skipped because only one failing row |

Interpretation:

- Explicit skew features are more predictive than the previous absolute-delay features for the dominant reason-2 population. The best reason-2 pairwise score improved from about 0.90 in the raw semantic feature set to 0.948 in the derived skew set.
- The reason-2 population still has no strict univariate separator. The working model should remain "combined alignment margin" rather than "one bad skew threshold".
- The top skew features are not confined to the lane reported by the abort observer. Several strongest reason-2 features involve lane1 DQS/DQ skew even though six of seven reason-2 aborts report lane 0. Treat these as placement/alignment-margin signatures or proxies until exact source/sink and placement audits prove the physical interpretation.
- CE-001 and CE-002 should now be phrased as DQ/DQS IDELAY programming skew and byte-lane alignment margin. "Slow IDELAY programming path" is too narrow and loses the sign information that appears in the skew analysis.
- The current `idelay_ce_inc` zero-entry result is explained. A seed1 broad IDELAYE2 SDF query finds CE, INC, and REGRST interconnects, but they are all driven by `PACKER_GND_DRV` in this design and are filtered as static edges. LD and CNTVALUEIN remain the dynamic IDELAY programming surfaces in the current RTL.

Next tests:

1. Exact component audit: for the top skew pair, extract the exact source/sink pins and placed cells for DQS1 `CNTVALUEIN3`, DQ14 `CNTVALUEIN3`, and the lane1 DQS-vs-DQ bus-skew contributors.
2. Add nextpnr JSON placement features for the same components: source cell to sink IDELAY distance, DQS-vs-DQ placement asymmetry, lane0-vs-lane1 placement asymmetry, and whether the source LUTs cross byte-lane/clock-region boundaries.
3. Add the `CHECK_STARTING_DATA` candidate-window observer before changing RTL. The skew data predicts an alignment-margin problem, but it does not yet show which comparison or accepted-window boundary collapses.
4. Use held-out seeds only after the exact skew component/placement extractor is in place. More seed rows with incomplete skew provenance would improve prediction but not causality.



### CNTVALUEIN3 Exact Component Audit and Split Interventions: 2026-05-27

Purpose: split the strongest current skew hypothesis into two independent interventions.

| Experiment family | What changes | What stays fixed | Causality question |
| --- | --- | --- | --- |
| RTL stable-before-LD | `UBERDDR3_IDELAY_STABLE_BEFORE_LD` delays IDELAY `CNTVALUEIN` and `LD` together inside `ddr3_phy` | no placement locks | If CNTVALUEIN/LD sampling skew is causal, making CNTVALUEIN stable before LD should reduce or eliminate seed-dependent calibration failures without requiring exact BELs. |
| CNTVALUEIN3 skew lock | only the two seed3 source LUT BELs for data/dqs `i_controller_idelay_*_cntvaluein[3]` are locked | baseline RTL and constraints | If the exact `abs(dqs1 - dq14)` `CNTVALUEIN3` placement/skew feature is causal or a strong proxy, moving that metric toward the seed3-good placement should improve failing held-out seeds. |

New build targets:

- RTL variant: `ypcb-ddr3-{bitstream,nextpnr-json,cvc-sdf}-seed-N-idelay-stable-before-ld`
- Physical diagnostic: `ypcb-ddr3-{bitstream,nextpnr-json,cvc-sdf}-seed-N-cntvaluein3-skew-locked`

New artifacts/scripts:

- focused source/sink audit script: `scripts/uberddr3_cntvaluein3_skew_audit.py`
- targeted lock file: `example_demo/ypcb_00338_1p1/constraints/ypcb_00338_1p1_ddr3_cntvaluein3_skew_locks_seed3.json`
- seed2/seed3 baseline audit: `artifacts/sdf-diagnostics/cntvaluein3-dqs1-dq14-baseline-seed2-seed3/`

Preliminary exact audit:

| Row | Hardware | DQ14 CNTVALUEIN3 | DQS1 CNTVALUEIN3 | abs skew | source BEL delta | sink BEL delta |
| --- | --- | ---: | ---: | ---: | --- | --- |
| baseline seed2 | fail reason 2 | 1118 ps | 1825 ps | 707 ps | DQ14 `SLICE_X1Y58/B6LUT`, DQS1 `SLICE_X5Y75/A6LUT`, manhattan 21 | IDELAY manhattan 5 |
| baseline seed3 | pass | 1756 ps | 1809 ps | 53 ps | DQ14 `SLICE_X1Y72/A6LUT`, DQS1 `SLICE_X1Y75/B6LUT`, manhattan 3 | IDELAY manhattan 5 |

This is still a cause/effect hypothesis, not proof. The useful property is that the exact top SDF feature now maps to concrete nextpnr cells and BELs. The next proof step is intervention: build/program held-out failing seeds with each family independently, append those hardware rows to the causality matrix, and compare the post-intervention SDF/JSON audit rows against baseline.

## Split IDELAY Skew Interventions: 2026-05-27

This experiment separated two solution hypotheses that were previously conflated:

| Experiment | Seed | RTL/lock setting | Hardware result | Focused CNTVALUEIN3 audit | Interpretation |
| --- | ---: | --- | --- | --- | --- |
| `idelay-stable-before-ld-seed2` | 2 | PHY-local CNTVALUEIN/LD pipeline | pass | abs dqs1-dq14 = 184 ps; source manhattan = 2 | This RTL change can rescue seed2. |
| `idelay-stable-before-ld-seed3` | 3 | PHY-local CNTVALUEIN/LD pipeline | fail, reason 2 | abs dqs1-dq14 = 222 ps; source manhattan = 9 | The current RTL pipeline is not a complete fix; it fails with CHECK_STARTING_DATA exhaustion and tap mismatch. |
| `cntvaluein3-skew-locked-seed2` | 2 | current `phy_idelay_*_cntvaluein[3]` cells locked to original low-skew seed3 BELs | pass | abs dqs1-dq14 = 163 ps; source manhattan = 3 | The physical intervention rescues seed2. |
| `cntvaluein3-skew-locked-seed3` | 3 | same two-cell CNTVALUEIN3 lock | pass | abs dqs1-dq14 = 533 ps; source manhattan = 3 | The lock does not damage seed3, but absolute SDF skew alone is not the causal threshold. |

Important conclusion: the intervention result strengthens the physical/topology hypothesis, not the naive `abs(dqs1 - dq14) CNTVALUEIN3 must be below N ps` hypothesis. The locked seed3 row passes with a large SDF abs skew, while the stable-before-LD seed3 row fails with a smaller skew. The current best causal statement is narrower and more careful: placement/topology of the IDELAY CNTVALUEIN3 source cells, or a correlated unmodeled margin around that cone, matters enough that forcing the original good source BEL pair rescues the tested failing seed.

The RTL stable-before-LD idea remains plausible as a higher-level fix, but this implementation is incomplete. The failing seed3 row shows reason 2, lane 1, `start_index_check=48`, `dq_target_index=33`, data/DQS tap mismatch, and reset reassertion after calibration reset. If this path is pursued, it needs an explicit IDELAY load/readback handshake or delayed expected-tap bookkeeping, not just a blind pipeline of CNTVALUEIN and LD.

Next test: run the same two-cell CNTVALUEIN3 lock over a held-out seed set that includes several known baseline failures and passes. If the pass rate holds, derive a higher-level locality/floorplan constraint for the IDELAY programming source cells rather than promoting exact BEL locks as the final integration strategy.

## CNTVALUEIN3 Lock Held-Out Batch: 2026-05-28

The exact two-cell CNTVALUEIN3 lock was tested against remaining known baseline failures `6, 11, 12, 16, 20, 23, 27` and pass controls `1, 5, 28, 30`.

| Seed group | Seeds | Pass | Fail |
| --- | --- | ---: | ---: |
| baseline reason-2 failures | `6, 11, 12, 20, 23, 27` | 4 | 2 |
| baseline startup failure | `16` | 0 | 1 |
| baseline pass controls | `1, 5, 28, 30` | 2 | 2 |
| total | `1, 5, 6, 11, 12, 16, 20, 23, 27, 28, 30` | 6 | 5 |

Passing rows: `6, 11, 20, 27, 1, 5`.

Failing rows:

- `12`: no abort, final state 3, instruction 13.
- `16`: reason 2, lane 0, CHECK_STARTING_DATA exhaustion.
- `23`: reason 2, lane 0, CHECK_STARTING_DATA exhaustion.
- `28`: pass-control damaged by the lock; reason 2, lane 0.
- `30`: pass-control damaged by the lock; reason 2, lane 0.

Focused SDF/placement audit result: all held-out locked rows have the intended CNTVALUEIN3 source placement distance, `source_dqs1_minus_dq14_manhattan = 3`. Failures remain, and SDF `abs(dqs1-dq14)` is not a separator: passing locked seed27 has 629 ps abs skew, while failing locked seed30 has 69 ps.

Conclusion: exact CNTVALUEIN3 source placement is an effective perturbation and rescues several baseline failures, but it is neither sufficient nor safe as a final workaround. It likely perturbs a broader placement/routing margin. The next analysis should compare pass-vs-fail rows inside the locked population to identify what collateral SDF/JSON feature separates the five failures from the six passes.

### CNTVALUEIN3 Lock Pre/Post SDF Movement: 2026-05-28

Correction to the intervention logic: a failed solution hypothesis does not automatically falsify the cause/effect hypothesis. Before judging the exact CNTVALUEIN3 lock, we must ask whether it actually moved the SDF feature it was supposed to fix.

Artifacts:

- baseline focused audit: `artifacts/sdf-diagnostics/cntvaluein3-dqs1-dq14-prepost-lock/baseline-no-lock/`
- locked focused audit: `artifacts/sdf-diagnostics/cntvaluein3-dqs1-dq14-prepost-lock/cntvaluein3-skew-locked/`
- joined pre/post comparison: `artifacts/sdf-diagnostics/cntvaluein3-dqs1-dq14-prepost-lock/prepost_comparison.csv`
- summary: `artifacts/sdf-diagnostics/cntvaluein3-dqs1-dq14-prepost-lock/README.md`

Summary by hardware transition:

| transition | rows | median baseline abs ps | median locked abs ps | median delta abs ps | improved abs count | worsened abs count | median source manhattan delta |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| fail_to_fail | 3 | 230.0 | 419.0 | 189.0 | 0 | 3 | -10.0 |
| fail_to_pass | 5 | 400.0 | 163.0 | -155.0 | 3 | 2 | -14.0 |
| pass_to_fail | 2 | 161.0 | 303.5 | 142.5 | 1 | 1 | -8.5 |
| pass_to_pass | 3 | 139.0 | 355.0 | 216.0 | 0 | 3 | -4.0 |

Per-seed examples:

| seed | transition | baseline abs ps | locked abs ps | delta abs ps | source manhattan |
| ---: | --- | ---: | ---: | ---: | --- |
| 2 | fail_to_pass | 707 | 163 | -544 | 21 -> 3 |
| 20 | fail_to_pass | 421 | 69 | -352 | 22 -> 3 |
| 12 | fail_to_fail | 117 | 350 | +233 | 15 -> 3 |
| 23 | fail_to_fail | 230 | 419 | +189 | 13 -> 3 |
| 28 | pass_to_fail | 179 | 538 | +359 | 9 -> 3 |
| 30 | pass_to_fail | 143 | 69 | -74 | 14 -> 3 |

Conclusion: the exact two-cell lock is a valid topology perturbation but not a valid controlled intervention on the `abs(dqs1-dq14) CNTVALUEIN3` SDF skew. It consistently forces the source LUTs to the seed3 BEL pair, but the routed SDF skew often gets worse. Therefore the held-out lock failures do not by themselves disprove the original skew hypothesis. They show that this lock set is too weak or too indirect to guarantee the intended SDF feature.

The strongest refined statement is:

- `abs(dqs1-dq14) CNTVALUEIN3` remains a plausible cause/effect or proxy hypothesis because some rescued rows, especially seeds 2 and 20, moved the target skew sharply in the expected direction.
- The exact BEL source lock is not a sufficient solution hypothesis because it does not reliably move the target SDF skew, and it can damage passing seeds.
- Any future solution hypothesis must include a pre-hardware SDF acceptance check: build the candidate, measure the target skew/topology, and only then interpret hardware pass/fail as a test of that cause.

### CNTVALUEIN3 Lock Pre/Post Signed-Skew Analysis: 2026-05-28

The next refinement compared signed derived skew features before and after the CNTVALUEIN3 lock, joined by seed and classified by hardware transition. This uses the standard semantic SDF pipeline: normalized SDF metrics -> derived skew features -> paired pre/post transition comparison.

Artifacts:

- locked unique metrics: `artifacts/sdf-metrics/cntvaluein3-lock-unique-prepost/`
- locked unique feature table: `artifacts/statistical-sdf/cntvaluein3-lock-unique-prepost/`
- locked unique skew table: `artifacts/statistical-sdf/cntvaluein3-lock-unique-prepost-skew/`
- paired signed-skew analysis: `artifacts/statistical-sdf/cntvaluein3-lock-prepost-signed-skew-analysis/`

Samples:

| transition | samples |
| --- | ---: |
| fail_to_pass | 5 |
| fail_to_fail | 3 |
| pass_to_fail | 2 |
| pass_to_pass | 3 |
| total | 13 |

Each seed has 124 paired signed features covering IDELAY CNTVALUEIN DQS-vs-DQ, lane-vs-lane, IDELAY LD DQS-vs-DQ, and LD-vs-CNTVALUEIN relations. These are feature observations, not independent samples.

Per-seed aggregate result:

| seed | transition | sign flips / 124 | abs improved | abs worsened | median delta abs ps |
| ---: | --- | ---: | ---: | ---: | ---: |
| 2 | fail_to_pass | 62 | 63 | 59 | -14.25 |
| 20 | fail_to_pass | 88 | 52 | 72 | 28.75 |
| 28 | pass_to_fail | 87 | 33 | 91 | 236.5 |
| 30 | pass_to_fail | 65 | 67 | 57 | -22.5 |

Global sign flips are not sufficient by themselves: pass-to-pass rows also show many sign flips. The lock is a large perturbation, so the useful signal is not `any sign flip`; it is which signed relation flips or moves differently in pass-to-fail versus fail-to-pass rows.

The clearest pass-to-fail enriched subset is in `pass_to_fail_sign_flip_enriched.csv`: seven features flip in both pass-to-fail rows but in at most one of five fail-to-pass rows. They concentrate around lane0 `CNTVALUEIN3` DQS-vs-DQ signed relations and lane0 DQS `LD-vs-CNTVALUEIN3`:

| feature family | examples | pass-to-fail flips | fail-to-pass flips |
| --- | --- | ---: | ---: |
| lane0 ctrl3 DQS-vs-DQ bit signed skew | dq0, dq1, dq4, dq6 | 2/2 | 1/5 |
| lane0 ctrl3 DQS-vs-DQ median signed skew | dqs0 vs DQ lane median | 2/2 | 1/5 |
| lane0 ctrl3 LD-vs-CNTVALUEIN DQS signed skew | dqs0 `LD - CNTVALUEIN3` | 2/2 | 1/5 |

Conclusion: seed30 no longer looks like evidence that lower absolute skew is bad. It looks like evidence that the absolute-skew metric is incomplete. The stronger cause/effect hypothesis is signed/order-sensitive and lane0/control-bit-3 heavy: the damaging lock cases appear to change the relative order between lane0 DQS and DQ `CNTVALUEIN3`, plus the lane0 DQS LD-vs-CNTVALUEIN3 relationship. This fits the hardware signature because the damaged pass controls fail with reason 2 on lane0.

This is still not proof. The pass-to-fail population is only two samples, and pass-to-pass rows also show broad sign churn. The next causal test must intentionally move or protect the lane0 ctrl3 signed relations, then verify the signed SDF acceptance criterion before programming hardware.

### CNTVALUEIN3 held-out long-poll retest

The failed rows from `cntvaluein3-lock-heldout-seeds` were reprogrammed with `--poll-count 500 --poll-interval 0.1`. This gives about 50 seconds of JTAG polling after programming completes, versus the previous default 100 polls / 10 seconds.

| Seed | Prior 100-poll result | 500-poll result | Signature |
| ---: | --- | --- | --- |
| 12 | False | False | long-poll retest still fails without abort; final state 3 instruction 13 |
| 16 | False | False | long-poll retest still fails with check_starting_data_search_exhausted lane 0 start_index_check=48 dq_target_index=33 |
| 23 | False | False | long-poll retest still fails with check_starting_data_search_exhausted lane 0 start_index_check=48 dq_target_index=33 |
| 28 | False | False | long-poll retest still fails with check_starting_data_search_exhausted lane 0 start_index_check=48 dq_target_index=33 |
| 30 | False | False | long-poll retest still fails with check_starting_data_search_exhausted lane 0 start_index_check=48 dq_target_index=33 |

Conclusion: the five locked held-out failures are not short-timeout artifacts. The exact CNTVALUEIN3 two-cell lock remains a diagnostic intervention, not a final fix. Seed 12 should be analyzed as a no-abort instruction-13/stalled-calibration case; seeds 16, 23, 28, and 30 should be analyzed as reason-2 lane-0 CHECK_STARTING_DATA cases.

### CNTVALUEIN3 Locked-Population SDF/JSON Diff: 2026-05-28

Artifacts:

- SDF metrics: `artifacts/sdf-metrics/cntvaluein3-lock-heldout-long-poll/`
- SDF feature table: `artifacts/statistical-sdf/cntvaluein3-lock-heldout-long-poll/`
- derived skew table: `artifacts/statistical-sdf/cntvaluein3-lock-heldout-long-poll-skew/`
- SDF-referenced placement table: `artifacts/statistical-sdf/cntvaluein3-lock-heldout-long-poll-placement/`
- filtered bucket analysis: `artifacts/statistical-sdf/cntvaluein3-lock-heldout-long-poll-analysis/`
- findings summary: `artifacts/statistical-sdf/cntvaluein3-lock-heldout-long-poll-analysis/locked_population_findings.md`

This analysis compares the six passing locked rows against the five failing locked long-poll rows, but filters out the two locked `CNTVALUEIN3` source-LUT features and derived `CNTVALUEIN3` aggregate skew metrics. The goal is to identify collateral SDF/JSON signatures after the intended lock target is held fixed.

Buckets:

| bucket | pass rows | fail rows | interpretation |
| --- | ---: | ---: | --- |
| reason-2 lane-0 | 6 | 4 | seeds `16, 23, 28, 30`; all have `CHECK_STARTING_DATA`, lane 0, `start_index_check=48`, `dq_target_index=33` |
| seed12 no-abort | 6 | 1 | seed `12`; final state `3`, instruction `13`, no captured abort |
| all-fail pooled | 6 | 5 | retained only as a sanity view; not the main interpretation because seed12 is a different bucket |

Reason-2 lane-0 results:

| feature family | strongest result | interpretation |
| --- | --- | --- |
| direct SDF | no strict separator; top fail-higher rows are `dq_iologic lane1 dq11` AUC 0.917, `dq_iologic lane0 dq5` AUC 0.875, and `dq_iologic lane0 dq3` AUC 0.875 | direct delays still point at DQ IOLOGIC and non-locked IDELAY programming, but with overlap |
| derived skew | one strict separator: `abs(dqs1 - dq9) CNTVALUEIN4`, fail-lower, AUC 1.000, median -273 ps, strict margin 41 ps | the remaining signal is relative skew/alignment margin, not a simple fail-slower threshold |
| JSON placement distance | no strict separator; reset-release manhattan max/spread AUC 0.75 with overlap | current placement-distance features are too coarse, especially for same-site IOLOGIC edges |

Seed12 singleton results:

| feature family | strongest result | interpretation |
| --- | --- | --- |
| direct SDF | strict fail-higher clues in `dq_iologic lane0 dq1` (+566 ps median, +460 ps strict margin), clocking (+562.5 ps, +420 ps), and `idelay_data_cntvaluein lane1 ctrl0` fanout spread (+411 ps, +292 ps) | compatible with a stalled calibration progress bucket, but one failing row is not population proof |
| derived skew | strict fail-higher clues in lane0 DQS `LD - CNTVALUEIN` skew across ctrl bits, especially ctrl4 (+614.5 ps median, +507 ps strict margin) | suggests seed12 deserves a separate instruction-13 progress observer rather than pooling with reason-2 lane-0 failures |

Conclusion:

- CE-004 is narrowed, not falsified: source-LUT topology for the exact `CNTVALUEIN3 dqs1-dq14` pair is not sufficient, and the source lock does not reliably improve the actual SDF skew. Locked rows all have the intended source placement, yet the target SDF skew still varies from 69 ps to 629 ps and five rows fail.
- CE-001 and CE-002 remain active, but the current locked-population evidence points to a broader byte-lane alignment-margin signature involving non-locked CNTVALUEIN bits, LD-vs-CNTVALUEIN skew, and DQ/DQS IOLOGIC delay.
- SO-006 remains rejected as a final fix. It is useful as a perturbation that generated a cleaner pass/fail population, not as a constraint to ship.
- The next cause/effect test should either add a focused reason-2 observer for the `CHECK_STARTING_DATA` accepted/rejected candidate window, or create a soft byte-lane locality/floorplan intervention and verify that it moves the broader skew/IOLOGIC signature and held-out pass rate together.

### Seed 31..60 Paired CNTVALUEIN3-Lock Matrix: 2026-05-28

Artifacts:

- build manifest: `artifacts/builds/seed-31-60-baseline-cntvaluein3-lock/`
- hardware sweep: `artifacts/hardware/seed-31-60-baseline-cntvaluein3-lock/`
- baseline SDF metrics: `artifacts/sdf-metrics/seed-31-60-baseline-no-lock/`
- locked SDF metrics: `artifacts/sdf-metrics/seed-31-60-cntvaluein3-lock/`
- signed-skew transition analysis: `artifacts/statistical-sdf/seed-31-60-cntvaluein3-lock-prepost-signed-skew/`
- findings summary: `artifacts/statistical-sdf/seed-31-60-cntvaluein3-lock-prepost-signed-skew/findings.md`

This matrix extends the paired baseline versus CNTVALUEIN3-lock experiment to seeds 31..60 with long-poll hardware testing. The hardware transition counts are:

| transition | seeds |
| --- | ---: |
| fail -> pass | 13 |
| fail -> fail | 3 |
| pass -> fail | 8 |
| pass -> pass | 6 |

The lock improves aggregate pass count from 14/30 baseline to 19/30 locked, but it damages 8 passing baselines. Therefore the exact two-LUT CNTVALUEIN3 BEL lock remains rejected as a final solution. It is a useful perturbation, not a robust integration constraint.

The larger signed-skew analysis strengthens CE-006 but shifts its narrow target. The original 13-pair result was lane0 ctrl3-heavy; the 30-pair matrix instead ranks signed DQS-minus-DQ CNTVALUEIN relations mostly in lane0 ctrl0/ctrl2:

| feature | pass-to-fail median delta ps | fail-to-pass median delta ps |
| --- | ---: | ---: |
| lane0 dq7 ctrl0 signed DQS-DQ | -576.5 | 240 |
| lane0 dq7 ctrl2 signed DQS-DQ | 551.5 | -229 |
| lane0 dq3 ctrl0 signed DQS-DQ | -462 | 323 |
| lane0 dq1 ctrl2 signed DQS-DQ | 448.5 | -292 |
| lane0 dq4 ctrl2 signed DQS-DQ | 374 | -318 |
| lane0 dq5 ctrl0 signed DQS-DQ | -505.5 | 208 |

Interpretation:

- CE-006 is strengthened as a signed/order-sensitive IDELAY programming hypothesis, not an absolute-skew hypothesis.
- The exact `abs(dqs1-dq14) CNTVALUEIN3` target is demoted to a proxy. It is not sufficient as an SDF acceptance criterion.
- No strict separator exists in the new transition table; the next solution must be SDF-gated before hardware. If a proposed RTL or constraint change does not move the intended signed DQS-vs-DQ and LD-vs-CNTVALUEIN features in the expected direction, the hardware result should not be used as evidence for that solution.

Next test:

1. Build an RTL shadow/load handshake or soft lane0 IDELAY-programming locality intervention.
2. Reject candidate bitstreams before programming unless signed DQS-vs-DQ and LD-vs-CNTVALUEIN features move into the accepted band.
3. Hardware-test held-out seeds only after the intended SDF signature moves.


### Invalid-window retry gate: 2026-05-29

The all-ones invalid-window case was targeted with a small RTL retry in `ANALYZE_DATA`.
The first build registered the invalid-window flag from the prior-cycle shifted word;
seed5 still failed with reason 1 and an all-ones snapshot, proving the flag was
misaligned with the decision cycle.

After aligning the flag to the same indexed 32-bit slice that will be captured in
`read_lane_data_shifted`, seed5 builds and meets timing. The hardware result is:

| RTL commit | seed | result | signature |
| --- | ---: | --- | --- |
| `fe5e6ec` | 5 | fail | reason 1 `analyze_data_both_assumptions_failed`, lane0, `start_index_check=0`, `data_start_index=24`, `dq_target_index=35`, shifted `0xf12c3d91`, expected `0xd0ad51c1`, window `0xdbcfd275f12c3d91`, data taps `24/26`, DQS taps `1/3` |

Conclusion: the aligned invalid-window retry is no longer looking at stale data,
but seed5 is not currently an all-zeros/all-ones invalid-window failure. It is a
nontrivial mismatch where the algorithm has set both early and late assumptions
and then aborts. The next RTL change should handle this bucket explicitly, likely
by adding a bounded local re-center/search around the contradiction path rather
than treating only saturated read windows as invalid.

Artifacts:

- hardware result: `artifacts/hardware/invalid-window-retry-gate2/seed-5.json`
- summary: `artifacts/hardware/invalid-window-retry-gate2/summary.csv`

### ANALYZE_DATA contradiction retry gate: 2026-05-29

The seed5 failure after the aligned invalid-window retry was not an all-ones/all-zeroes
window. It was a nontrivial mismatch with both calibration assumptions set:
`lane_write_dq_late=1` and `lane_read_dq_early=1`. That means the saturated-window
classifier was too narrow for this bucket.

A bounded per-lane contradiction retry was added in `ANALYZE_DATA`: when the
contradiction path would otherwise reset, the FSM may clear both assumptions,
reset `data_start_index` and `start_index_check`, and rerun `CHECK_STARTING_DATA`.
After three such retries, the old reason-1 abort remains in place.

| RTL commit | seed | result | signature |
| --- | ---: | --- | --- |
| `e1ae1e2` | 5 | pass | `calib_complete=true`, `bist_done=true`, `wrong_read_data=0`, no abort, data taps `24/25`, DQS taps `1/2` |

Conclusion: seed5 is rescued by treating the both-assumptions contradiction as a
recoverable calibration-search ambiguity rather than an immediate terminal error.
This is a stronger RTL-level solution hypothesis than the previous saturated-window
retry, but it still needs regression testing on known failing and known passing seeds.

Artifacts:

- hardware result: `artifacts/hardware/analyze-data-contradiction-retry-gate1/seed-5.json`
- summary: `artifacts/hardware/analyze-data-contradiction-retry-gate1/summary.csv`

Regression note: the first bounded contradiction-retry RTL (`e1ae1e2`) is too
large as written. Seed5 builds at 95.47 MHz and passes hardware, but the known
pass-control seed3 fails nextpnr timing at 79.68 MHz against the 83.33 MHz
controller clock target. Seeds 2 and 6 were not tested in this gate because the
multi-build stopped after the seed3 timing failure. The next patch should keep
the same logical behavior but remove the extra per-lane contradiction counter,
preferably reusing existing retry state.

### Reduced contradiction-retry gate: 2026-05-29

The first contradiction retry (`e1ae1e2`) rescued seed5 but added enough logic to
break timing on seed3. A reduced version (`3ea4648`) removed the new per-lane
contradiction counter and reused the existing invalid-window retry budget.

| RTL commit | seed | build | hardware result | signature |
| --- | ---: | --- | --- | --- |
| `3ea4648` | 5 | pass timing | fail | reason 6 `analyze_data_invalid_window_exhausted`, lane0, `start_index_check=0`, `data_start_index=0`, `dq_target_index=36`, shifted `0xffffffff`, window `0x51ffffffffffffff`, data taps `23/24`, DQS taps `0/1` |
| `3ea4648` | 3 | pass timing | pass | `calib_complete=true`, `bist_done=true`, no abort, data taps `25/26`, DQS taps `2/3` |

Conclusion: the reduced implementation is timing-clean and preserves the seed3
pass control, but it is not logically equivalent to the seed5-rescuing version.
Reusing `analyze_data_invalid_retry` consumes the retry budget on the wrong class
of recovery and seed5 returns to the all-ones invalid-window exhausted bucket.
The next implementation should keep a separate contradiction-retry decision, but
encode it without adding a new timing-heavy per-lane counter on the controller
critical path. A promising shape is to fold the retry into the existing
`ANALYZE_DATA_SEARCH` / `ANALYZE_DATA_SEARCH_DONE` state flow so the terminal
both-assumptions branch only redirects into the existing search/recenter machine,
with one shared small retry bit or state tag rather than extra per-lane compare
logic in the hot combinational cone.

Artifacts:

- hardware result seed5: `artifacts/hardware/analyze-data-contradiction-retry-reduced-gate1/seed-5.json`
- hardware result seed3: `artifacts/hardware/analyze-data-contradiction-retry-reduced-gate1/seed-3.json`
- summary: `artifacts/hardware/analyze-data-contradiction-retry-reduced-gate1/summary.csv`
