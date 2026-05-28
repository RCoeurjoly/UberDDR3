set terminal pngcairo size 1200,840 enhanced font 'DejaVu Sans,9'
set output 'pair_07_skew_abs_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane1_dq11_ctrl_1_dqs_vs_dq_bit_value_ps_VS_skew_abs_lane1_minus_lane0_dqs_idelay_cntvaluein_skew_all_n.png'
set datafile separator comma
set key outside right top
set grid
set title 'rule 7: bal_acc=0.713884 errors=29'
set xlabel 'abs_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq11__ctrl_1__dqs_vs_dq_bit__value_ps (ps)'
set ylabel 'abs_lane1_minus_lane0_dqs__idelay_cntvaluein_skew__all__no_bit__ctrl_4__lane1_vs_lane0_dqs__value_ps (ps)'
set arrow 1 from 87.656522, graph 0 to 87.656522, graph 1 nohead lw 2 lc rgb '#666666' dt 2
set arrow 2 from graph 0, 201.143478 to graph 1, 201.143478 nohead lw 2 lc rgb '#666666' dt 2
plot \
  'pair_07_skew_abs_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane1_dq11_ctrl_1_dqs_vs_dq_bit_value_ps_VS_skew_abs_lane1_minus_lane0_dqs_idelay_cntvaluein_skew_all_n.dat' using 3:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'pair_07_skew_abs_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane1_dq11_ctrl_1_dqs_vs_dq_bit_value_ps_VS_skew_abs_lane1_minus_lane0_dqs_idelay_cntvaluein_skew_all_n.dat' using 5:6 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
