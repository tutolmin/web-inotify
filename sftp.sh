#!/bin/bash
#
# This script is called whenever a file is moved into uploads directory
# It parses the file with pgn-extract to keep valid games only
# Then it compresses the resulting file and copies it to a remote cache/db server
# Then checks if there was another file moved into the queue directory
#
# Possible file names
# games-6-mo2120tutolmin-5e387070f1a9a.txt
# lines-6-5e387070f1a9a.txt
# evals-c80da44ba2e3fcea8205c639f75b3e775b76da3c016fa9c23e1f20bdc2c8cd63.json
#
# games & evals should go to cache server
# games & lines to DB server

. /home/chesscheat/.cc_profile

LOCKFILE="$SLOCK"

# Create lockfile if not exist
if [[ ! -e $LOCKFILE ]]; then
#  logger -t inotify "Creating $LOCKFILE < $$"
  logger -t inotify "Creating $LOCKFILE"
  echo $$ > $LOCKFILE
else
  logger -t inotify "$LOCKFILE present!"
  exit
fi

# Find the first file in PGN upload dir
FILE=`find $UPLOADDIR -type f -print0 -quit`

while [[ -f $FILE ]]; do

  filename=$(basename -- "$FILE")
  filetype=$(echo $filename | cut -f 1 -d'-')

  # DO NOT parse json & lines files
  if [[ "$filetype" == "games" ]]; then

    logger -t inotify "Parsing the $FILE with pgn-extract"

    # Parse the file with pgn-extract
    $BINDIR/pgn-extract -A $APPDIR/args $FILE -l "$ERRDIR/$filename.err" -o "$OUTDIR/$filename.out"

    logger -t inotify "Compressing the $OUTDIR/${filename}.out to save bandwidth"

    # GZipping the file before transmission
    gzip -c "$OUTDIR/${filename}.out" > "$UPLOADDIR/${filename}.gz"
 
    # Delete original file
    unlink "${FILE}"

  else

    logger -t inotify "Compressing the ${FILE} to save bandwidth"

    # GZipping the file before transmission
    gzip ${FILE}

  fi

  if [[ "$filetype" == "games" || "$filetype" == "lines" ]]; then

    logger -t inotify "Copying the ${FILE}.gz remotely to $DBSRV"

    scp -q "${FILE}.gz" "$DBSRV:$DBREMOTEDIR"

  fi

  if [[ "$filetype" == "games" || "$filetype" == "evals" ]]; then

    logger -t inotify "Copying the ${FILE}.gz remotely to $CACHESRV"

    # Copy the file remotely
    scp -q "${FILE}.gz" "$CACHESRV:$CACHEREMOTEDIR"

  fi

  #
  # What to do if file transfer did not complete successfully?
  #

  # Delete gzipped file
  unlink "${FILE}.gz"

  # Find the first file in PGN upload dir
  FILE=`find $UPLOADDIR -type f -print0 -quit`

done

logger -t inotify "Deleting $LOCKFILE"

# remove lock file
unlink $LOCKFILE

