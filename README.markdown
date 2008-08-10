# pgsqlbackup

There are probably many other backup scripts for Postgres, but I
wanted something that

  * supported hooks,
  * had configuration in a separate file,
  * was less complex/ugly than the other stuff I found out there.

So, this is my attempt. It's still in a very early stage but suitable
for simple use cases. Usage is simple, just look at config.sample.
The script is developed/tested only with zsh, and no attempt is made at keeping
bash compability.

You'll probably want to run this from crontab:

    crontab -e

    01 00 * * * /home/USER/pgsqlbackup/pgsqlbackup.sh

This example runs the script daily at midnight.

Contributions are very welcome.
