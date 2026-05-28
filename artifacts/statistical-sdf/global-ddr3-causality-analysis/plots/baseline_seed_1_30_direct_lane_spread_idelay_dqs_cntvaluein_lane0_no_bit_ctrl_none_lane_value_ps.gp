set terminal pngcairo size 1200,720 enhanced font 'DejaVu Sans,10'
set output 'baseline_seed_1_30_direct_lane_spread_idelay_dqs_cntvaluein_lane0_no_bit_ctrl_none_lane_value_ps.png'
set datafile separator comma
set key outside right top
set grid
set xlabel 'Experiment index'
set ylabel 'Feature value (ps)'
set title 'lane_spread__idelay_dqs_cntvaluein__lane0__no_bit__ctrl_none__lane__value_ps'
plot \
  'baseline_seed_1_30_direct_lane_spread_idelay_dqs_cntvaluein_lane0_no_bit_ctrl_none_lane_value_ps.dat' using 1:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'baseline_seed_1_30_direct_lane_spread_idelay_dqs_cntvaluein_lane0_no_bit_ctrl_none_lane_value_ps.dat' using 1:5 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
