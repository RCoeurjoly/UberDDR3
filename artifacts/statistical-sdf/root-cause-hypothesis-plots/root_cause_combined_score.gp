set terminal pngcairo size 1300,880 enhanced font 'DejaVu Sans,10'
set output 'root_cause_combined_score.png'
set datafile separator comma
set key outside right top
set grid
set xlabel 'capture/lane score z = z(DQS-DQ) + z(lane mismatch)'
set ylabel 'LD-CNTVALUEIN score z'
set title 'UberDDR3 combined IDELAY programming/capture margin hypothesis'
set arrow 1 from 0, graph 0 to 0, graph 1 nohead lw 2 lc rgb '#777777' dt 2
set arrow 2 from graph 0, 0 to graph 1, 0 nohead lw 2 lc rgb '#777777' dt 2
plot \
  'root_cause_combined_score.dat' using 3:4 with points pt 7 ps 1.25 lc rgb '#1a9850' title 'pass', \
  'root_cause_combined_score.dat' using 5:6 with points pt 7 ps 1.25 lc rgb '#d73027' title 'fail'
