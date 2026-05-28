set terminal pngcairo size 1200,840 enhanced font 'DejaVu Sans,9'
set output 'pair_08_skew_signed_lane1_minus_lane0_dq_median_idelay_cntvaluein_skew_all_no_bit_ctrl_2_lane1_vs_lane0_dq_value_ps_VS_skew_dq_lane_range_idelay_cntvaluein_skew.png'
set datafile separator comma
set key outside right top
set grid
set title 'rule 8: bal_acc=0.712758 errors=35'
set xlabel 'signed_lane1_minus_lane0_dq_median__idelay_cntvaluein_skew__all__no_bit__ctrl_2__lane1_vs_lane0_dq__value_ps (ps)'
set ylabel 'dq_lane_range__idelay_cntvaluein_skew__lane1__no_bit__ctrl_4__dq_lane__value_ps (ps)'
set arrow 1 from -406.092391, graph 0 to -406.092391, graph 1 nohead lw 2 lc rgb '#666666' dt 2
set arrow 2 from graph 0, 592.027174 to graph 1, 592.027174 nohead lw 2 lc rgb '#666666' dt 2
plot \
  'pair_08_skew_signed_lane1_minus_lane0_dq_median_idelay_cntvaluein_skew_all_no_bit_ctrl_2_lane1_vs_lane0_dq_value_ps_VS_skew_dq_lane_range_idelay_cntvaluein_skew.dat' using 3:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'pair_08_skew_signed_lane1_minus_lane0_dq_median_idelay_cntvaluein_skew_all_no_bit_ctrl_2_lane1_vs_lane0_dq_value_ps_VS_skew_dq_lane_range_idelay_cntvaluein_skew.dat' using 5:6 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
