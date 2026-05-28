set terminal pngcairo size 1200,720 enhanced font 'DejaVu Sans,10'
set output 'baseline_abort2_vs_pass_direct_cntvaluein_bus_skew_idelay_data_cntvaluein_lane1_dq9_ctrl_none_dq9_value_ps.png'
set datafile separator comma
set key outside right top
set grid
set xlabel 'Experiment index'
set ylabel 'Feature value (ps)'
set title 'cntvaluein_bus_skew__idelay_data_cntvaluein__lane1__dq9__ctrl_none__dq9__value_ps'
plot \
  'baseline_abort2_vs_pass_direct_cntvaluein_bus_skew_idelay_data_cntvaluein_lane1_dq9_ctrl_none_dq9_value_ps.dat' using 1:4 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'baseline_abort2_vs_pass_direct_cntvaluein_bus_skew_idelay_data_cntvaluein_lane1_dq9_ctrl_none_dq9_value_ps.dat' using 1:5 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
