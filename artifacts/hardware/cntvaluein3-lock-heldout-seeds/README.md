# CNTVALUEIN3 lock held-out hardware results

This batch tested the exact two-cell CNTVALUEIN3 lock against remaining known baseline failures `6, 11, 12, 16, 20, 23, 27` plus pass controls `1, 5, 28, 30`.

Summary:

| Group | Pass | Fail |
| --- | ---: | ---: |
| Baseline reason2 failures | 4 | 2 |
| Baseline startup failure | 0 | 1 |
| Baseline pass controls | 2 | 2 |
| Total | 6 | 5 |

Passing rows: `6, 11, 20, 27, 1, 5`.

Failing rows: `12` fails at state 4 / instruction 13 with no abort; `16, 23, 28, 30` fail with reason 2 CHECK_STARTING_DATA exhaustion.

Conclusion: the exact CNTVALUEIN3 lock is a useful intervention probe, but it is not an all-failure fix and is not safe as a final workaround because it damages pass-control seeds.
