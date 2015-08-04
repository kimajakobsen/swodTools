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


for STORE in $STORES; do
    ./"$STORE"/query.sh $@
done
