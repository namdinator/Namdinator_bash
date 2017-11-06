#module load rosetta_phenix_2016.32.58837

RES=5.9
LIMHIGH=5.0
LIMLOW=3.8

RES1=$(echo "($RES*10)" |bc | cut -d\. -f1)
LIM1=$(echo "($LIMHIGH*10)" |bc | cut -d\. -f1)
LIM2=$(echo "($LIMLOW*10)" |bc | cut -d\. -f1)

if [ "$RES1" -le  "$LIM1" ] && [ "$RES1" -ge "$LIM2" ]; then

    echo "resolution is between the two values"

elif [ "$RES1" -lt "$LIM2" ]; then
    
echo " Resolution is lower than low limit"

elif [ "$RES1" -gt  "$LIM1" ]; then
   
    echo " Resolution is HIGHER than limit"

else
    :
fi


