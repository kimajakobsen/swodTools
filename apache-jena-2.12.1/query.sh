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

THISHOST=$(hostname)
TIMESTAMP_START=$(date +%Y-%m-%d-%H-%M-%S)


for CUBE in $CUBES; do
	for OPTIMIZATION in $OPTIMIZATIONS; do
		for SCALE in $SCALES; do
			for SEED in $SEEDS; do
				IRI=$CUBE'/'$OPTIMIZATION'/'$SCALE'/'
				REPO=$CUBE"_"$OPTIMIZATION"_"$SCALE
				echo "using tdb /tdb/$IRI/"
				#screen -dmS $SESSIONNAME bash -c 'echo waiting 5 senconds...; sleep 5; cd $FUSEKI; source fuseki-server --loc=/tdb/$IRI/ /$IRI'               
				$BIBM/tpchdriver -uc ../../$LTPCH/apache-jena-2.12.1/queries/$OPTIMIZATION/$CUBE/ -seed $SEED -mt 1  -printres "http://172.19.1.103:3030/$CUBE/$OPTIMIZATION/$SCALE/sparql" 
				mkdir -p $LTPCH/logs/$THISHOST/apache-jena-2.12.1/$TIMESTAMP_START/$CUBE"_"$OPTIMIZATION"_"$SCALE"/"
				files=($LTPCH/benchmark_result.*)
				mv "${files[@]}" $LTPCH/logs/$THISHOST/apache-jena-2.12.1/$TIMESTAMP_START/$CUBE"_"$OPTIMIZATION"_"$SCALE"/"
				mv $LTPCH/run.log $LTPCH/logs/$THISHOST/apache-jena-2.12.1/"run_"$REPO"_"$SEED"_"$TIMESTAMP_START".log"
				grep -Pzo '(?s)Query [0-9]* of run [0-9]* has been executed in [0-9\.]*|Query results \([0-9]*.*?\)|queryname:[0-9]*|results:\[[^\]]..*? \],|results:\[\],' $LTPCH/logs/$THISHOST/apache-jena-2.12.1/"run_"$REPO"_"$SEED"_"$TIMESTAMP_START".log"| perl -pe 's/([0-9][0-9][0-9][0-9Ee]+)\.[0-9]*/$1/g' | perl -pe 's/([0-9]+\.[0-9Ee][0-9Ee][0-9Ee])[0-9]*/$1/g' > $LTPCH/logs/$THISHOST/apache-jena-2.12.1/$REPO"_"$SEED.tmp
			done
		done
	done
done


for TIMEOUTQUERY in $TIMEOUTQUERIES; do
    svn revert $TIMEOUTQUERY
done