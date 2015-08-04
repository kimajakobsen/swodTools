#!/usr/bin/env bash
if [[ -z "$1" ]] ;
then
    echo "Usage: ./generate.sh <source-file...>"
    exit
fi;
for var in "$@"
do
    source $var
done
#if [[ -n $VERBOSE ]]; then
  echo "EXTBI: $EXTBI"
  echo "OPTIMIZATIONS: $OPTIMIZATIONS"
  echo "CUBES: $CUBES"
  echo "SCALES: $SCALES"
  echo "LTPCH: $LTPCH"
  echo "DATASET: $DATASET"
#fi

#################################
#        default variables      #
#################################
files=(nation region customer part supplier partsupp orders lineitem)
THISHOST=$(hostname)
cleanup=true
#################################
#            throw errors       #
#################################

function checkExtbi 
{
  if [[ -z $EXTBI ]]; then
    echo "(-e) Path to extbi is not set"
    exit
  fi
}

function checkBibm 
{
  if [[ -z $BIBM ]]; then
    echo "(-b) BIBM path is not set"
    exit
  fi
  if [ ! -f $BIBM"/tpch/virtuoso/rdfh_schema.json" ]; then
    echo "Path to bibm directs to wrong location, cannot find the tpch_schema.json file, path given:"
    echo $BIBM"/tpch/virtuoso/rdfh_schema.json"
    exit
  fi
}

function checkTpch 
{
  if [[ -z $TPCH ]]; then
    echo "(-t) TPCH path is not set"
    exit
  fi
}

#################################
#        generate data          #
#################################
function generate_tbl
{


  cd "$TPCH"dbgen/

  if [[ -n $VERBOSE ]]; then 
    echo "generating data";
    ./dbgen -vf -s $SCALE
  else
    ./dbgen -f -s $SCALE > /dev/null
  fi

  mkdir -p $INPUT
  cd $INPUT
  for tbl_file in ${files[@]}
  do
    mv "$TPCH"dbgen/$tbl_file".tbl" .
  done
}

function convert_tbl_to_ttl
{
  if [[ -n $VERBOSE ]]; then  echo "convert to ttl"; fi
  
  cd $INPUT
  
  for tbl_file in ${files[@]}
  do
    
    if [[ -n $VERBOSE ]]; then
        printf $tbl_file"->ttl: "
        echo $BIBM/csv2ttl.sh -schema $BIBM"/tpch/virtuoso/rdfh_schema.json" -ext tbl $INPUT/$tbl_file".tbl"
        $BIBM/csv2ttl.sh -schema $BIBM"/tpch/virtuoso/rdfh_schema.json" -ext tbl $INPUT/$tbl_file".tbl" | grep ^Exec 

    else
        $BIBM/csv2ttl.sh -schema $BIBM"/tpch/virtuoso/rdfh_schema.json" -ext tbl $INPUT/$tbl_file".tbl" > /dev/null
    fi
    
    rm $INPUT/$tbl_file".tbl"
  done
}





#################################
#             main              #
#################################



mkdir -p $DATASET
checkTpch
checkBibm
checkExtbi

for SCALE in $SCALES; do
  INPUT="$DATASET/tpch-sf"$SCALE"-ttl-data/"
  if [[ ! -d $LTPCH/dataset/tpch-sf$SCALE-ttl-data/ ]]; then
    STARTTIME=$(date +%s%3N)
    generate_tbl
    ENDTIME=$(date +%s%3N)
    echo "Time generate ($SCALE): "$(expr $ENDTIME - $STARTTIME)"ms"

    STARTTIME=$(date +%s%3N)
    convert_tbl_to_ttl
    ENDTIME=$(date +%s%3N)
    echo "Time convert ($SCALE): "$(expr $ENDTIME - $STARTTIME)"ms"
  fi
  
  cd $EXTBI/ltpch/TPCH/


  ########################
  #       Cleanse        #

  for ttl_file in ${files[@]}; do
    INPUT="$DATASET/tpch-sf"$SCALE"-ttl-data/"
    sed -i s/xsd:dateTime/xsd:date/ $INPUT/$ttl_file".ttl"
    sed -i s%http://lod2.eu/schemas/rdfh#%http://extbi.lab.aau.dk/ontology/ltpch/%g $INPUT/$ttl_file".ttl"
    sed -i s%http://lod2.eu/schemas/rdfh-inst#%http://extbi.lab.aau.dk/resource/ltpch/%g $INPUT/$ttl_file".ttl"
    sed -i s/rdfh/ltpch/g $INPUT/$ttl_file".ttl"
  done
