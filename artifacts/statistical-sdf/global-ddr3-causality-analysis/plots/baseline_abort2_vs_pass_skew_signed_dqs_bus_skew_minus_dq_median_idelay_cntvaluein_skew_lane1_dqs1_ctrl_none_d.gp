set terminal pngcairo size 1200,720 enhanced font 'DejaVu Sans,10'
set output 'baseline_abort2_vs_pass_skew_signed_dqs_bus_skew_minus_dq_median_idelay_cntvaluein_skew_lane1_dqs1_ctrl_none_d.png'
set datafile separator comma
set key outside right top
set grid
set xlabel 'Experiment index'
set ylabel 'Feature value (ps)'
set title 'signed_dqs_bus_skew_minus_dq_median__idelay_cntvaluein_skew__lane1__dqs1__ctrl_none__dqs_vs_dq_bus_skew__value_ps'
plot \
  'baseline_abort2_vs_pass_skew_signed_dqs_bus_skew_minus_dq_median_idelay_cntvaluein_skew_lane1_dqs1_ctrl_none_d.dat' using 1:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'baseline_abort2_vs_pass_skew_signed_dqs_bus_skew_minus_dq_median_idelay_cntvaluein_skew_lane1_dqs1_ctrl_none_d.dat' using 1:5 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
