#!/usr/bin/env bash
if [[ -z "$1" ]] ;
then
    echo "Usage: ./query.sh <source-file...>"
    exit
fi;
for var in "$@"
do
    source $var
done

THISHOST=$(hostname)
TIMESTAMP_START=$(date +%Y-%m-%d-%H-%M-%S)

for TIMEOUTQUERY in $TIMEOUTQUERIES; do
    if [[ -n $VERBOSE ]]; then
        echo "Timeouting $TIMEOUTQUERY"
    fi
    echo "select
  (\"Timeout!\" as ?timeout)
where {
?S ?P ?O
} 
limit 1" > $TIMEOUTQUERY
done

for CUBE in $CUBES; do
	for OPTIMIZATION in $OPTIMIZATIONS; do
		for SCALE in $SCALES; do
			for SEED in $SEEDS; do
				REPO=$CUBE"_"$OPTIMIZATION"_"$SCALE
				$BIBM/tpchdriver -uc ../../$LTPCH/virtuoso_open-source_7.1/queries/$OPTIMIZATION/$CUBE/ -seed $SEED -mt 1   -dg "http://extbi.lab.aau.dk/resource/ltpch/lineitem-cube/$OPTIMIZATION/$SCALE/" -printres "http://localhost:8890/sparql" 
				mkdir -p $LTPCH/logs/$THISHOST/virtuoso_open-source_7.1/$TIMESTAMP_START/$CUBE"_"$OPTIMIZATION"_"$SCALE"/"
				files=($LTPCH/benchmark_result.*)
				mv "${files[@]}" $LTPCH/logs/$THISHOST/virtuoso_open-source_7.1/$TIMESTAMP_START/$CUBE"_"$OPTIMIZATION"_"$SCALE"/"
				mv $LTPCH/run.log $LTPCH/logs/$THISHOST/virtuoso_open-source_7.1/"run_"$REPO"_"$SEED"_"$TIMESTAMP_START".log"
				grep -Pzo '(?s)Query [0-9]* of run [0-9]* has been executed in [0-9\.]*|Query results \([0-9]*.*?\)|queryname:[0-9]*|results:\[[^\]]..*? \],|results:\[\],' $LTPCH/logs/$THISHOST/virtuoso_open-source_7.1/"run_"$REPO"_"$SEED"_"$TIMESTAMP_START".log"| perl -pe 's/([0-9][0-9][0-9][0-9Ee]+)\.[0-9]*/$1/g' | perl -pe 's/([0-9]+\.[0-9Ee][0-9Ee][0-9Ee])[0-9]*/$1/g' > $LTPCH/logs/$THISHOST/virtuoso_open-source_7.1/$REPO"_"$SEED.tmp
			done
		done
	done
done

for TIMEOUTQUERY in $TIMEOUTQUERIES; do
    svn revert $TIMEOUTQUERY
done


