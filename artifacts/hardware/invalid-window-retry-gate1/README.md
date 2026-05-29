# Invalid Window Retry Gate 1

RTL commits tested: `8d0354e` plus `be28dcd`.

HIL settings: `--poll-count 200 --poll-interval 0.1`.

Seed 5 implemented after registering the invalid-window detector, but still failed on hardware.
The abort snapshot is still an all-ones window, while the reason is the generic both-assumptions abort. That means the registered invalid flag is one controller cycle out of phase with `read_lane_data_shifted` in the ANALYZE_DATA branch.

Next action: align the invalid flag with the newly selected shifted word by registering invalidity from `read_lane_data[start_index_check +: 32]`, not from the previous `read_lane_data_shifted` value.
