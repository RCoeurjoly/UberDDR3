set terminal pngcairo size 1200,840 enhanced font 'DejaVu Sans,9'
set output 'pair_12_direct_cntvaluein_bus_skew_idelay_data_cntvaluein_lane1_dq10_ctrl_none_dq10_value_ps_VS_skew_abs_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane1_dq14_ctrl.png'
set datafile separator comma
set key outside right top
set grid
set title 'rule 12: bal_acc=0.709944 errors=26'
set xlabel 'cntvaluein_bus_skew__idelay_data_cntvaluein__lane1__dq10__ctrl_none__dq10__value_ps (ps)'
set ylabel 'abs_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq14__ctrl_3__dqs_vs_dq_bit__value_ps (ps)'
set arrow 1 from 884.673913, graph 0 to 884.673913, graph 1 nohead lw 2 lc rgb '#666666' dt 2
set arrow 2 from graph 0, 321.880435 to graph 1, 321.880435 nohead lw 2 lc rgb '#666666' dt 2
plot \
  'pair_12_direct_cntvaluein_bus_skew_idelay_data_cntvaluein_lane1_dq10_ctrl_none_dq10_value_ps_VS_skew_abs_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane1_dq14_ctrl.dat' using 3:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'pair_12_direct_cntvaluein_bus_skew_idelay_data_cntvaluein_lane1_dq10_ctrl_none_dq10_value_ps_VS_skew_abs_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane1_dq14_ctrl.dat' using 5:6 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
