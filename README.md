# iptv-strmmaker
Downloads an m3u file from a http location and creates strm files from the tv series and movie entries in dedicated "STRM Movie" and "STRM TV" folders. strm files for movies are created in a folder named after each movie and episodes for TV series' are saved in numbered season folders in a parent folder named after the show. The script will also compare files that exist and ones recently processed in order to purge strl files for entries that no longer exist.

Tested on ubuntu and a QNAP NAS server.

# Usage
iptv-strmmaker.sh [m3u url] [output folder]

where:
* "m3u url" is the http location of an m3u file that contains vod files with one of the following extensions
  * avi
  * mp4
  * m4v
  * mkv
* "output folder" is a valid local folder where the strm files will be written

The following files should be edited and saved without the ".sample" extensions to customise the m3u entries to match (the script will not work without one of each file - without ".sample" extension):
* vodselection-tv
  * regex formatting can be used in the file
  * this matches to the group-title entry in the m3u file (usually named after the tv series)
    * UPDATE: a compare is also checked against tvg-name as some playlists do not use the group-title to categorise TV series. When this is required, ".*" will always be needed as the TV series name is almost always followed by a series and episode reference
  * entries in the m3u file must contain "season" and "episode" references like "S01 E02" or "S01E02" (with or without a space)
  * the url entries in the m3u file for tv series related entries must have "/series/" in the url
* vodselection-movies
  * regex formatting can be used in the file
  * this matches to the tvg-name (usually named after the movie)
  * If movie names have the year of release at the end, entering ".*" at the end of the entry will act as a wildcard lookup (lookup how to use regex)
  * the url entries in the m3u file for movie related entries must have "/movie/" or "/movies/" in the url

# Notes
A log file is created - check the output for details of errors and processing activity.
The m3u playlist can have live tv channels - these will be ignored as long as the urls do not have "/series/", "/movie/" or "/movies/" in them.
