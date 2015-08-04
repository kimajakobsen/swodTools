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


  echo "DELETE FROM DB.DBA.load_list;" | $ISQLVT $SERVERADDR $USER $PASS > /dev/null
