#!/usr/bin/env zsh

# PostgreSQL backup script, by Bjørn Arild Mæland <bjorn.maeland at gmail.com>
# WWW: http://github.com/Chrononaut/pgsqlbackup/tree/master

PATH="/bin:/usr/bin:/usr/local/bin:/opt/local/bin"

# Load config
if [[ ! -f "`dirname $0`/config" ]]; then
  echo "Copy config.sample to config and edit the settings, then run this script again."
  exit
fi
source "`dirname $0`/config"

# Cd's into a given dir - creates if it doesn't already exist.
# Throws an exception if the directory is illegal.
cd_or_create_and_cd() {
  if [ ! -d $1 ]; then mkdir -p $1 || exception "Could not create directory: $1"; fi
  cd $1 || exception "Could not cd to directory: $1"
}

# Echoes out an exception message, triggers the exception hooks and
# then exits the script with an error code.
exception() {
  echo $1
  if [ $EXCEPTIONHOOKS ]; then
    for hook in $EXCEPTIONHOOKS; do eval $hook \"$1\"; done
  fi
  exit 1
}

# Builds the connection string
pg_args=""
if [ $PGUSER ]; then pg_args+="-U $PGUSER"; fi
if [ $PGHOST ]; then pg_args+="-h $PGHOST"; fi

# Tests the given connection information to the database:
# We check if the database list is null - if so we throw an exception.
DBS=`psql ${=pg_args} -l` || exception "Could not connect to PostgreSQL database!"

if (( ! ${#DATABASES} )); then
  DATABASES=`echo $DBS|grep "^ \w"|awk -F '|' '{printf("%s\n", $1)}'|sed 's/ //g'`

  if (( ${#EXCLUDE} )); then
    for ex in $EXCLUDE; do
      DATABASES=`echo $DATABASES | grep -v $ex`
    done
  fi
fi

DATABASES=(${=DATABASES}) # Make an array of the databaselist
if (( ! ${#DATABASES} )); then exception "No suitable databases listed!"; fi

cd_or_create_and_cd $BASEDIR
if [[ -d $BACKUPDIR ]]; then rm -rf $BACKUPDIR; fi
cd_or_create_and_cd $BACKUPDIR

pg_args+=" -F t"

for db in $DATABASES; do
  eval "pg_dump $pg_args $db > $db.tar"
  $COMPRESSOR $db.tar
done

cd ..

# Cleanup old dirs
while [ `ls|wc -l` -gt $KEEP ]; do rm -rf `ls -tr|head -1`; done

if [ $POSTHOOKS ]; then
  for hook in $POSTHOOKS; do eval $hook; done
fi

echo "Backup completed successfully"
