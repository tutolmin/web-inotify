#!/bin/bash
#
# This simple script daemonizes inotify which waits for a moved_to event
# in the PGNs directory. The files can be either uploaded by a web user
# or compiled by the :Line merge function for game analysis
# Runs a sftp script in background to copy all the files to cache server

. /home/chesscheat/.cc_profile

# MOVED_TO lines-6-mo2120tutolmin-5e387070f1a9a.txt /home/chchcom/symfony/public/uploads/PGNs
# CLOSE_WRITE:CLOSE games-6-mo2120tutolmin-5e387070f1a9a.txt /home/chchcom/symfony/public/uploads/PGNs

# Blocking approach. We do NOT want to handle other files while current file is being copied
while inotifywait -qq -e moved_to -e close_write $UPLOADDIR
do
  # Log the event into system log
  logger -t sftp_uploads "Event in $UPLOADDIR"

  # Fire an sftp uploader script
  $APPDIR/sftp.sh
done &
