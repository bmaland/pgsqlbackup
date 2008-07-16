#!/usr/bin/env zsh

# PostgreSQL backup script, by Chrononaut <bjorn.maeland@gmail.com>
# Keeping it simple for now

if [ ! -f config ]; then
  echo "Copy config.sample to config and edit the settings, then run this script again."
  exit
fi
source config

DATABASES=`psql -U $USER -l | grep "^ \w" |  awk -F '|' '{ printf("%s\n", $1) }' | sed 's/ //g'`

for ex in `echo $EXCLUDE`; do
  DATABASES=`echo $DATABASES | grep -v $ex`
done

if [ ! -d $BACKUPDIR ]; then
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

if [ "$POSTHOOK" ]; then
  eval $POSTHOOK
fi

