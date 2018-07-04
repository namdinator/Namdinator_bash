set terminal dumb 110 35
unset xtics
plot "ccc_frames.txt" using 1:2 w points pt "*" notitle
