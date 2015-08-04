#!/bin/bash
if [[ -z $BIBM ]] ; then
    BIBM="/opt/bibm/"
fi;
if [[ -z $TPCH ]] ; then
    TPCH="/opt/tpch_2_16_1/"
fi;
if [[ -z $EXTBI ]] ; then
    EXTBI="/home/kim/Documents/EXTBI/"
fi;
if [[ -z $CUBES ]] ; then
    CUBES="lineitem-cube" #Do not change or add.
fi;
if [[ -z $SEEDS ]] ; then
    SEEDS="1 2 3 4 5 6"
#     SEEDS="99"
fi;
if [[ -z $LTPCH ]] ; then
    LTPCH="$EXTBI/ltpch/TPCH/"
fi;
if [[ -z $ONTOLOGY ]] ; then
    ONTOLOGY="$LTPCH/ontologies/tpc-h-qb4o.owl"
fi;

if [[ -z $DATASET ]] ; then
    DATASET="$LTPCH/dataset/"
fi;


export JAVA_ARGS="-Xmx8g -Xms4g"

VERBOSE="" ## Must be empty or -verbose 
SERVERADDR="127.0.0.1"
ISQLVT="/usr/local/virtuoso-opensource/bin/isql"
JENA="/usr/local/apache-jena-2.12.1/"
FUSEKI="/usr/local/jena-fuseki-1.1.1"
