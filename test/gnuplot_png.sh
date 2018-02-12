set term png size 1400,800
set output "CCC_all_frames.png"
plot "ccc_frames.txt" using 1:2 with lines notitle
replot
