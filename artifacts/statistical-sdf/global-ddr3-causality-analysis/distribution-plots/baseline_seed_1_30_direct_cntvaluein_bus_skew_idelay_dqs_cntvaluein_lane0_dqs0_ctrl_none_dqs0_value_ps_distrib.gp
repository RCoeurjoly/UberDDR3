set terminal pngcairo size 1200,720 enhanced font 'DejaVu Sans,10'
set output 'baseline_seed_1_30_direct_cntvaluein_bus_skew_idelay_dqs_cntvaluein_lane0_dqs0_ctrl_none_dqs0_value_ps_distrib.png'
set datafile separator comma
set key outside right top
set grid ytics
set xrange [0.45:4.55]
set xtics ('pass' 1, 'fail-reason-2' 2, 'no-abort' 3, 'fail-other' 4)
set xlabel 'Hardware outcome class'
set ylabel 'SDF feature value (ps)'
set title 'cntvaluein_bus_skew__idelay_dqs_cntvaluein__lane0__dqs0__ctrl_none__dqs0__value_ps'
plot \
  'baseline_seed_1_30_direct_cntvaluein_bus_skew_idelay_dqs_cntvaluein_lane0_dqs0_ctrl_none_dqs0_value_ps_distrib.summary.dat' using 1:4:3:5 with yerrorbars pt 9 ps 1.5 lw 3 lc rgb '#333333' title 'median + IQR', \
  'baseline_seed_1_30_direct_cntvaluein_bus_skew_idelay_dqs_cntvaluein_lane0_dqs0_ctrl_none_dqs0_value_ps_distrib.dat' using 1:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'baseline_seed_1_30_direct_cntvaluein_bus_skew_idelay_dqs_cntvaluein_lane0_dqs0_ctrl_none_dqs0_value_ps_distrib.dat' using 1:5 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
