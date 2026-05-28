set terminal pngcairo size 1300,880 enhanced font 'DejaVu Sans,10'
set output 'root_cause_raw_3factor.png'
set datafile separator comma
set key outside right top
set grid
set xlabel 'signed lane1-lane0 DQ median skew, ctrl2 (ps)'
set ylabel 'lane1 dq14 ctrl3 abs DQS-DQ skew (ps)'
set title 'UberDDR3 root-cause hypothesis: lane mismatch + DQS/DQ skew; point size = LD-CNTVALUEIN skew'
plot \
  'root_cause_raw_3factor.dat' using 4:5:6 with points pt 7 ps variable lc rgb '#1a9850' title 'pass', \
  'root_cause_raw_3factor.dat' using 7:8:9 with points pt 7 ps variable lc rgb '#d73027' title 'fail'
