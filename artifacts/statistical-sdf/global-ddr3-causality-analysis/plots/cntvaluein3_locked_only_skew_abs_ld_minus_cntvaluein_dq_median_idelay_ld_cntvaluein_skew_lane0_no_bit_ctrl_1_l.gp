set terminal pngcairo size 1200,720 enhanced font 'DejaVu Sans,10'
set output 'cntvaluein3_locked_only_skew_abs_ld_minus_cntvaluein_dq_median_idelay_ld_cntvaluein_skew_lane0_no_bit_ctrl_1_l.png'
set datafile separator comma
set key outside right top
set grid
set xlabel 'Experiment index'
set ylabel 'Feature value (ps)'
set title 'abs_ld_minus_cntvaluein_dq_median__idelay_ld_cntvaluein_skew__lane0__no_bit__ctrl_1__ld_vs_cntvaluein_dq_lane__value_ps'
plot \
  'cntvaluein3_locked_only_skew_abs_ld_minus_cntvaluein_dq_median_idelay_ld_cntvaluein_skew_lane0_no_bit_ctrl_1_l.dat' using 1:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'cntvaluein3_locked_only_skew_abs_ld_minus_cntvaluein_dq_median_idelay_ld_cntvaluein_skew_lane0_no_bit_ctrl_1_l.dat' using 1:5 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
