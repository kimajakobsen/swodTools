#!/usr/bin/env bash
if [[ -z "$1" ]] ;
then
    echo "Usage: ./results.sh <source-file...>"
    exit
fi;
for var in "$@"
do
    source $var
done

RES_PER_FILE=2
if [[ -n $TEST ]]; then
    RES_PER_FILE=1
fi

rm tmp -f
TIMEOUT_TIME=1000
THISHOST=$(hostname)

for SCALE in $SCALES; do
    
    RESULT_FILE="results"$SCALE".csv"
    rm $RESULT_FILE
    echo -n "Cube,Query" >> $RESULT_FILE
    for OPTIMIZATION in  $OPTIMIZATIONS ; do
        QUERYMIX=0
        QUERYMIX_TO=$RES_PER_FILE
        for SEED in $SEEDS; do
            for RUN in `seq 0 $(echo "$RES_PER_FILE - 1" | bc -l)`; do
                QUERYMIX=$(echo "$QUERYMIX + 1" | bc -l)
                echo -n ",{"$OPTIMIZATION" "$QUERYMIX"}" >> $RESULT_FILE
            done
        done
        echo -n ",{"$OPTIMIZATION" avg(w/o max min)}" >> $RESULT_FILE
    done
    echo '' >> $RESULT_FILE
    for CUBE in $CUBES ; do
        for QUERY in $(ls $EXTBI/procedures/TPCH/queries/TPCH/snowflakeschema/$CUBE/ | egrep -o '[0-9]+' | sort -n); do
            echo "Query "$QUERY
            echo -n "{$CUBE},$QUERY" >> $RESULT_FILE
            for OPTIMIZATION in  $OPTIMIZATIONS ; do
                REPO=$CUBE"_sf"$SCALE"_"$OPTIMIZATION
                TIMEOUT=false
                for TIMEOUTQUERY in $TIMEOUTQUERIES; do
                    if [[ $(echo $TIMEOUTQUERY | egrep "$CUBE/$OPTIMIZATION/query$QUERY.txt") != "" ]]; then
                        echo "Found timeout: $REPO"_"$SEED Query $QUERY"
                        TIMEOUT=true
                    fi
                done
                for SEED in $SEEDS; do
                    echo $REPO"_"$SEED
                    for RUN in `seq 0 $(echo "$RES_PER_FILE - 1" | bc -l)`; do
                        QUERYMIX=$(echo "$QUERYMIX + 1" | bc -l)
                        if [[ $TIMEOUT = true ]]; then
                            echo '-1' >> tmp
                        else
                            grep -Pzo "(?s)Query $QUERY of run $RUN has been executed in [0-9\.]*" $EXTBI/procedures/TPCH/logs/$THISHOST/$REPO"_"$SEED.tmp | perl -pe "s/Query $QUERY of run $RUN has been executed in ([0-9\.]*)/\$1/" >> tmp
                        fi
                    done
                done
                gawk 'BEGIN{min=-1;max=-1}{
                        i = i + 1; 
                        if(max < 0)
                        {
                            max = $1
                        }
                        else if(min < 0)
                        {
                            min = $1
                            if(min > max)
                            {
                                tmp = min
                                min = max
                                max = tmp
                            }
                        }
                        else if($1 > max)
                        {
                            max = $1
                        }
                        else if($1 < min) 
                        {
                            min = $1
                        }
                        n = n + $1; 
                        printf ",%s", $1;
                    }
                    END{
                        if(i > 2)
                        {
                            printf ",%f", ((n-min-max)/(i-2));  
                        }
                        else
                        {
                            printf ",%f", (n)/(i);  
                        }
                    }' tmp >> $RESULT_FILE
                    rm tmp
            done
            echo '' >> $RESULT_FILE
        done
    done
    gawk -F',' 'FNR==1 {
            nf=NF
            for(i = 3 ; i<=nf ; i++) {
                sum[i] = 0.0
                mult[i] = 1.0
            }
        } {
            for(i = 3 ; i<=nf ; i++) {
                if(mult[i] == 0)
                {
                    mult[i] = 1
                }
                if($i > 0) 
                {
                    sum[i] += $i
                    mult[i] *= $i
                    num[i] += 1
                }
                else
                {
                    sum[i] += 1000
                    mult[i] *= 1000
                    num[i] += 1
                }
            }
        }
        END{
            printf "%s", "{Average},{Average}"
            for(i = 3 ; i<=nf ; i++) {
                printf ",%f", (sum[i]/num[i])
            }
            printf "\n%s", "{Geo. Mean},{Geo. Mean}"
            for(i = 3 ; i<=nf ; i++) {
                printf ",%f", (mult[i]^(1/num[i]))
            }
        }' $RESULT_FILE > tmp
        cat tmp >> $RESULT_FILE
        rm tmp -f
done
