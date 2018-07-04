set terminal dumb 110 35
unset xtics 
plot "all_frames_clash.txt" using 2:xtic(1) w points pt "*" notitle
