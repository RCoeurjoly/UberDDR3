set terminal pngcairo size 1200,720 enhanced font 'DejaVu Sans,10'
set output 'signed_baseline_abort2_vs_pass_skew_signed_dqs_bus_skew_minus_dq_median_idelay_cntvaluein_skew_lane0_dqs0_ctrl.png'
set datafile separator comma
set key outside right top
set grid ytics
set xrange [0.45:4.55]
set xtics ('pass' 1, 'fail-reason-2' 2, 'no-abort' 3, 'fail-other' 4)
set xlabel 'Hardware outcome class'
set ylabel 'SDF feature value (ps)'
set title 'signed_dqs_bus_skew_minus_dq_median__idelay_cntvaluein_skew__lane0__dqs0__ctrl_none__dqs_vs_dq_bus_skew__value_ps'
plot \
  'signed_baseline_abort2_vs_pass_skew_signed_dqs_bus_skew_minus_dq_median_idelay_cntvaluein_skew_lane0_dqs0_ctrl.summary.dat' using 1:4:3:5 with yerrorbars pt 9 ps 1.5 lw 3 lc rgb '#333333' title 'median + IQR', \
  'signed_baseline_abort2_vs_pass_skew_signed_dqs_bus_skew_minus_dq_median_idelay_cntvaluein_skew_lane0_dqs0_ctrl.dat' using 1:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'signed_baseline_abort2_vs_pass_skew_signed_dqs_bus_skew_minus_dq_median_idelay_cntvaluein_skew_lane0_dqs0_ctrl.dat' using 1:5 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
