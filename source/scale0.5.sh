if [[ -n $SCALES ]]; then
    SCALES="$SCALES 0.5"
else
    SCALES="0.5"
fi
if [[ -z $TIMEOUTQUERIES ]] ; then
TIMEOUTQUERIES="
apache-jena-2.12.1/queries/snowflakeschema/lineitem-cube/query20.txt
apache-jena-2.12.1/queries/starschema/lineitem-cube/query20.txt
apache-jena-2.12.1/queries/denormalizedschema/lineitem-cube/query20.txt
apache-jena-2.12.1/queries/denormalizedschema/lineitem-cube/query15.txt
apache-jena-2.12.1/queries/starschema/lineitem-cube/query15.txt
virtuoso_open-source_7.1/queries/snowflakeschema/lineitem-cube/query10.txt"
fi;

#   TIMEOUTQUERIES="apache-jena-2.12.1/queries/snowflakeschema/lineitem-cube/query17.txt apache-jena-2.12.1/queries/starschema/lineitem-cube/query17.txt apache-jena-2.12.1/queries/denormalizedschema/lineitem-cube/query17.txt apache-jena-2.12.1/queries/snowflakeschema/lineitem-cube/query4.txt apache-jena-2.12.1/queries/snowflakeschema/lineitem-cube/query17.txt virtuoso_open-source_7.1/queries/snowflakeschema/lineitem-cube/query21.txt virtuoso_open-source_7.1/queries/snowflakeschema/lineitem-cube/query9.txt virtuoso_open-source_7.1/queries/snowflakeschema/lineitem-cube/query10.txt virtuoso_open-source_7.1/queries/snowflakeschema/lineitem-cube/query2.txt virtuoso_open-source_7.1/queries/snowflakeschema/lineitem-cube/query20.txt apache-jena-2.12.1/queries/snowflakeschema/lineitem-cube/query20.txt  apache-jena-2.12.1/queries/starschema/lineitem-cube/query20.txt apache-jena-2.12.1/queries/denormalizedschema/lineitem-cube/query20.txt apache-jena-2.12.1/queries/denormalizedschema/lineitem-cube/query13.txt apache-jena-2.12.1/queries/denormalizedschema/lineitem-cube/query15.txt"
