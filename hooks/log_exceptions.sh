#!/usr/bin/env zsh
# Exception hook that simply logs timestamped exception messages to a .txt file.
PATH="/bin:/usr/bin:/opt/local/bin"
echo `date`: $2 >> $1
