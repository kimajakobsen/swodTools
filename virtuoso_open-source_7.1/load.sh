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

  
echo "log_enable (2);" | $ISQLVT $SERVERADDR $USER $PASS 
echo "DELETE FROM DB.DBA.load_list;" | $ISQLVT $SERVERADDR $USER $PASS 
for CUBE in $CUBES; do
  for OPTIMIZATION in $OPTIMIZATIONS; do
    for SCALE in $SCALES; do
      GRAPH_IRI='http://extbi.lab.aau.dk/resource/ltpch/'$CUBE'/'$OPTIMIZATION'/'$SCALE'/'
     # echo "SPARQL CLEAR GRAPH  <$GRAPH_IRI>; " | $ISQLVT $SERVERADDR $USER $PASS | tail -n+6 | egrep -v '^(Done\. --.*)?$' | head -n-1
      STARTTIME=$(date +%s%3N)
      DATASET_DIR="$LTPCH/dataset/"$CUBE"_"$OPTIMIZATION"_"$SCALE"/"
      ONTOLOGY_DIR="$LTPCH/ontologies/"
      ONTOLOGY_NAME="tpc-h-qb4o.owl"
      #if [[ -n $VERBOSE ]]; then
        echo $GRAPH_IRI
        echo $DATASET_DIR
      #fi
      echo "ld_dir ('$DATASET_DIR', 'data.nt', '$GRAPH_IRI');" | $ISQLVT $SERVERADDR $USER $PASS 
      echo "ld_dir ('$ONTOLOGY_DIR', '$ONTOLOGY_NAME', '$GRAPH_IRI');" | $ISQLVT $SERVERADDR $USER $PASS 
      echo "rdf_loader_run();" | $ISQLVT $SERVERADDR $USER $PASS 
      echo "checkpoint;" | $ISQLVT $SERVERADDR $USER $PASS  
      ENDTIME=$(date +%s%3N)
      echo "Time load $OPTIMIZATION ($SCALE): "$(expr $ENDTIME - $STARTTIME)"ms"
    done
        
  done
done
    
