#!/usr/bin/env bash
# this script reads a logfile from simplecd and convert it, so it can be accessed via a html page
# 1. creates a html page
# 2. converts logfile to html (just puts <br /> after every line; will be extended soon)
# 3. uses ajax via javascript to get the converted html-logfile

if [[ ! -w /var/www/simplecd ]] ; then echo "Directory /var/www/simplecd does not exist, aborting." && exit 1; fi

NOW=$(date '+%d.%m.%Y_%H:%M:%S')

#Input variables
LOGFILE=$1
REPO=$(echo $2 | cut -d '/' -f 2 | cut -d '.' -f 1)

# check if input variables are not null
if [[ $LOGFILE == "" ]]
then
    echo "No Logfile handed over. Aborting..."
    exit 1
fi

OUTPUT_DIRECTORY_NAME="${REPO}_${NOW}"
OUTPUT_DIRECTORY_PATH=/var/www/simplecd/"${OUTPUT_DIRECTORY_NAME}"
LOG_EXISTS=false
PAGE_TITLE="Build $REPO on $(date '+%d.%m.%Y %H:%M:%S')"
CURDIR=$(dirname "$0")
KNOWN_ANSI_CODES=("[31m" "[32m" ";32m" "[0m" ";31m" "[1m" "[0m") # for better text readibility - extendable

echo $PAGE_TITLE

# wait until Logfile exists
# abort if it's not available after one minute
let w=0
until $LOG_EXISTS || [[ $w -gt 11 ]]
do
    [[ -f $LOGFILE ]] && LOG_EXISTS=true || sleep 5
    let w=$w+1
done

if [[ $w > 11 ]]
then
    echo "Logfile does not exist. Aborting..." > $LOGFILE
    exit 1
fi

# create subdirectory
[[ -d $OUTPUT_DIRECTORY_PATH ]] || mkdir -p $OUTPUT_DIRECTORY_PATH



# create html-file
cat > $OUTPUT_DIRECTORY_PATH/index.html \
<<- _EOF_
    <html>
    <head>
        <title>
          SimpleCD Monitor
         </title>
         <style>
             body {
                 font-family: monospace;
             }
         </style>
     </head>
     <body>
     <script>

     setInterval(function() {
        if ((window.innerHeight + window.scrollY) >= document.body.offsetHeight) {
            var xhttp = new XMLHttpRequest();
            xhttp.onreadystatechange = function() {
                if (this.readyState == 4 && this.status == 200) {
                    document.getElementById("text").innerHTML = xhttp.responseText;
                    if ((window.innerHeight + window.scrollY) >= document.body.offsetHeight) {
                        document.getElementById("bottom").scrollIntoView();

                    }
                }
            };
            xhttp.open("GET", "htmllog.log", true);
            xhttp.send();
        }

     }, 1000);
     </script>

     <div style="position:fixed; top:0; height: 50px;background-color:white;width:98%;padding-bottom:20px;">
        <h1>$PAGE_TITLE</h1>
     </div>
     <div id="text" style="z-index:-100;margin-top:100px;width:99%"></div>
     <div id="bottom"></div>
     </body>
     </html>
_EOF_

# If there is a script for notifying about the new rollout and its web output, trigger it.

[[ -e $CURDIR/notification.sh ]] && $CURDIR/notification.sh $REPO $OUTPUT_DIRECTORY_NAME

LASTLINE=null

# read Logfile line by line
# abort after one minute if no one's writing anymore
let i=0
let t=0
while [[ t -lt 60 ]]; do
    let i=$i+1
    FONTCOLOR=black
    CURRENTLINE=$(head -n $i $LOGFILE | tail -n 1)

      if [[ $LASTLINE != $CURRENTLINE ]]
      then
        LASTLINE=$CURRENTLINE
        let t=0
        for color in ${KNOWN_ANSI_CODES[*]}
        do
            if [[ $CURRENTLINE == *$color* ]]
            then
              # ansi code handling
              case $color in
                  \[31m)  FONTCOLOR=red
                          CURRENTLINE=$(echo $CURRENTLINE | sed -r 's/\[31m//g' );;
                  \[32m)  FONTCOLOR=green
                          CURRENTLINE=$(echo $CURRENTLINE | sed -r 's/\[32m//g' );;
                  \;32m)  FONTCOLOR=green
                          CURRENTLINE=$(echo $CURRENTLINE | sed -r 's/\;32m//g' );;
                  \;31m)  FONTCOLOR=red
                          CURRENTLINE=$(echo $CURRENTLINE | sed -r 's/\;31m//g' );;
                  \[1m)   CURRENTLINE=$(echo '<b>'$CURRENTLINE'</b>' | sed -r 's/\[1m//g' ) ;;
                  \[0m)   CURRENTLINE=$(echo $CURRENTLINE | sed -r 's/\[0m//g') ;;
                  default) FONTCOLOR=black
              esac
            fi
        done
        echo '<span style="color:'$FONTCOLOR'">'$CURRENTLINE'</span><br>' >> $OUTPUT_DIRECTORY_PATH/htmllog.log
        sleep 0.2
      else
        sleep 5
        let t=$t+1
      fi
done

rm -f $LOGFILE
