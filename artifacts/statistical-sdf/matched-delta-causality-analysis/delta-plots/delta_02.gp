set terminal pngcairo size 1200,780 enhanced font 'DejaVu Sans,10'
set output 'delta_02.png'
set datafile separator comma
set key outside right top
set grid ytics
set xrange [0.45:4.55]
set xtics ('fail->pass' 1, 'pass->fail' 2, 'fail->fail' 3, 'pass->pass' 4)
set ylabel 'after - before feature delta'
set title 'signed_idelayctrl_minus_reset_release__startup_relative_skew__all__no_bit__ctrl_none__idelayctrl_vs_reset__value_ps'
plot \
  'delta_02.dat' using 1:3 with points pt 7 ps 1.25 lc rgb '#1a9850' title 'fail->pass', \
  'delta_02.dat' using 1:4 with points pt 7 ps 1.25 lc rgb '#d73027' title 'pass->fail', \
  'delta_02.dat' using 1:5 with points pt 7 ps 1.1 lc rgb '#666666' title 'other'
