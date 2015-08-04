#!/usr/bin/env bash
if [[ -z "$1" ]] ;
then
    echo "Usage: ./size.sh <source-file...>"
    exit
fi;
for var in "$@"
do
    source $var
done

HOME=$BIBM/$EXTBI_RELATIVE_TO_BIBM/procedures/TPCH/

for CUBE in $CUBES ; do
    RESULT_FILE="size-$CUBE.csv"
    rm $RESULT_FILE
    echo -n '{Pattern}' >> $RESULT_FILE
    for SCALE in $SCALES; do
        echo -n ",{$SCALE}" >> $RESULT_FILE
    done
    for OPTIMIZATION in  $OPTIMIZATIONS ; do
        echo '' >> $RESULT_FILE
        echo -n $OPTIMIZATION | perl -pe 's/schema//' >> $RESULT_FILE
        for SCALE in $SCALES; do
            LOGGED_SCALE=$(echo "define int(x)   { auto os;os=scale;scale=0;x/=1;scale=os;return(x) }; int(l($SCALE)/l(10))" | bc -l)
            REPO=$CUBE"_sf"$LOGGED_SCALE"_"$OPTIMIZATION
            ls -la $REPO_BASE$REPO | head -n 1 |  perl -pe 's/total ([0-9\.]+).*\n/,$1/' >> $RESULT_FILE
        done
    done
done


