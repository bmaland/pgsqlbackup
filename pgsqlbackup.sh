#!/usr/bin/env zsh

# PostgreSQL backup script, by Bjørn Arild Mæland <bjorn.maeland at gmail.com>
# WWW: http://github.com/Chrononaut/pgsqlbackup/tree/master

PATH="/bin:/usr/bin:/opt/local/bin"

# Load config
if [ ! -f config ]; then
  echo "Copy config.sample to config and edit the settings, then run this script again."
  exit
fi
source config

# Functions
create_and_cd() {
  if [ ! -d $1 ]; then mkdir -p $1; fi
  cd $1
}

exception() {
  echo $1
  if [ $EXCEPTIONHOOKS ]; then
    for hook in $EXCEPTIONHOOKS; do eval $hook \"$1\"; done
  fi
  exit
}

# Check for connectivity
pg_args="-U $PGUSER"
if [ $PGHOST ]; then pg_args="$pg_args -h $PGHOST"; fi

if [ -z `eval "psql $pg_args -l 2>/dev/null"` ]; then
  exception "Could not connect to PostgreSQL database!"
fi

# The rest
if [ $EXCLUDE ]; then
  DATABASES=`psql -U $USER -l | grep "^ \w" |  awk -F '|' '{ printf("%s\n", $1) }' | sed 's/ //g'`

  for ex in `echo $EXCLUDE`; do
    DATABASES=`echo $DATABASES | grep -v $ex`
  done
fi

create_and_cd $BACKUPDIR
if [ -d $DIR ]; then rm -rf $DIR; fi
create_and_cd $DIR

pg_args="$pg_args -F t"

# TODO check for errors
for db in `echo $DATABASES`; do
  eval "pg_dump $pg_args $db > $db.tar"
  $COMPRESSOR $db.tar
done

cd ..

# Cleanup old dirs
while [ `ls|wc -l` -gt $KEEP ]; do rm -rf `ls|head -1`; done

if [ $POSTHOOKS ]; then
  for hook in $POSTHOOKS; do eval $hook; done
fi

echo "Backup completed successfully"
