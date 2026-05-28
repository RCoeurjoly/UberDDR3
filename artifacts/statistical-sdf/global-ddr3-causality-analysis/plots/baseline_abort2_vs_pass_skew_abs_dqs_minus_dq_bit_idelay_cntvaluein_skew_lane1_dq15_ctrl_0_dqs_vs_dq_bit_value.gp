set terminal pngcairo size 1200,720 enhanced font 'DejaVu Sans,10'
set output 'baseline_abort2_vs_pass_skew_abs_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane1_dq15_ctrl_0_dqs_vs_dq_bit_value.png'
set datafile separator comma
set key outside right top
set grid
set xlabel 'Experiment index'
set ylabel 'Feature value (ps)'
set title 'abs_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq15__ctrl_0__dqs_vs_dq_bit__value_ps'
plot \
  'baseline_abort2_vs_pass_skew_abs_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane1_dq15_ctrl_0_dqs_vs_dq_bit_value.dat' using 1:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'baseline_abort2_vs_pass_skew_abs_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane1_dq15_ctrl_0_dqs_vs_dq_bit_value.dat' using 1:5 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
