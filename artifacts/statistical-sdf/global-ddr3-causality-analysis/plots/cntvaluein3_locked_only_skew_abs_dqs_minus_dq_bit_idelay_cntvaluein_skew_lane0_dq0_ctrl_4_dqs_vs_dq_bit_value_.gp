set terminal pngcairo size 1200,720 enhanced font 'DejaVu Sans,10'
set output 'cntvaluein3_locked_only_skew_abs_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane0_dq0_ctrl_4_dqs_vs_dq_bit_value_.png'
set datafile separator comma
set key outside right top
set grid
set xlabel 'Experiment index'
set ylabel 'Feature value (ps)'
set title 'abs_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq0__ctrl_4__dqs_vs_dq_bit__value_ps'
plot \
  'cntvaluein3_locked_only_skew_abs_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane0_dq0_ctrl_4_dqs_vs_dq_bit_value_.dat' using 1:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'cntvaluein3_locked_only_skew_abs_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane0_dq0_ctrl_4_dqs_vs_dq_bit_value_.dat' using 1:5 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
