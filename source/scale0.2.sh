if [[ -n $SCALES ]]; then
    SCALES="$SCALES 0.2"
else
    SCALES="0.2"
fi
if [[ -z $TIMEOUTQUERIES ]] ; then
TIMEOUTQUERIES="
apache-jena-2.12.1/queries/snowflakeschema/lineitem-cube/query20.txt
apache-jena-2.12.1/queries/denormalizedschema/lineitem-cube/query15.txt
virtuoso_open-source_7.1/queries/snowflakeschema/lineitem-cube/query10.txt 
apache-jena-2.12.1/queries/starschema/lineitem-cube/query20.txt
apache-jena-2.12.1/queries/denormalizedschema/lineitem-cube/query20.txt"

fi;
