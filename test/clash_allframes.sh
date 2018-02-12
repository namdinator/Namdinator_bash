#!/bin/bash

for i in $(ls -1v frame*.pdb); do

    f=$(echo $i| cut -d\. -f1)
    
    sed -e "s/\ [0,1]\.00\ \ 0.00\ /\ 1.00\ 20\.00\ /g" $i > $f-bf.pdb
done

NUM=0
for i in $(ls -1v frame*-bf.pdb); do
    NUM=$(( $NUM + 1 ))
    f=$(echo $i| cut -d\. -f1)

    while [ $(pgrep -f clashscore.py | wc -l) -ge 2 ]; do
    sleep 1
    done

    phenix.clashscore $i > $f.log & pids[${NUM}]=$!
done

for pid in ${pids[*]}; do
    wait $pid     
done

done
ls -1v frame*-bf.log | xargs -d '\n' grep "clashscore" | sed -e "s/:clashscore =//g" | sed -e 's/-bf.log/.pdb/g' > all_frames_clash.txt

