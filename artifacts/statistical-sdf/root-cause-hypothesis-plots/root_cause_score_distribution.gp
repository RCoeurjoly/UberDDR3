set terminal pngcairo size 1100,760 enhanced font 'DejaVu Sans,10'
set output 'root_cause_score_distribution.png'
set datafile separator comma
set key outside right top
set grid ytics
set xrange [0.45:2.55]
set xtics ('pass' 1, 'fail' 2)
set xlabel 'Hardware outcome'
set ylabel 'combined margin-loss score z'
set title 'UberDDR3 root-cause hypothesis combined score distribution'
plot \
  'root_cause_score_distribution.dat' using 1:3 with points pt 7 ps 1.2 lc rgb '#1a9850' title 'pass', \
  'root_cause_score_distribution.dat' using 1:4 with points pt 7 ps 1.2 lc rgb '#d73027' title 'fail'
