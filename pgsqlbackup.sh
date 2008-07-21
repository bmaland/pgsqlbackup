#!/usr/bin/env zsh

# PostgreSQL backup script, by Bjørn Arild Mæland <bjorn.maeland at gmail.com>
# WWW: http://github.com/Chrononaut/pgsqlbackup/tree/master

PATH="/bin:/usr/bin:/opt/local/bin"

# Load config
if [ ! -f "`dirname $0`/config" ]; then
  echo "Copy config.sample to config and edit the settings, then run this script again."
  exit
fi
source "`dirname $0`/config"

# Functions

# Cd's into a given dir - creates if it doesn't already exist.
# Throws an exception if the directory is illegal.
create_and_cd() {
  if [ ! -d $1 ]; then mkdir -p $1; fi
  if [ -d $1 ]; then
    cd $1
  else
    exception "Illegal directory: $1"
  fi
}

# Echoes out an exception message, triggers the exception hooks and
# then exits the script to prevent further damage.
exception() {
  echo $1
  if [ $EXCEPTIONHOOKS ]; then
    for hook in $EXCEPTIONHOOKS; do eval $hook \"$1\"; done
  fi
  exit
}

# Somewhat of an assertion checker. Throws an exception if the given statement
# is false. This function is really fragile atm - it breaks if it receives "weird" data.
assert() {
  eval "if [ ! $1 ]; then exception \"$2\"; fi"
}

# Builds the connection string
pg_args="-U $PGUSER"
if [ $PGHOST ]; then pg_args="$pg_args -h $PGHOST"; fi

# Tests the given connection information to the database:
# We check if the database list is null - if so we throw an exception.
dbs=`eval "psql $pg_args -l 2>/dev/null|head -1"`
assert "! -z $dbs" "Could not connect to PostgreSQL database!"

# The rest
if [ $EXCLUDE ]; then
  DATABASES=`psql -U $USER -l | grep "^ \w" |  awk -F '|' '{ printf("%s\n", $1) }' | sed 's/ //g'`

  for ex in `echo $EXCLUDE`; do
    DATABASES=`echo $DATABASES | grep -v $ex`
  done
fi

create_and_cd $BACKUPDIR
assert "`pwd`/ = $BACKUPDIR" "Could not cd to backupdir: $BACKUPDIR"
if [ -d $DIR ]; then rm -rf $DIR; fi
create_and_cd $DIR

pg_args="$pg_args -F t"

# TODO check for errors
for db in `echo $DATABASES`; do
  eval "pg_dump $pg_args $db > $db.tar"
  $COMPRESSOR $db.tar
done

cd ..
assert "`pwd`/ = $BACKUPDIR" "Could not cd to backupdir: $BACKUPDIR"

# Cleanup old dirs
while [ `ls|wc -l` -gt $KEEP ]; do rm -rf `ls|head -1`; done

if [ $POSTHOOKS ]; then
  for hook in $POSTHOOKS; do eval $hook; done
fi

echo "Backup completed successfully"
