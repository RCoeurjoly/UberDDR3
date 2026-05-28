set terminal pngcairo size 1200,840 enhanced font 'DejaVu Sans,9'
set output 'pair_11_direct_control_fanout_spread_idelay_data_cntvaluein_lane0_no_bit_ctrl_2_lane_control_bit_value_ps_VS_skew_signed_dqs_bus_skew_minus_dq_median_idelay_cnt.png'
set datafile separator comma
set key outside right top
set grid
set title 'rule 11: bal_acc=0.710131 errors=33'
set xlabel 'control_fanout_spread__idelay_data_cntvaluein__lane0__no_bit__ctrl_2__lane_control_bit__value_ps (ps)'
set ylabel 'signed_dqs_bus_skew_minus_dq_median__idelay_cntvaluein_skew__lane0__dqs0__ctrl_none__dqs_vs_dq_bus_skew__value (ps)'
set arrow 1 from 381.917391, graph 0 to 381.917391, graph 1 nohead lw 2 lc rgb '#666666' dt 2
set arrow 2 from graph 0, -322.717391 to graph 1, -322.717391 nohead lw 2 lc rgb '#666666' dt 2
plot \
  'pair_11_direct_control_fanout_spread_idelay_data_cntvaluein_lane0_no_bit_ctrl_2_lane_control_bit_value_ps_VS_skew_signed_dqs_bus_skew_minus_dq_median_idelay_cnt.dat' using 3:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'pair_11_direct_control_fanout_spread_idelay_data_cntvaluein_lane0_no_bit_ctrl_2_lane_control_bit_value_ps_VS_skew_signed_dqs_bus_skew_minus_dq_median_idelay_cnt.dat' using 5:6 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
