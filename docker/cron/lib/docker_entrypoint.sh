#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################

# Do we have any variables to load here? Ideally we'd use a config.json to handle our chains
printenv | sed 's/^\(.*\)\=\(.*\)$/export \1\="\2"/g' > /container.env

# Install our cron script
if [ ! -f "/usr/local/etc/cron.d/crontab.conf" ]; then
    echo "No crontab.conf found in /usr/local/etc/cron.d/"
    exit 2
fi

cp "/usr/local/etc/cron.d/crontab.conf" "/etc/cron.d/crontab.conf"
chmod 0644 /etc/cron.d/crontab.conf
crontab /etc/cron.d/crontab.conf
touch /var/log/cron.log

# Check to see if there is an init script available
if [ -f "/usr/local/bin/init.sh" ]; then
    source /usr/local/bin/init.sh
fi

# Run cron in the foreground
exec cron -f