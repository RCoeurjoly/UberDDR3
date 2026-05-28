set terminal pngcairo size 1200,780 enhanced font 'DejaVu Sans,10'
set output 'delta_12.png'
set datafile separator comma
set key outside right top
set grid ytics
set xrange [0.45:4.55]
set xtics ('fail->pass' 1, 'pass->fail' 2, 'fail->fail' 3, 'pass->pass' 4)
set ylabel 'after - before feature delta'
set title 'signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq3__ctrl_0__dqs_vs_dq_bit__value_ps'
plot \
  'delta_12.dat' using 1:3 with points pt 7 ps 1.25 lc rgb '#1a9850' title 'fail->pass', \
  'delta_12.dat' using 1:4 with points pt 7 ps 1.25 lc rgb '#d73027' title 'pass->fail', \
  'delta_12.dat' using 1:5 with points pt 7 ps 1.1 lc rgb '#666666' title 'other'
