#!/usr/bin/env zsh
# Post backup hook - Send your backups offsite with rsync.
# First argument:  local path
# Second argument: remote path
PATH="/bin:/usr/bin:/opt/local/bin"
rsync -rzC --delete ${1}* $2
