set terminal pngcairo size 1200,720 enhanced font 'DejaVu Sans,10'
set output 'signed_baseline_seed_31_60_skew_signed_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane0_dq5_ctrl_0_dqs_vs_dq_bit_.png'
set datafile separator comma
set key outside right top
set grid ytics
set xrange [0.45:4.55]
set xtics ('pass' 1, 'fail-reason-2' 2, 'no-abort' 3, 'fail-other' 4)
set xlabel 'Hardware outcome class'
set ylabel 'SDF feature value (ps)'
set title 'signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq5__ctrl_0__dqs_vs_dq_bit__value_ps'
plot \
  'signed_baseline_seed_31_60_skew_signed_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane0_dq5_ctrl_0_dqs_vs_dq_bit_.summary.dat' using 1:4:3:5 with yerrorbars pt 9 ps 1.5 lw 3 lc rgb '#333333' title 'median + IQR', \
  'signed_baseline_seed_31_60_skew_signed_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane0_dq5_ctrl_0_dqs_vs_dq_bit_.dat' using 1:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'signed_baseline_seed_31_60_skew_signed_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane0_dq5_ctrl_0_dqs_vs_dq_bit_.dat' using 1:5 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
