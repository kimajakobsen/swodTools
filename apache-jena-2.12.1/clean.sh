#!/usr/bin/env bash
if [[ -z "$1" ]] ;
then
    echo "Usage: ./clean.sh <source-file...>"
    exit
fi;
for var in "$@"
do
    source $var
done


