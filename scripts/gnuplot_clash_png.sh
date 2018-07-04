
set autoscale
set term png
set xtics rotate
set output "clash_all_frames.png"
plot "all_frames_clash.txt" using 2:xtic(1) with lines notitle
replot
