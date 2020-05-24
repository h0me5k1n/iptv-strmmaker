# iptv-strmmaker
Download m3u file from iptv provider and create strm files from tv series and movie entries.

# Usage
iptv-strmmaker.sh [m3u url] [output folder]

where:
* "m3u url" is the http location of an m3u file that contains vod files with one of the following extensions
  * avi
  * mp4
  * m4v
  * mkv
* "output folder" is a valid local folder where the strm files will be written

The following files should be edited and saved without the ".sample" extensions to customise the m3u entries to match:
* vodselection-tv
  * regex formatting can be used in the file
  * this matches to the group-title entry in the m3u file (usually named after the tv series)
  * entries in the m3u file must contain "season" and "episode" references like "S01 E02" or "S01E02" (with or without a space)
* vodselection-movies
  * regex formatting can be used in the file
  * this matches to the tvg-name (usually named after the movie)
  * If movie names have the year of release at the end, entering ".*" at the end of the entry will act as a wildcard lookup (lookup how to use regex)

