#!/usr/bin/env bash
if [[ -z "$1" ]] ;
then
    echo "Usage: ./triples.sh <source-file...>"
    exit
fi;
for var in "$@"
do
    source $var
done

sudo service tomcat7 stop

for CUBE in $CUBES ; do
    RESULT_FILE="triples-$CUBE.csv"
    rm $RESULT_FILE
    echo -n '{Pattern}' >> $RESULT_FILE
    for SCALE in $SCALES; do
        echo -n ",{$SCALE}" >> $RESULT_FILE
    done
    for OPTIMIZATION in  $OPTIMIZATIONS ; do
        echo '' >> $RESULT_FILE
        echo -n $OPTIMIZATION | perl -pe 's/schema//' >> $RESULT_FILE
        for SCALE in $SCALES; do
            LOGGED_SCALE=$(echo "define int(x)   { auto os;os=scale;scale=0;x/=1;scale=os;return(x) }; int(l($SCALE)/l(10))" | bc -l)
            REPO=$CUBE"_sf"$LOGGED_SCALE"_"$OPTIMIZATION
            if [[ -n $VERBOSE ]]; then
                echo java $JAVA_ARGS -jar $EXTBI"/bin/sesam-1.1-jar-with-dependencies.jar" --test $REPO_BASE$REPO 
            fi
            java $JAVA_ARGS -jar $EXTBI"/bin/sesam-1.1-jar-with-dependencies.jar" --test $REPO_BASE$REPO | egrep -o "^\"[0-9]+\""| perl -pe 's/[^0-9]*([0-9]*)[^0-9]*/,$1/'  >> $RESULT_FILE
        done
    done
done
