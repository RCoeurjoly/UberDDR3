set terminal pngcairo size 1200,840 enhanced font 'DejaVu Sans,9'
set output 'pair_09_direct_cntvaluein_bus_skew_idelay_data_cntvaluein_lane1_dq10_ctrl_none_dq10_value_ps_VS_skew_abs_lane1_minus_lane0_dqs_idelay_cntvaluein_skew_all_no_bit.png'
set datafile separator comma
set key outside right top
set grid
set title 'rule 9: bal_acc=0.712008 errors=31'
set xlabel 'cntvaluein_bus_skew__idelay_data_cntvaluein__lane1__dq10__ctrl_none__dq10__value_ps (ps)'
set ylabel 'abs_lane1_minus_lane0_dqs__idelay_cntvaluein_skew__all__no_bit__ctrl_4__lane1_vs_lane0_dqs__value_ps (ps)'
set arrow 1 from 493.408696, graph 0 to 493.408696, graph 1 nohead lw 2 lc rgb '#666666' dt 2
set arrow 2 from graph 0, 201.143478 to graph 1, 201.143478 nohead lw 2 lc rgb '#666666' dt 2
plot \
  'pair_09_direct_cntvaluein_bus_skew_idelay_data_cntvaluein_lane1_dq10_ctrl_none_dq10_value_ps_VS_skew_abs_lane1_minus_lane0_dqs_idelay_cntvaluein_skew_all_no_bit.dat' using 3:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'pair_09_direct_cntvaluein_bus_skew_idelay_data_cntvaluein_lane1_dq10_ctrl_none_dq10_value_ps_VS_skew_abs_lane1_minus_lane0_dqs_idelay_cntvaluein_skew_all_no_bit.dat' using 5:6 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
