#!/usr/bin/env bash
if [[ -z "$1" ]] ;
then
    echo "Usage: ./load.sh <source-file...>"
    exit
fi;
for var in "$@"
do
    source $var
done

  
for CUBE in $CUBES; do
  for OPTIMIZATION in $OPTIMIZATIONS; do
    for SCALE in $SCALES; do
      GRAPH_IRI='http://extbi.lab.aau.dk/resource/ltpch/'$CUBE'/'$OPTIMIZATION'/'$SCALE'/'
      STARTTIME=$(date +%s%3N)
      echo "sparql DROP SILENT GRAPH <$GRAPH_IRI>; " | $ISQLVT $SERVERADDR $USER $PASS
      ENDTIME=$(date +%s%3N)
      echo "drop $OPTIMIZATION ($SCALE): "$(expr $ENDTIME - $STARTTIME)"ms"
    done
        
  done
done
    



