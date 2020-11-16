#!/bin/bash
SCRIPTNAME="$(basename $0)"
SCRIPTDIR="$(cd $(dirname $0) && pwd)"
vLOG="$SCRIPTDIR/${SCRIPTNAME%.*}.log"
vFILEPROCESSEDLOG="$SCRIPTDIR/${SCRIPTNAME%.*}-FILESPROCESSED.log"
vFILEEXISTINGLOG="$SCRIPTDIR/${SCRIPTNAME%.*}-FILESEXISTING.log"
vFILESTODELETE="$SCRIPTDIR/${SCRIPTNAME%.*}-FILESTODELETE.log"
vNewTV="$SCRIPTDIR/${SCRIPTNAME%.*}-NewTV.log"
vNewMOVIES="$SCRIPTDIR/${SCRIPTNAME%.*}-NewMOVIES.log"
vFILESTODELETE="$SCRIPTDIR/${SCRIPTNAME%.*}-FILESTODELETE.log"
LOCKFILE="$SCRIPTDIR/${SCRIPTNAME%.*}.lock"

#source "$SCRIPTDIR/vodselection-tv"
#source "$SCRIPTDIR/vodselection-movies"

# Log function
PrintLog(){
 echo "[`date`] - ${*}" >> "${vLOG}" 
}

# counter function

AddCounter()(
 TEMPFILE=$1.tmp
 COUNTER=$[$(cat $TEMPFILE) + 1]
 echo $COUNTER > $TEMPFILE
)

# Set variables using parameters - m3u url first then output location for strm file folders
if [ -n "$1" ]; then
 vURL="$1"
 if [ -n "$2" ]; then
  OUTPUTDIR="$2"
  OUTPUTDIR=${OUTPUTDIR%/}
  if [ ! -d "$OUTPUTDIR" ]; then
   PrintLog "ERROR: output path $OUTPUTDIR does not exist"
   exit 1
  fi
 else
  echo
  PrintLog "ERROR: need an output path - nothing defined"
  exit 1
 fi
else
 echo
 PrintLog "ERROR: need a url to an m3u as input - nothing defined"
 exit 1
fi

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