done

########################
#    stage virtuoso    #

for SCALE in $SCALES; do
  GRAPH_NAME="http://extbi.lab.aau.dk/resource/ltpch/stage/$SCALE/"
  
  DATASETDIR="$LTPCH/dataset/tpch-sf$SCALE-ttl-data/"
  
  echo "SPARQL CLEAR GRAPH  <$GRAPH_NAME>; " | $ISQLVT $SERVERADDR $USER $PASS > /dev/null
  STARTTIME=$(date +%s%3N)
  for file in $(ls $DATASETDIR); do
    if [[ -n $VERBOSE ]]; then
        echo "ld_dir ('$DATASETDIR', '$file', '$GRAPH_NAME');" 
        echo "ld_dir ('$DATASETDIR', '$file', '$GRAPH_NAME');" | $ISQLVT $SERVERADDR $USER $PASS 
    else
        echo "ld_dir ('$DATASETDIR', '$file', '$GRAPH_NAME');" | $ISQLVT $SERVERADDR $USER $PASS > /dev/null
    fi
  done
  echo "ld_dir ('$LTPCH/ontologies/', 'tpc-h-qb4o.owl', '$GRAPH_NAME');" | $ISQLVT $SERVERADDR $USER $PASS > /dev/null
  if [[ -n $VERBOSE ]]; then
    echo "rdf_loader_run();" | $ISQLVT $SERVERADDR $USER $PASS 
    echo "checkpoint;" | $ISQLVT $SERVERADDR $USER $PASS 
  else
    echo " rdf_loader_run ();" | $ISQLVT $SERVERADDR $USER $PASS > /dev/null
    echo "checkpoint;" | $ISQLVT $SERVERADDR $USER $PASS > /dev/null
  fi
  ENDTIME=$(date +%s%3N)
  echo "Time stage ($SCALE): "$(expr $ENDTIME - $STARTTIME)"ms"
done



##########################
# make construct queries #


  #statements


