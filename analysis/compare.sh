#!/usr/bin/env bash
if [[ -z "$1" ]] ;
then
    echo "Usage: ./compare.sh <source-file...>"
    exit
fi;
for var in "$@"
do
    source $var
done

if [[ -z $THISHOST ]]; then
    THISHOST=$(hostname)
fi
HOME=$BIBM/$EXTBI_RELATIVE_TO_BIBM/procedures/TPCH/

for SCALE in $SCALES; do
    LOGGED_SCALE=$(echo "define int(x)   { auto os;os=scale;scale=0;x/=1;scale=os;return(x) }; int(l($SCALE)/l(10))" | bc -l)
    for CUBE in $CUBES ; do
        UNDERLYING_REPO=""
        for OPTIMIZATION in  $OPTIMIZATIONS ; do
            REPO=$CUBE"_sf"$LOGGED_SCALE"_"$OPTIMIZATION
            for SEED in $SEEDS; do
                if [[ "$UNDERLYING_REPO" != "" ]]; then
                    echo Comparing $UNDERLYING_REPO"_"$SEED and $REPO"_"$SEED
                    diff $BIBM/$EXTBI_RELATIVE_TO_BIBM/data/TPCH/$THISHOST/$UNDERLYING_REPO"_"$SEED.tmp $BIBM/$EXTBI_RELATIVE_TO_BIBM/data/TPCH/$THISHOST/$REPO"_"$SEED.tmp
                fi
            done
            UNDERLYING_REPO=$REPO
            if [[ -n $VERBOSE ]] ; then
                echo "New underlying repo: $UNDERLYING_REPO"
            fi
        done
    done
done
