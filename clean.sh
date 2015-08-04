#!/usr/bin/env bash
##################################################################
# Right now this only clean up graphs. It should also clean up 
# the construct dir, datadir etc. Maybe make some settings which
# specify the stuff to be cleaned up-
##################################################################
if [[ -z "$1" ]] ;
then
    echo "Usage: ./clean.sh <source-file...>"
    exit
fi;
for var in "$@"
do
    source $var
done

for SCALE in $SCALES; do
	echo "removing $LTPCH/dataset/tpch-sf$SCALE-ttl-data/ "
	rm -fr $LTPCH/dataset/tpch-sf"$SCALE"-ttl-data/ 
done

rm -fr $LTPCH/construct/

for STORE in $STORES; do
	cd $LTPCH
   
    echo "Calling $STORE/clean.sh"
    ./$STORE/clean.sh $@
done

