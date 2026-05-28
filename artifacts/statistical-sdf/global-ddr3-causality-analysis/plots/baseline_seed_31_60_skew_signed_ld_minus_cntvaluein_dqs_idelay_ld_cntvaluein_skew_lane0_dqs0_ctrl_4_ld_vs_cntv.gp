set terminal pngcairo size 1200,720 enhanced font 'DejaVu Sans,10'
set output 'baseline_seed_31_60_skew_signed_ld_minus_cntvaluein_dqs_idelay_ld_cntvaluein_skew_lane0_dqs0_ctrl_4_ld_vs_cntv.png'
set datafile separator comma
set key outside right top
set grid
set xlabel 'Experiment index'
set ylabel 'Feature value (ps)'
set title 'signed_ld_minus_cntvaluein_dqs__idelay_ld_cntvaluein_skew__lane0__dqs0__ctrl_4__ld_vs_cntvaluein_dqs__value_ps'
plot \
  'baseline_seed_31_60_skew_signed_ld_minus_cntvaluein_dqs_idelay_ld_cntvaluein_skew_lane0_dqs0_ctrl_4_ld_vs_cntv.dat' using 1:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'baseline_seed_31_60_skew_signed_ld_minus_cntvaluein_dqs_idelay_ld_cntvaluein_skew_lane0_dqs0_ctrl_4_ld_vs_cntv.dat' using 1:5 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
