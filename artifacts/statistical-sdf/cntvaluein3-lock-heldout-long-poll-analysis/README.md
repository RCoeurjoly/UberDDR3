# CNTVALUEIN3 Locked Population Filtered Analysis Inputs

This directory contains pass/fail feature tables for the locked held-out population after excluding features directly driven by the two locked CNTVALUEIN3 source LUTs.

Excluded feature families:

- direct `idelay_data_cntvaluein` / `idelay_dqs_cntvaluein` features with `control_bit=3`;
- aggregate direct CNTVALUEIN lane/bus metrics that include control bit 3;
- derived `idelay_cntvaluein_skew` features for `control_bit=3` or bus-skew aggregates;
- derived `idelay_ld_cntvaluein_skew` features for `control_bit=3`.

Buckets:

- `reason2`: six pass rows versus four long-poll reason-2 lane-0 failures, seeds 16/23/28/30.
- `seed12`: six pass rows versus the long-poll seed12 no-abort/instruction-13 failure.
- `allfail`: six pass rows versus all five long-poll failures.

Findings:

- `locked_population_findings.md` is the human-readable summary.
- Reason-2 lane-0 failures have no strict direct-SDF separator after filtering out the locked CNTVALUEIN3 target. The strongest remaining evidence is relative skew: `abs(dqs1 - dq9) CNTVALUEIN4` is a strict fail-lower separator with 41 ps margin, while several DQ IOLOGIC and non-locked IDELAY programming metrics have high AUC but overlap.
- Seed12 is a separate singleton no-abort/instruction-13 bucket. It has many strict clues, led by clocking, lane0 DQ IOLOGIC, and lane0 DQS LD-vs-CNTVALUEIN skew, but those are not population proof.
- The JSON placement-distance extractor does not find a decisive separator in this population; it is currently too coarse for same-site IOLOGIC edges.
