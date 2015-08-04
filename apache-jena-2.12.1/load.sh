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
      IRI=$CUBE'/'$OPTIMIZATION'/'$SCALE'/'
      rm /tdb/$IRI/* -f
      mkdir /tdb/$IRI -p
      
      DATASET_DIR="$LTPCH/dataset/"$CUBE"_"$OPTIMIZATION"_"$SCALE"/"
      
      STARTTIME=$(date +%s%3N)
      $JENA/bin/tdbloader2 -loc /tdb/$IRI $DATASET_DIR/data.nt #$ONTOLOGY
      ENDTIME=$(date +%s%3N)
      echo "Time load $OPTIMIZATION ($SCALE): "$(expr $ENDTIME - $STARTTIME)"ms"
    done
        
  done
done
    
