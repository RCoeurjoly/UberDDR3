set terminal pngcairo size 1200,840 enhanced font 'DejaVu Sans,9'
set output 'pair_02_skew_abs_ld_minus_cntvaluein_dq_median_idelay_ld_cntvaluein_skew_lane0_no_bit_ctrl_1_ld_vs_cntvaluein_dq_lane_value_ps_VS_direct_control_fanout_spread_i.png'
set datafile separator comma
set key outside right top
set grid
set title 'rule 2: bal_acc=0.721013 errors=31'
set xlabel 'abs_ld_minus_cntvaluein_dq_median__idelay_ld_cntvaluein_skew__lane0__no_bit__ctrl_1__ld_vs_cntvaluein_dq_lane_ (ps)'
set ylabel 'control_fanout_spread__idelay_data_cntvaluein__lane0__no_bit__ctrl_2__lane_control_bit__value_ps (ps)'
set arrow 1 from 421.823913, graph 0 to 421.823913, graph 1 nohead lw 2 lc rgb '#666666' dt 2
set arrow 2 from graph 0, 381.917391 to graph 1, 381.917391 nohead lw 2 lc rgb '#666666' dt 2
plot \
  'pair_02_skew_abs_ld_minus_cntvaluein_dq_median_idelay_ld_cntvaluein_skew_lane0_no_bit_ctrl_1_ld_vs_cntvaluein_dq_lane_value_ps_VS_direct_control_fanout_spread_i.dat' using 3:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'pair_02_skew_abs_ld_minus_cntvaluein_dq_median_idelay_ld_cntvaluein_skew_lane0_no_bit_ctrl_1_ld_vs_cntvaluein_dq_lane_value_ps_VS_direct_control_fanout_spread_i.dat' using 5:6 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
