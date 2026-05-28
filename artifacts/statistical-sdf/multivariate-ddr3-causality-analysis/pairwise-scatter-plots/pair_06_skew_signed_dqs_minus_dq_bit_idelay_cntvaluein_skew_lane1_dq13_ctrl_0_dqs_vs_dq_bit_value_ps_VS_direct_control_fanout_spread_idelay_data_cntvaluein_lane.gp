set terminal pngcairo size 1200,840 enhanced font 'DejaVu Sans,9'
set output 'pair_06_skew_signed_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane1_dq13_ctrl_0_dqs_vs_dq_bit_value_ps_VS_direct_control_fanout_spread_idelay_data_cntvaluein_lane.png'
set datafile separator comma
set key outside right top
set grid
set title 'rule 6: bal_acc=0.714634 errors=33'
set xlabel 'signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq13__ctrl_0__dqs_vs_dq_bit__value_ps (ps)'
set ylabel 'control_fanout_spread__idelay_data_cntvaluein__lane1__no_bit__ctrl_4__lane_control_bit__value_ps (ps)'
set arrow 1 from 73.35, graph 0 to 73.35, graph 1 nohead lw 2 lc rgb '#666666' dt 2
set arrow 2 from graph 0, 589.342391 to graph 1, 589.342391 nohead lw 2 lc rgb '#666666' dt 2
plot \
  'pair_06_skew_signed_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane1_dq13_ctrl_0_dqs_vs_dq_bit_value_ps_VS_direct_control_fanout_spread_idelay_data_cntvaluein_lane.dat' using 3:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'pair_06_skew_signed_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane1_dq13_ctrl_0_dqs_vs_dq_bit_value_ps_VS_direct_control_fanout_spread_idelay_data_cntvaluein_lane.dat' using 5:6 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
