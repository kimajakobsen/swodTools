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

for STORE in $STORES; do
	cd $LTPCH
    echo "Calling $STORE/drop.sh"
    ./$STORE/drop.sh $@

done

