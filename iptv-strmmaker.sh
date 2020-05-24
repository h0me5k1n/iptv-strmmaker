#!/bin/bash
SCRIPTNAME="$(basename $0)"
SCRIPTDIR="$(cd $(dirname $0) && pwd)"
vLOG="$SCRIPTDIR/${SCRIPTNAME%.*}.log"
LOCKFILE="$SCRIPTDIR/${SCRIPTNAME%.*}.lock"

source "$SCRIPTPATH/vodselection-tv"
source "$SCRIPTPATH/vodselection-movies"

# Log function
PrintLog(){
 echo "[`date`] - ${*}" >> ${vLOG} 
 sed -i -e :a -e '$q;N;500,$D;ba' ${vLOG}
}

# This changes each playlist entry to appear on a single line instead of 2 lines
to_one_line_per_record() {
  local inf_line= line=
  while read -r line; do
    if [[ $line = "#"* ]]; then
      inf_line=$line
    elif [[ $line = "" ]]; then
      echo blank line
    else
      printf '%s\n' "${inf_line},$line"
    fi
  done
}

# This changes each line in a "single lined" list of m3u entries back to 2 lines 
# doesn't work for vod!! too many commas
from_one_line_per_record() {
  local inf_f1 inf_f2 url
  while IFS=, read -r inf_f1 inf_f2 url; do
    printf '%s,%s\n%s\n' "$inf_f1" "$inf_f2" "$url"
  done
}

vURL=
vTEMPFILE=
OUTPUTDIR=
vFILE=

wget --quiet -O "$vTEMPFILE" "$vURL" -nv -T 10 -t 1
if [ $? -ne 0 ]; then
 PrintLog "$vFILE wget reported an error..."
 ERRORCHECK=1
 rm "$vTEMPFILE"
else
 mv "$vTEMPFILE" "$OUTPUTDIR/$vFILE"
 FILESIZE=$(stat -c%s "$OUTPUTDIR/$vFILE")
fi



