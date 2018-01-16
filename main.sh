#!/bin/bash

# Directory of this file
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Requires user to add lines to the <input> file
# Format of file: hostname script
usernames=( $(cat $DIR/input | cut -d ' ' -f1) )
names=( $(cat $DIR/input | cut -d' ' -f2) )
hostnames=( $(cat $DIR/input | cut -d' ' -f3) )
scripts=( $(cat $DIR/input | cut -d' ' -f4) )

# Parse Users File and Create an Array of Lab Member Username Queries
lab=( $(cat $DIR/users | grep = | grep -v 'end') )
LAB=()
for lm in "${lab[@]}"; do
   _temp=$(sed -n "/${lm}/,/=/p" < $DIR/users | sed '1d;$d')
   for t in "${_temp[@]}"; do
        LAB+=($t)
   done
done

# Make Temporary Directory to House Files
if [ ! -d $DIR/tmp ]; then
    mkdir $DIR/tmp
fi

# Clear Cache (so previous results aren't repeated)
if [ "$(ls -A $DIR/tmp)" ]; then
    rm $DIR/tmp/*
fi

for ((i=0; i<${#usernames[@]}; ++i)); do
    user=$(   echo "${usernames[i]}" )
    name=$(   echo "${names[i]}" )
    host=$(   echo "${hostnames[i]}" )
    script=$( echo "${scripts[i]}"   )

    # Run check and data retrieval in background for each cluster
    # Connection: Timeout after 60 s (connect, job queue)
    # Single connection attempt per host
    {
    echo "Connection attempt to host: $host"
    timeout 60 ssh -oBatchMode=yes -q -l $user $host "bash -s" \
    < $DIR/scripts/$script $name "${LAB[@]}" > $DIR/tmp/$host

    # Check for file after connection attempt (cache clear ability)
    # Could check connection with $? but too many output option uncertainties
    if [ -e $DIR/tmp/$host ]; then
        echo "Connection Success: $host"
	if [ $(wc -l < $DIR/tmp/$host) -eq 0 ]; then
	    echo "Nothing in file (FAIL): $host"
            $DIR/scripts/fail $name "${LAB[@]}" > $DIR/tmp/$host
        fi
    # Output default result file (all 0's)
    else
      echo "Connection Failed: $host"
      $DIR/scripts/fail $name "${LAB[@]}" > $DIR/tmp/$host
    fi
    } &
done
wait

# Make combined file and cat with organized columns
if [ $(ls tmp/* 2>/dev/null | wc -l) -ne 0 ]; then
    for f in $DIR/tmp/*; do
        (cat "${f}" ; echo '...') >> $DIR/tmp/summary.txt
    done

    # Print to Console
    cat $DIR/tmp/summary.txt | column -t

    # Append Data to Log Files
    for ((i=0; i<${#usernames[@]}; ++i)); do
        {
        user=$(   echo "${usernames[i]}" )
        name=$(   echo "${names[i]}" )
        host=$(   echo "${hostnames[i]}" )
        script=$( echo "${scripts[i]}"   )

        line=$(awk '/=/{ print NR; exit }' $DIR/tmp/$host)
        tail --line=+$((${line} + 5)) $DIR/tmp/$host | head -n -2 \
        >> $DIR/tmp/_log1
        } &
    done
    wait
    # Replace usernames with real names (contains underscores still)
    # For each lab member: map usernames and reduce rows (summation)
    for lm in "${lab[@]}"; do
      {
       _temp=$(sed -n "/${lm}/,/=/p" < users | sed '1d;$d')
       LM=$(for i in ${_temp[@]}; do echo -ne "${i}\\|" ; done)

       cat $DIR/tmp/_log1 | grep "${LM%??}" | awk -v var=${lm:1:-1} 'NF \
       {a[$8]+=$2} {b[$8]+=$3} \
       {c[$8]+=$4} {d[$8]+=$5} \
       {e[$8]+=$6} {f[$8]+=$7} \
       END{for(i in a) \
       print var," ",a[i]," ",b[i]," ",c[i]," ",d[i]," ",e[i]," ",f[i]," ",i}' \
       >> $DIR/tmp/_log2
      } &
    done
    wait

    # Add the current date and time on this machine to each line
    cat tmp/_log2 | awk '{print $0" '$(date +%Y-%m-%d)' '$(date +%H:%M:%S)'"}' \
    > $DIR/tmp/_log3

    # Convert to CSV format (Easier to stick into sqlite3 db)
    # FIRST: single quotations for every column;
    # SECOND: commas between columns;
    # THIRD: brackets ( ) for each line and add comma at the end
    cat $DIR/tmp/_log3 | sed -r 's/[^ ]+/\x27&\x27/g' \
    | awk '{$1=$1}1' OFS="," | awk '{print "("$0"),"}' > $DIR/tmp/_log4


    #Removes the last comma from the last row of the file
    #Replace underscore (_) with a space (for names)
    logData=$( cat $DIR/tmp/_log4 )
    echo ${logData::-1} | sed 's/_/ /g' > $DIR/log

else
    echo "No files in /tmp because there were no connections: \
    i.e. the log file was not created."
fi
