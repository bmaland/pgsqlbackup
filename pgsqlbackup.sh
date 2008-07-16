#!/usr/bin/env zsh

# PostgreSQL backup script, by Chrononaut <bjorn.maeland@gmail.com>
# Keeping it simple for now

USER="bjorn"

# Root dir for backups - don't store other files here as they could get deleted by the script.
BACKUPDIR="/Users/bjorn/pgsql_backups"

# Directory to put the backup files
DIR=`date +%d-%m-%Y`

# Number of copies to keep
KEEP=14

# Which compressor to use (gzip/bzip2)
COMPRESSOR="bzip2"

# Since each element in this list is passed to an inverted grep, you can exclude
# multiple databases with a single matching word.
EXCLUDE="test development postgres template"

# Post hook, can be uncommented. Can be used send mails or copy the files offsite, etc.
#POSTBACKUP="zsh ~/rsync_pgsql_backups"

# -- End of config -- #

DATABASES=`psql -U $USER -l | grep "^ \w" |  awk -F '|' '{ printf("%s\n", $1) }' | sed 's/ //g'`

for ex in `echo $EXCLUDE`; do
  DATABASES=`echo $DATABASES | grep -v $ex`
done

if [ ! -d $BACKUPDIR]; then
  mkdir $BACKUPDIR
fi
cd $BACKUPDIR

if [ ! -d $DIR ]; then
  mkdir $DIR
fi
cd $DIR

for db in `echo $DATABASES`; do
  pg_dump -U $USER $db | $COMPRESSOR > $db.db.bz2
done

cd ..

# Cleanup old dirs
while [ `ls|wc -l` -gt $KEEP ]; do
  rm -rf `ls|head -1`
done

if [ "$POSTBACKUP" ]; then
  eval $POSTBACKUP
fi

