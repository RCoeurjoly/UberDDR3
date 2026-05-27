# Exact-Abort Seed3 Focused SDF Rankings

This artifact runs `sdf-toolkit rank-paths` only for strict fail-slower DDR candidates from the exact-abort seed3 pass/pass/fail matrix.

Each candidate is a semantic key from `candidate_strict_fail_slower.csv`. For every sample, the ranked source/sink is that sample's own worst direct entry for the same semantic key, so the comparison survives synthesized temporary name churn.

## Files

- `selected_candidates.csv`: semantic candidates selected for ranking.
- `rank_summary.csv`: sample-specific ranked endpoints and direct SDF delays.
- `*.txt`: raw `sdf-toolkit rank-paths` output for each candidate/sample pair.

## Interpretation Rule

Use these outputs to identify the exact source/sink pins behind a semantic delay correlate and to verify that `sdf-toolkit rank-paths` resolves the same delay that the normalized metric reported. These candidates are direct SDF interconnect edges, so the rank output is usually one graph edge rather than a lower-level route decomposition. The direct delay value remains the cross-sample metric.

## Focused Result

All 27 rank-path checks completed with return code 0.

The cleanest strict fail-slower rows in this matrix are:

- `reset_release all`: pass/pass/fail delays are `584/584/990` ps.
- `idelay_data_cntvaluein lane1 dq9 ctrl3`: pass/pass/fail delays are `1396/1274/1743` ps.
- `idelay_data_cntvaluein lane1 dq15 ctrl3`: pass/pass/fail delays are `1315/1194/1652` ps.
- `dq_iologic lane0 dq2`: pass/pass/fail delays are `2069/2082/2365` ps.

Some rows are still useful but weaker as single-cause evidence:

- `idelay_dqs_cntvaluein lane0 dqs0 ctrl4`: pass/pass/fail delays are `1282/2066/2141` ps, so the CNTVALUEIN-only passing lock is already close to the failing row.
- `idelay_ld lane0 dqs0`: pass/pass/fail delays are `2046/1370/2055` ps, so it separates the failing row from the CNTVALUEIN-only pass but barely from the baseline pass.
