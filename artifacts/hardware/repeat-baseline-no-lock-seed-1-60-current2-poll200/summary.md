# Repeatability sweep (subset)

- manifest: `artifacts/builds/repeat-baseline-no-lock-seed-1-60-current2-poll200/build_manifest.csv`
- poll_count: 200
- poll_interval: 0.1

|seed|repeat pass|repeat reason|baseline pass|baseline reason|
|---|---:|---|---:|---|
|2|True|none|True|none|
|3|False|none|True|none|
|5|True|none|True|none|
|6|True|none|True|none|
|10|False|analyze_data_both_assumptions_failed|False|analyze_data_both_assumptions_failed|
|11|True|none|True|none|
|12|True|none|True|none|
|13|False|analyze_data_both_assumptions_failed|False|analyze_data_both_assumptions_failed|
|16|True|none|True|none|
|20|True|none|True|none|
|23|True|none|True|none|
|26|False|analyze_data_both_assumptions_failed|False|analyze_data_both_assumptions_failed|
|27|True|none|True|none|
|30|False|analyze_data_both_assumptions_failed|False|analyze_data_both_assumptions_failed|
|32|True|none|False|none|
|39|False|analyze_data_both_assumptions_failed|False|analyze_data_both_assumptions_failed|
|45|False|analyze_data_both_assumptions_failed|False|analyze_data_both_assumptions_failed|
|53|False|analyze_data_both_assumptions_failed|False|analyze_data_both_assumptions_failed|
|55|False|analyze_data_both_assumptions_failed|False|analyze_data_both_assumptions_failed|
|57|False|analyze_data_both_assumptions_failed|False|analyze_data_both_assumptions_failed|
|59|False|analyze_data_both_assumptions_failed|False|analyze_data_both_assumptions_failed|
|60|False|analyze_data_both_assumptions_failed|False|analyze_data_both_assumptions_failed|

## Counts
- total: 22
- pass=False: 12
- pass=True: 10

## Determinism check
- changed seeds vs baseline matrix: 2
  - seed3: baseline True/none -> repeat False/none
  - seed32: baseline False/none -> repeat True/none
