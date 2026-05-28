# Seed 31..60 CNTVALUEIN3-Lock Signed-Skew Findings

## Hardware Transitions

The paired matrix has 30 seeds, each built as baseline plus CNTVALUEIN3-lock:

| transition | seeds |
| --- | ---: |
| fail -> pass | 13 |
| fail -> fail | 3 |
| pass -> fail | 8 |
| pass -> pass | 6 |

The lock improves aggregate pass count from 14/30 baseline to 19/30 locked, but it damages 8 passing baselines. This rejects the exact two-LUT CNTVALUEIN3 lock as a final fix.

## SDF Interpretation

The strongest pre/post transition contrasts are signed DQS-minus-DQ IDELAY CNTVALUEIN relations, mostly lane 0 ctrl0/ctrl2:

| feature | pass->fail median delta ps | fail->pass median delta ps |
| --- | ---: | ---: |
| lane0 dq7 ctrl0 signed DQS-DQ | -576.5 | 240 |
| lane0 dq7 ctrl2 signed DQS-DQ | 551.5 | -229 |
| lane0 dq3 ctrl0 signed DQS-DQ | -462 | 323 |
| lane0 dq1 ctrl2 signed DQS-DQ | 448.5 | -292 |
| lane0 dq4 ctrl2 signed DQS-DQ | 374 | -318 |
| lane0 dq5 ctrl0 signed DQS-DQ | -505.5 | 208 |

This strengthens CE-006 as a signed/order-sensitive IDELAY programming hypothesis, but it also changes the narrow target: the earlier lane0 ctrl3-heavy result was too small-n. The larger matrix points more broadly at lane0 signed DQS-vs-DQ CNTVALUEIN relationships, especially ctrl0/ctrl2, with LD-vs-CNTVALUEIN still present but lower ranked.

## Constraint Consequence

Do not promote the CNTVALUEIN3 BEL lock. A valid solution candidate must first pass an SDF acceptance gate on the intended signed-skew features, then improve held-out hardware pass rate. The next candidates are:

- RTL shadow/register CNTVALUEIN before LD with explicit load/readback sequencing.
- Soft lane0 byte-lane locality/floorplan covering DQS/DQ CNTVALUEIN and LD source cones.
- Exact BEL locks only as diagnostic perturbations, not as the final integration strategy.
