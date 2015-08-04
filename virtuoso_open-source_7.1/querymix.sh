#!/usr/bin/env bash
if [[ -z "$1" ]] ;
then
    echo "Usage: ./querymix.sh <source-file...>"
    exit
fi;
for var in "$@"
do
    source $var
done

  
for CUBE in $CUBES; do
  for OPTIMIZATION in $OPTIMIZATIONS; do
    ../source/querymix.txt >> "queries/"$OPTIMIZATION"/"$CUBE"/querymix.txt"
  done
done
    
