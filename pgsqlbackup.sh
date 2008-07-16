#!/usr/bin/env zsh

# PostgreSQL backup script, by Bjørn Arild Mæland <bjorn.maeland at gmail.com>
# WWW: http://github.com/Chrononaut/pgsqlbackup/tree/master

# Load config
if [ ! -f config ]; then
  echo "Copy config.sample to config and edit the settings, then run this script again."
  exit
fi
source config

# Functions
create_and_cd() {
  if [ ! -d $1 ]; then
    mkdir -p $1
  fi
  cd $1
}

# The rest
if [ "$EXCLUDE" ]; then
  DATABASES=`psql -U $USER -l | grep "^ \w" |  awk -F '|' '{ printf("%s\n", $1) }' | sed 's/ //g'`

  for ex in `echo $EXCLUDE`; do
    DATABASES=`echo $DATABASES | grep -v $ex`
  done
fi

create_and_cd $BACKUPDIR
create_and_cd $DIR

for db in `echo $DATABASES`; do
  pg_dump -U $PGUSER -h $PGHOST -F t $db > $db.tar
  $COMPRESSOR $db.tar
done

cd ..

# Cleanup old dirs
while [ `ls|wc -l` -gt $KEEP ]; do
  rm -rf `ls|head -1`
done

if [ "$POSTHOOK" ]; then
  eval $POSTHOOK
fi

