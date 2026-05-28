# CNTVALUEIN3 Locked-Population Pass/Fail Diff

Purpose: compare pass/fail rows after the exact two-cell `CNTVALUEIN3` source-LUT lock, while filtering out the two locked `CNTVALUEIN3` source features themselves. This asks what collateral SDF/JSON signature remains when the intended lock target is held fixed.

Inputs:

- pass rows: locked seeds `1, 5, 6, 11, 20, 27`
- reason-2 lane-0 fail rows: locked long-poll seeds `16, 23, 28, 30`
- separate no-abort bucket: locked long-poll seed `12`, final state `3`, instruction `13`
- excluded features: direct `idelay_{data,dqs}_cntvaluein` control bit `3`, aggregate bus metrics containing control bit `3`, and derived `CNTVALUEIN3` skew features

Artifacts:

- filtered input tables: `*_features_long.csv`
- statistical rankings: `sdf_*_analysis/`, `skew_*_analysis/`, `placement_*_analysis/`
- placement feature extraction: `scripts/uberddr3_sdf_placement_features.py`

## Reason-2 Lane-0 Bucket

Rows: 6 pass, 4 fail. These are the rows that still fail with `CHECK_STARTING_DATA` reason `2`, lane `0`, `start_index_check=48`, `dq_target_index=33`, after the two CNTVALUEIN3 source LUTs are locked.

Direct SDF delay results:

| Feature | Direction | AUC | Fail median delta | Strict? |
| --- | --- | ---: | ---: | --- |
| `dq_iologic lane1 dq11` | fail higher | 0.917 | +387 ps | no |
| `dq_iologic lane0 dq5` | fail higher | 0.875 | +598.5 ps | no |
| `dq_iologic lane0 dq3` | fail higher | 0.875 | +457 ps | no |
| `idelay_dqs_cntvaluein lane0 dqs0 ctrl0` | fail higher | 0.875 | +214.5 ps | no |
| `idelay_data_cntvaluein lane1 ctrl0 fanout spread` | fail higher | 0.875 | +116.5 ps | no |
| `idelay_dqs_cntvaluein lane0 dqs0 ctrl2` | fail lower | 0.875 | -655.5 ps | no |

Derived skew results:

| Feature | Direction | AUC | Fail median delta | Strict? |
| --- | --- | ---: | ---: | --- |
| `abs(dqs1 - dq9) CNTVALUEIN4` | fail lower | 1.000 | -273 ps | yes, 41 ps |
| `abs(dqs1 - dq8) CNTVALUEIN2` | fail lower | 0.958 | -432.5 ps | no |
| `signed(dqs1 - dq13) CNTVALUEIN2` | fail lower | 0.917 | -698 ps | no |
| `signed lane1-lane0 DQ median CNTVALUEIN2` | fail higher | 0.917 | +128.8 ps | no |
| `LD - CNTVALUEIN DQS lane1 ctrl2` | fail higher | 0.875 | +275 ps | no |

JSON placement-distance results:

| Feature | Direction | AUC | Fail median delta | Strict? |
| --- | --- | ---: | ---: | --- |
| `reset_release source-to-sink manhattan max` | fail higher | 0.75 | +3 sites | no |
| `reset_release source-to-sink manhattan spread` | fail higher | 0.75 | +3 sites | no |

Interpretation:

- The reason-2 bucket does not have a clean direct-delay separator outside the locked `CNTVALUEIN3` LUTs.
- The best remaining evidence is still relative skew, not absolute placement distance. The only strict separator is `abs(dqs1 - dq9) CNTVALUEIN4`, and it is fail-lower, not fail-higher.
- The high-AUC direct SDF candidates cluster in DQ IOLOGIC and non-locked IDELAY programming bits, which supports a broader byte-lane alignment-margin hypothesis.
- The extracted JSON placement-distance features are too coarse to explain this bucket. Most IOLOGIC edges are same-site distance zero, and reset-release distance has overlap.

Conclusion for reason-2 failures: the two-cell lock is not enough because the failing locked rows still land in a bad collateral alignment margin. The next hypothesis should widen from the exact `CNTVALUEIN3 dqs1-dq14` pair to a byte-lane-local IDELAY programming and DQ/DQS IOLOGIC skew signature, especially lane1 DQS-vs-DQ skew terms and lane0 DQ IOLOGIC delay.

## Seed12 No-Abort Bucket

Rows: 6 pass, 1 fail. Seed12 is final state `3`, instruction `13`, with no captured abort. Treat every strict separator here as a singleton clue, not population proof.

Top singleton direct SDF clues:

| Feature | Direction | AUC | Fail median delta | Strict margin |
| --- | --- | ---: | ---: | ---: |
| `dq_iologic lane0 dq1` | fail higher | 1.000 | +566 ps | +460 ps |
| `clocking all endpoints` | fail higher | 1.000 | +562.5 ps | +420 ps |
| `dq_iologic lane0 dq5` | fail higher | 1.000 | +412 ps | +138 ps |
| `idelay_data_cntvaluein lane1 ctrl0 fanout spread` | fail higher | 1.000 | +411 ps | +292 ps |
| `idelay_ld lane0 dqs0` | fail higher | 1.000 | +181.5 ps | +28 ps |

Top singleton skew clues:

| Feature | Direction | AUC | Fail median delta | Strict margin |
| --- | --- | ---: | ---: | ---: |
| `LD - CNTVALUEIN DQS lane0 ctrl4` | fail higher | 1.000 | +614.5 ps | +507 ps |
| `LD - CNTVALUEIN DQS lane0 ctrl2` | fail higher | 1.000 | +795.5 ps | +216 ps |
| `LD - CNTVALUEIN DQS lane0 ctrl0` | fail higher | 1.000 | +746.5 ps | +216 ps |
| `LD - CNTVALUEIN DQS lane0 ctrl1` | fail higher | 1.000 | +500.5 ps | +211 ps |
| `DQ CNTVALUEIN lane1 ctrl0 range` | fail higher | 1.000 | +411 ps | +292 ps |

Interpretation:

- Seed12 is not the same failure mode as seeds `16, 23, 28, 30`; pooling it with reason-2 rows hides that distinction.
- Its strongest clues are clocking, lane0 DQ IOLOGIC, and lane0 DQS LD-vs-CNTVALUEIN skew. That is compatible with a calibration startup/progress stall around instruction `13`, but one row cannot prove it.
- The next useful seed12-style test is observability, not a constraint: capture what instruction `13` is waiting for and whether DQS/read-leveling progress counters are still changing.

## Actionable Next Step

Do not promote the exact two-cell `CNTVALUEIN3` BEL lock to a fix. It has no universal pass result and it does not consistently move the intended SDF skew in the expected direction.

The next intervention should target one broader signature at a time:

1. A soft byte-lane locality/floorplan experiment that keeps IDELAY programming source logic, DQ/DQS IOLOGIC-adjacent logic, and calibration bookkeeping near their byte lanes without exact BEL freezing.
2. A small RTL observer for the reason-2 bucket that records the accepted/rejected `CHECK_STARTING_DATA` candidate window and final compared read/write words.
3. A separate seed12 observer for instruction `13` progress, because its no-abort signature is not the reason-2 lane-0 search exhaustion.
