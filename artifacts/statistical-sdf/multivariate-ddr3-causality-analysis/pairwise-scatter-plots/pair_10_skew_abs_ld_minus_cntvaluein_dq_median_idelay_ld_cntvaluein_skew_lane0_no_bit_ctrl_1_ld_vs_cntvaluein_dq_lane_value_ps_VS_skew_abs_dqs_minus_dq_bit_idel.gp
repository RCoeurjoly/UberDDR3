set terminal pngcairo size 1200,840 enhanced font 'DejaVu Sans,9'
set output 'pair_10_skew_abs_ld_minus_cntvaluein_dq_median_idelay_ld_cntvaluein_skew_lane0_no_bit_ctrl_1_ld_vs_cntvaluein_dq_lane_value_ps_VS_skew_abs_dqs_minus_dq_bit_idel.png'
set datafile separator comma
set key outside right top
set grid
set title 'rule 10: bal_acc=0.710131 errors=33'
set xlabel 'abs_ld_minus_cntvaluein_dq_median__idelay_ld_cntvaluein_skew__lane0__no_bit__ctrl_1__ld_vs_cntvaluein_dq_lane_ (ps)'
set ylabel 'abs_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq12__ctrl_4__dqs_vs_dq_bit__value_ps (ps)'
set arrow 1 from 458.193478, graph 0 to 458.193478, graph 1 nohead lw 2 lc rgb '#666666' dt 2
set arrow 2 from graph 0, 388.778261 to graph 1, 388.778261 nohead lw 2 lc rgb '#666666' dt 2
plot \
  'pair_10_skew_abs_ld_minus_cntvaluein_dq_median_idelay_ld_cntvaluein_skew_lane0_no_bit_ctrl_1_ld_vs_cntvaluein_dq_lane_value_ps_VS_skew_abs_dqs_minus_dq_bit_idel.dat' using 3:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'pair_10_skew_abs_ld_minus_cntvaluein_dq_median_idelay_ld_cntvaluein_skew_lane0_no_bit_ctrl_1_ld_vs_cntvaluein_dq_lane_value_ps_VS_skew_abs_dqs_minus_dq_bit_idel.dat' using 5:6 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
