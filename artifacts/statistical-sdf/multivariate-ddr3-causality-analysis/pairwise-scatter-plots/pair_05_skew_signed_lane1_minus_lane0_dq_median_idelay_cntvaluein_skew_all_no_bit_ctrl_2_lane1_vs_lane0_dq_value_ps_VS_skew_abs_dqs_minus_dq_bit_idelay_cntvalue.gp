set terminal pngcairo size 1200,840 enhanced font 'DejaVu Sans,9'
set output 'pair_05_skew_signed_lane1_minus_lane0_dq_median_idelay_cntvaluein_skew_all_no_bit_ctrl_2_lane1_vs_lane0_dq_value_ps_VS_skew_abs_dqs_minus_dq_bit_idelay_cntvalue.png'
set datafile separator comma
set key outside right top
set grid
set title 'rule 5: bal_acc=0.71576 errors=27'
set xlabel 'signed_lane1_minus_lane0_dq_median__idelay_cntvaluein_skew__all__no_bit__ctrl_2__lane1_vs_lane0_dq__value_ps (ps)'
set ylabel 'abs_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq14__ctrl_3__dqs_vs_dq_bit__value_ps (ps)'
set arrow 1 from -441.85, graph 0 to -441.85, graph 1 nohead lw 2 lc rgb '#666666' dt 2
set arrow 2 from graph 0, 321.880435 to graph 1, 321.880435 nohead lw 2 lc rgb '#666666' dt 2
plot \
  'pair_05_skew_signed_lane1_minus_lane0_dq_median_idelay_cntvaluein_skew_all_no_bit_ctrl_2_lane1_vs_lane0_dq_value_ps_VS_skew_abs_dqs_minus_dq_bit_idelay_cntvalue.dat' using 3:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'pair_05_skew_signed_lane1_minus_lane0_dq_median_idelay_cntvaluein_skew_all_no_bit_ctrl_2_lane1_vs_lane0_dq_value_ps_VS_skew_abs_dqs_minus_dq_bit_idelay_cntvalue.dat' using 5:6 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