for CUBE in $CUBES; do
  for SCALE in $SCALES; do
    for OPTIMIZATION in $OPTIMIZATIONS; do
      FROM_PATH="$LTPCH/swod/generated/$OPTIMIZATION/$CUBE"
      TO_PATH="$LTPCH/construct/$CUBE/$OPTIMIZATION/$SCALE/"
      
      
      GRAPH="http://extbi.lab.aau.dk/resource/ltpch/$CUBE/$OPTIMIZATION/$SCALE/"

      if [[ ! -d $TO_PATH  ]]; then
        mkdir -p "$TO_PATH"
        for f in $(ls $FROM_PATH); do

          if [[ -n $VERBOSE ]]; then echo "generating $f construct script"; fi
          cp $FROM_PATH/$f $TO_PATH/$f
          if [[ $OPTIMIZATION == "snowflakeschema" ]]; then
            # This will become QB4OLAP
            sed -i -e '1,/where/s/where/from <http:\/\/extbi.lab.aau.dk\/resource\/ltpch\/stage\/'$SCALE'\/> where/g' $TO_PATH/$f
            sed -i 's@http://lod2.eu/schemas/rdfh-inst#@http://extbi.lab.aau.dk/resource/ltpch/@g' $TO_PATH/$f
            sed -i 's@construct@INSERT INTO <http://extbi.lab.aau.dk/resource/ltpch/QB4OLAP/'$SCALE'/> @g' $TO_PATH/$f
          fi
          if [[ $OPTIMIZATION == "starschema" || $OPTIMIZATION == "denormalizedschema" ]]; then
            #One sed to rule them all.
            sed -i -e 's/where/from <http:\/\/extbi.lab.aau.dk\/resource\/ltpch\/QB4OLAP\/'$SCALE'\/> where/g' -e 's@http://extbi.lab.aau.dk/ontology/ltpch-inst#@http://extbi.lab.aau.dk/resource/ltpch/@g' -e 's@OPTIONAL { BIND(?level3 as ?dim) . }@@g' -e 's@OPTIONAL { BIND(?level2 as ?dim) . }@@g' -e 's@OPTIONAL { BIND(?level4 as ?dim) . }@@g' $TO_PATH/$f

            #sed -i 's/where/from <http:\/\/extbi.lab.aau.dk\/resource\/ltpch\/QB4OLAP\/'$SCALE'\/> where/g' $TO_PATH/$f
            
            #sed -i 's@http://extbi.lab.aau.dk/ontology/ltpch-inst#@http://extbi.lab.aau.dk/resource/ltpch/@g' $TO_PATH/$f
            #sed -i 's@OPTIONAL { BIND(?level3 as ?dim) . }@@g' $TO_PATH/$f
            #sed -i 's@OPTIONAL { BIND(?level2 as ?dim) . }@@g' $TO_PATH/$f
            #sed -i 's@OPTIONAL { BIND(?level4 as ?dim) . }@@g' $TO_PATH/$f
          fi
          if [[ $OPTIMIZATION == "starschema" ]]; then
            sed -i 's@OPTIONAL { BIND(?level1 as ?dim) . }@BIND (COALESCE(?level1,?level2, ?level3, ?level4) AS ?dim)@g' $TO_PATH/$f
          fi
          if [[ $OPTIMIZATION == "denormalizedschema" ]]; then
            sed -i 's@OPTIONAL { BIND(?level1 as ?dim) . }@@g' $TO_PATH/$f
            sed -i 's@OPTIONAL { BIND(?level0 as ?dim) . }@BIND (COALESCE(?level0,?level1,?level2, ?level3, ?level4) AS ?dim)@g' $TO_PATH/$f
          fi
          
          #One sed to rule them all.
          sed -i -e 's@http://extbi.lab.aau.dk/ontology/ltpch-inst#@http://extbi.lab.aau.dk/resource/ltpch/@g' -e 's@http://lod2.eu/schemas/rdfh#@http://extbi.lab.aau.dk/ontology/ltpch/@g' -e 's@http://lod2.eu/schemas/rdfh@http://extbi.lab.aau.dk/resource/ltpch@g' -e '1s/^/SPARQL DEFINE sql:log-enable 0 /' -e 's@prefix bif:@@g' -e 's@<http://example.org/customfunction/>@@g' -e 's@SUBSTR(STR(?part),38)@SUBSTR(STR(?part),44)@g' -e 's@SUBSTR(STR(?supp),42)@SUBSTR(STR(?supp),48)@g' -e 's@URI@IRI@g' -e 's@prefix rdfh-inst:@prefix ltpch-inst:@g' -e 's@prefix rdfh:@prefix ltpch:@g' -e 's@http://extbi.lab.aau.dk/ontology/ltpch#@http://extbi.lab.aau.dk/ontology/ltpch/@g' $TO_PATH/$f

          #sed -i 's@http://extbi.lab.aau.dk/ontology/ltpch-inst#@http://extbi.lab.aau.dk/resource/ltpch/@g' $TO_PATH/$f
          #sed -i 's@http://lod2.eu/schemas/rdfh#@http://extbi.lab.aau.dk/ontology/ltpch/@g' $TO_PATH/$f
          #sed -i 's@http://lod2.eu/schemas/rdfh@http://extbi.lab.aau.dk/resource/ltpch@g' $TO_PATH/$f
          #sed -i '1s/^/SPARQL DEFINE sql:log-enable 0 /' $TO_PATH/$f
          #sed -i 's@prefix bif:@@g' $TO_PATH/$f
          #sed -i 's@<http://example.org/customfunction/>@@g' $TO_PATH/$f

          #sed -i 's@SUBSTR(STR(?part),38)@SUBSTR(STR(?part),44)@g' $TO_PATH/$f
          #sed -i 's@SUBSTR(STR(?supp),42)@SUBSTR(STR(?supp),48)@g' $TO_PATH/$f
          
          #sed -i 's@URI@IRI@g' $TO_PATH/$f
          #sed -i 's@prefix rdfh-inst:@prefix ltpch-inst:@g' $TO_PATH/$f
          #sed -i 's@prefix rdfh:@prefix ltpch:@g' $TO_PATH/$f

          #sed -i 's@http://extbi.lab.aau.dk/ontology/ltpch#@http://extbi.lab.aau.dk/ontology/ltpch/@g' $TO_PATH/$f
          
          echo ";" >> $TO_PATH/$f
        done
      fi
      ##### make QB4OLAP #####
      if [[ $OPTIMIZATION == "snowflakeschema" ]]; then
        if [[ ! -d $LTPCH/construct/$CUBE/QB4OLAP/$SCALE/  ]]; then
        mkdir -p $LTPCH"/construct/"$CUBE"/"QB4OLAP"/"$SCALE"/" 
        for file in $(ls $TO_PATH ); do
          cp $TO_PATH/$file $LTPCH"/construct/"$CUBE"/"QB4OLAP"/"$SCALE"/"$file 
        done
        
        rm -f $TO_PATH/*
        echo "SPARQL construct {?s ?p ?o} from <http://extbi.lab.aau.dk/resource/ltpch/QB4OLAP/$SCALE/> where {?s ?p ?o};" > "$TO_PATH/all.spql"
        fi
      fi
    done
  done
done


#########################
# Run Construct queries #


for CUBE in $CUBES; do
  for SCALE in $SCALES; do

    echo "SPARQL CLEAR GRAPH  <http://extbi.lab.aau.dk/resource/ltpch/QB4OLAP/$SCALE/>; " | $ISQLVT $SERVERADDR $USER $PASS > /dev/null
  	STARTTIME=$(date +%s%3N)
    if [[ -n $VERBOSE ]]; then echo "construct the QB4OLAP cube"; fi
    for file in $(ls $LTPCH/construct/$CUBE/QB4OLAP/$SCALE/); do
      if [[ -n $VERBOSE ]]; then
        cat "$LTPCH/construct/$CUBE/QB4OLAP/$SCALE/$file" | $ISQLVT $SERVERADDR $USER $PASS | tail -n+6 
      else
        cat "$LTPCH/construct/$CUBE/QB4OLAP/$SCALE/$file" | $ISQLVT $SERVERADDR $USER $PASS > /dev/null
      fi
    done
    ENDTIME=$(date +%s%3N)
    echo "Time QB4OLAP ($SCALE): "$(expr $ENDTIME - $STARTTIME)"ms"
    if [[ -n $VERBOSE ]]; then echo "SPARQL select count(*) from <http://extbi.lab.aau.dk/resource/ltpch/QB4OLAP/$SCALE/> where {?a ?c ?b};" | $ISQLVT $SERVERADDR $USER $PASS | tail -n+6 ; fi
    for OPTIMIZATION in $OPTIMIZATIONS; do
      TO_PATH="$LTPCH/construct/$CUBE/$OPTIMIZATION/$SCALE/"
      if [[ -n $VERBOSE ]]; then echo "dumping $OPTIMIZATION" ; fi
      STARTTIME=$(date +%s%3N)
      for file in $(ls $TO_PATH/); do
        if [[ -n $VERBOSE ]]; then echo "Running script $file and saves on disk as $file.nt" ; fi
        mkdir -p "$LTPCH/dataset/$CUBE"_"$OPTIMIZATION"_"$SCALE"
        cat "$TO_PATH/$file" | $ISQLVT $SERVERADDR $USER $PASS | tail -n+8 | head -n -2 >$LTPCH/dataset/$CUBE"_"$OPTIMIZATION"_"$SCALE/$file.nt
        sed -e "s@\(http://\S\+\)@\<\1\>@g" -e "s@\(^<[^>]*>  <[^>]*>  \)\([^<].*$\|<.\{0,7\}$\|<\([^h]\|h[^t]\|ht[^t]\|htt[^p]\|http[^:]\|http:[^/]\|http:/[^/]\).*$\)@\1\"\2\"@g"         -e "s@\([^\.]\)[ \t]*\$@\1\.@g"          $LTPCH/dataset/$CUBE"_"$OPTIMIZATION"_"$SCALE/$file.nt >         $LTPCH/dataset/$CUBE"_"$OPTIMIZATION"_"$SCALE/$file.nt.tmp &&         mv $LTPCH/dataset/$CUBE"_"$OPTIMIZATION"_"$SCALE/$file.nt.tmp $LTPCH/dataset/$CUBE"_"$OPTIMIZATION"_"$SCALE/$file.nt
      done
      ENDTIME=$(date +%s%3N)
      echo "Time $OPTIMIZATION ($SCALE): "$(expr $ENDTIME - $STARTTIME)"ms"
    done
  done
done


#########################
# Cleaning up          #


for CUBE in $CUBES; do
  for SCALE in $SCALES; do
    for OPTIMIZATION in $OPTIMIZATIONS; do
      DATADIR=$LTPCH"/dataset/"$CUBE"_"$OPTIMIZATION"_"$SCALE
      rm -f $DATADIR/data.nt
      for file in $(ls $DATADIR); do
        cat $DATADIR/$file >> $DATADIR/data.nt
        rm -f $DATADIR/$file
      done
    done
  done
done


