#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -e $DIR/fakelog ]; then
rm $DIR/fakelog
fi

END=${1:-0}
DATE=${2:-$(date)}
echo $DATE
for (( c=0; c<=$END; c++ ))
do
    # Hour increment
    m=$(( $c * 1440 ))
    #echo $m
    for j in {0..4}; do
        echo "fakeuser${j} $RANDOM $RANDOM $RANDOM $RANDOM $RANDOM $RANDOM fakecluster $(date -d "$DATE $m minutes" +%Y-%m-%d) $(date -d "$DATE $m minutes" +%H:%M:%S)" \
        >> $DIR/fakelog
    done
done


# Convert to CSV format (Easier to stick into sqlite3 db)
# FIRST: single quotations for every column; SECOND: commas between columns; THIRD: brackets ( ) for each line and add comma at the end
cat $DIR/fakelog | sed -r 's/[^ ]+/\x27&\x27/g' | awk '{$1=$1}1' OFS="," | awk '{print "("$0"),"}' > $DIR/fakelog2
logData=$( cat $DIR/fakelog2 )
echo ${logData::-1} > $DIR/../log