ScanEntries_TV() {
 while read -r catLine; do
## DO NOT ECHO ENTRIES IN THIS FUNCTION ##
#  PrintLog "catLine is $catLine (output line)"

# set newLine as default
  newLine="$catLine"
# parse url
  vMediaUrl=http${newLine##*,http}
# parse existing channel name - from the end of the line before the url
  vChannelName="${newLine%%,http*}"
  vChannelName="${vChannelName##*,}"
  vChannelName="$(echo $vChannelName)" # remove extra spaces?
# parse season and episode
  vSeasonAndEpisode="${vChannelName:(-7)}"
# parse season
  vSeason="${vSeasonAndEpisode% *}"
  vSeason="${vSeason#*S}"
  vSeason="$(expr $vSeason + 0)"
  printf -v vSeason "%02d" $vSeason
# parse episode
  vEpisode="${vSeasonAndEpisode#* }"
  vEpisode="${vEpisode#*E}"
  vEpisode="$(expr $vEpisode + 0)"
  printf -v vEpisode "%02d" $vEpisode
# parse tv series
  vSeries="${vChannelName% $vSeasonAndEpisode}"
#  vSeries=$(echo $vSeries | sed -e 's/[^A-Za-z0-9._- ]//g')
# write output
#  PrintLog "FOUND - $vSeries from season $vSeason and episode $vEpisode. URL $vMediaUrl"
  WriteSTRMFile_TV
 done
}

WriteSTRMFile_TV(){
 #
 mkdir -p "$OUTPUTDIR/STRM TV/$vSeries/Season $vSeason"
 vSTRMFile="$OUTPUTDIR/STRM TV/"
 vSTRMFile+="$vSeries/Season $vSeason/$vSeries "
 vSTRMFile+="S${vSeason}"
 vSTRMFile+="E${vEpisode}"
 vTVEpisode="${vSTRMFile##*/}"
 vSTRMFile+=".strm"
# check if file contents are different - only write if different
 if [ -f "$vSTRMFile" ]; then
  content=$(cat "$vSTRMFile")
  if [ "$vMediaUrl" != "$content" ];then
   echo "$vMediaUrl" > "$vSTRMFile"
   AddCounter countTVCurrent
   PrintLog "WROTE UPDATED LINK - $vSTRMFile"
   echo "$vSTRMFile" >> "${vFILEPROCESSEDLOG}"
  else
   AddCounter countTVCurrent
   PrintLog "ALREADY EXISTS - $vSTRMFile"
   echo "$vSTRMFile" >> "${vFILEPROCESSEDLOG}"
  fi
 else 
  echo "$vMediaUrl" > "$vSTRMFile"
  AddCounter countTVNew
  PrintLog "WROTE NEW - $vSTRMFile"
  echo "> $vTVEpisode" >> "${vNewTV}"
  echo "$vSTRMFile" >> "${vFILEPROCESSEDLOG}"
 fi
}

ScanEntries_Movies() {
 while read -r catLine; do
## DO NOT ECHO ENTRIES IN THIS FUNCTION ##
#  PrintLog "catLine is $catLine (output line)"

# set newLine as default
  newLine="$catLine"
# parse url
  vMediaUrl=http${newLine##*,http}
# parse existing channel name - from the end of the line before the url
  vMovieName="${newLine%%,http*}"
  vMovieName="${vMovieName##*,}"
  vMovieName="$(echo $vMovieName)" # remove extra spaces?
#  vMovieName=$(echo $vMovieName | sed -e 's/[^A-Za-z0-9._- ]//g')
# write output
#  PrintLog "FOUND - $vMovieName. URL $vMediaUrl"
  WriteSTRMFile_Movies
 done
}

WriteSTRMFile_Movies(){
 #
 mkdir -p "$OUTPUTDIR/STRM Movies/$vMovieName"
 vSTRMFile="$OUTPUTDIR/"
 vSTRMFile+="STRM Movies/$vMovieName/"
 vSTRMFile+="$vMovieName.strm"
# check if file contents are different - only write if different
 if [ -f "$vSTRMFile" ]; then

  content=$(cat "$vSTRMFile")
  if [ "$vMediaUrl" != "$content" ];then
   echo "$vMediaUrl" > "$vSTRMFile"
   AddCounter countMovieCurrent
   PrintLog "WROTE UPDATED LINK - $vSTRMFile"
   echo "$vSTRMFile" >> "${vFILEPROCESSEDLOG}"
  else
   AddCounter countMovieCurrent
   PrintLog "ALREADY EXISTS - $vSTRMFile"
   echo "$vSTRMFile" >> "${vFILEPROCESSEDLOG}"
  fi
 else 
  echo "$vMediaUrl" > "$vSTRMFile"
  AddCounter countMovieNew
  PrintLog "WROTE NEW - $vSTRMFile"
  echo "> $vMovieName" >> "${vNewMOVIES}"
  echo "$vSTRMFile" >> "${vFILEPROCESSEDLOG}"
 fi
}

# VARIABLES
vTEMPFILE=temp.m3u

# PROCESSING

cd $SCRIPTDIR
[ -f "${vLOG}" ] && rm "${vLOG}"
[ -f "${vFILEPROCESSEDLOG}" ] && rm "${vFILEPROCESSEDLOG}"
[ -f "${vFILEEXISTINGLOG}" ] && rm "${vFILEEXISTINGLOG}"
[ -f "${vFILESTODELETE}" ] && rm "${vFILESTODELETE}"
[ -f "*.m3u" ] && rm "*.m3u"
[ -f "*.tmp" ] && rm "*.tmp"

echo 0 > countMovieCurrent.tmp
echo 0 > countMovieNew.tmp
echo 0 > countTVCurrent.tmp
echo 0 > countTVNew.tmp
echo 0 > countDeleted.tmp

if [ ! -f vodselection-tv ]; then
 PrintLog "vodselection-tv file does not exist. Choose TV series to be included by updating the sample file."
 exit 1
fi

if [ ! -f vodselection-movies ]; then
 PrintLog "vodselection-movies file does not exist. Choose Movies to be included by updating the sample file."
 exit 1
fi

wget --quiet -O "$vTEMPFILE" "$vURL" -nv -T 10 -t 1
if [ $? -ne 0 ]; then
 PrintLog "wget reported an error"
 rm "$vTEMPFILE"
 exit 1
else
 FILESIZE=$(stat -c%s "$vTEMPFILE")
 PrintLog "wget completed... $vTEMPFILE downloaded ($FILESIZE)"
fi

# fix line feeds
sed -i 's/^M$//' "$vTEMPFILE"
sed -i 's/\r$//' "$vTEMPFILE"

# remove blank lines
PrintLog "Removing blank lines from $vTEMPFILE"
cat "$vTEMPFILE" | sed '/^$/d' > 1_remblank.tmp
if [ $? -ne 0 ]; then
  echo "ERROR REPORTED"
  exit 1
fi

# remove commas from between quotes - it breaks splitting to one line and rebuilding back together at the end
PrintLog "Removing commas from between quotes in file"
cat 1_remblank.tmp | awk -F'"' -v OFS='"' '{for(i=2;i<NF;i+=2) gsub(",", "", $i)}1' > 2_quotefix.tmp
if [ $? -ne 0 ]; then
  echo "ERROR REPORTED"
  exit 1
fi

# one line per record
PrintLog "Rebuilding M3U file as single lined entries"
cat 2_quotefix.tmp | to_one_line_per_record > 3_1line.tmp
if [ $? -ne 0 ]; then
  echo "ERROR REPORTED"
  exit 1
fi

# sort records based on channel name
PrintLog "Sorting entries based on channel name"
cat 3_1line.tmp | sort -t, -k2,2 > 4_1linesorted.tmp
if [ $? -ne 0 ]; then
  echo "ERROR REPORTED"
  exit 1
fi

# extract only entries that end with mkv/mp4
PrintLog "Extracting VOD entries based on file extension"
cat 4_1linesorted.tmp | grep -E "\.avi$|\.mp4$|\.m4v$|\.mkv$" > 5_vodentries.tmp
if [ $? -ne 0 ]; then
  echo "ERROR REPORTED"
  exit 1
fi

# extract tv series vod entries 
PrintLog "Extracting VOD TV series entries"
cat 5_vodentries.tmp | grep -iE "^.*/series/.*$" > 6_vodentries_tv.tmp
if [ $? -ne 0 ]; then
  echo "ERROR REPORTED"
  exit 1
fi

# extract movies vod entries 
PrintLog "Extracting VOD movie entries"
cat 5_vodentries.tmp | grep -iE "^.*/(movie|movies)/.*$" > 6_vodentries_movies.tmp
if [ $? -ne 0 ]; then
  echo "ERROR REPORTED"
  exit 1
fi

# write strm files for tv series vod entries - with "S## E##" entry
input=vodselection-tv
cat "$input" | while read -r line
 do
#  PrintLog "Processing $line from $input"
  cat 6_vodentries_tv.tmp | grep -E '^.*S[[:digit:]]{2}[[:space:]]*E[[:digit:]]{2}.*$' | grep -iE "group-title=\"$line\"" | ScanEntries_TV
done 

# write strm files for movies vod entries
input=vodselection-movies
cat "$input" | while read -r line
 do
#  PrintLog "Processing $line from $input"
  cat 6_vodentries_movies.tmp | grep -iE "tvg-name=\"$line\"" | ScanEntries_Movies
done 

# purging strm files not processed during this script run 
#find "$OUTPUTDIR/STRM"* -name "*.strm" -mmin +60 -exec rm "{}" \;
find "$OUTPUTDIR/STRM"* -name "*.strm" -exec echo "{}" >> "${vFILEEXISTINGLOG}" \;
grep -Fxv -f "${vFILEPROCESSEDLOG}" "${vFILEEXISTINGLOG}" > "${vFILESTODELETE}"
# if there are files to delete - remove them
if [ -f "${vFILESTODELETE}" ]; then
 while read -r filename; do
  rm "$filename"
  PrintLog "DELETED $filename"
  AddCounter countDeleted
 done <${vFILESTODELETE}
fi

# remove empty directories
find "$OUTPUTDIR/STRM"* -type d -exec rmdir "{}" + 2>/dev/null

echo $(cat countMovieCurrent.tmp) current movies
echo $(cat countMovieNew.tmp) new movies
[ -f "${vNewMOVIES}" ] && cat "${vNewMOVIES}"
echo $(cat countTVCurrent.tmp) current tv episodes
echo $(cat countTVNew.tmp) new tv episodes
[ -f "${vNewTV}" ] && cat "${vNewTV}"
echo $(cat countDeleted.tmp) files purged after removal from the playlist

echo $(cat countMovieCurrent.tmp) current movies >> "${vLOG}"
echo $(cat countMovieNew.tmp) new movies >> "${vLOG}"
[ -f "${vNewMOVIES}" ] && cat "${vNewMOVIES}" >> "${vLOG}"
echo $(cat countTVCurrent.tmp) current tv episodes >> "${vLOG}"
echo $(cat countTVNew.tmp) new tv episodes >> "${vLOG}"
[ -f "${vNewTV}" ] && cat "${vNewTV}" >> "${vLOG}"
echo $(cat countDeleted.tmp) files purged after removal from the playlist >> "${vLOG}"

[ -f "${vFILEPROCESSEDLOG}" ] && rm "${vFILEPROCESSEDLOG}"
[ -f "${vFILEEXISTINGLOG}" ] && rm "${vFILEEXISTINGLOG}"
[ -f "${vFILESTODELETE}" ] && rm "${vFILESTODELETE}"
[ -f "${vNewTV}" ] && rm "${vNewTV}"
[ -f "${vNewMOVIES}" ] && rm "${vNewMOVIES}"
rm *.m3u
rm *.tmp
