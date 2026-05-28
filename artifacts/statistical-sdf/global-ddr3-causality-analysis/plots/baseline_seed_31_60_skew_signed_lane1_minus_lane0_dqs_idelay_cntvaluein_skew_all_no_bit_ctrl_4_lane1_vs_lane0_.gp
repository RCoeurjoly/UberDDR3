set terminal pngcairo size 1200,720 enhanced font 'DejaVu Sans,10'
set output 'baseline_seed_31_60_skew_signed_lane1_minus_lane0_dqs_idelay_cntvaluein_skew_all_no_bit_ctrl_4_lane1_vs_lane0_.png'
set datafile separator comma
set key outside right top
set grid
set xlabel 'Experiment index'
set ylabel 'Feature value (ps)'
set title 'signed_lane1_minus_lane0_dqs__idelay_cntvaluein_skew__all__no_bit__ctrl_4__lane1_vs_lane0_dqs__value_ps'
plot \
  'baseline_seed_31_60_skew_signed_lane1_minus_lane0_dqs_idelay_cntvaluein_skew_all_no_bit_ctrl_4_lane1_vs_lane0_.dat' using 1:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'baseline_seed_31_60_skew_signed_lane1_minus_lane0_dqs_idelay_cntvaluein_skew_all_no_bit_ctrl_4_lane1_vs_lane0_.dat' using 1:5 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
