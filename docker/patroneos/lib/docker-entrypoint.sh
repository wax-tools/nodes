#!/bin/sh
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################

# <UserParameters>
NODEOS_HOST="$1"
PATRONEOS_ARGS="$2"
NODEOS_PORT="$3"
CONFIG_DIR="${4:-/etc/patroneos}"
# </UserParameters>

# <Body>
function display_help() {
    
    echo
    [ ! -z "$@" ] && { echo "$@"; echo; }
    
    echo "Usage:"
    echo "        docker-entrypoint.sh nodeos-host patroneos-args nodeos-port config-dir"
    echo
    echo "nodeos-host - The address for the target nodeos host. Defaults to 0.0.0.0"
    echo "patroneos-args - Additional args to pass through to patroneos"
    echo "nodeos-port - The port for the target nodeos host"
    echo "config-dir - The path in the container to load config.json fro. Defaults to /etc/patroneos"
    echo
}

if [ "$1" = "--help" ]; then
	display_help
	exit 0
fi

[ -z "$NODEOS_HOST" ] && { display_help "Error: nodeos-host is required"; exit 1; }

# Make sure a custom configuration file isn't already in play
if [ "${PATRONEOS_ARGS#*--configFile}" = "$PATRONEOS_ARGS" ] \
   && [ ! -f "$CONFIG_DIR/config.json" ] \
   && [ -f "$CONFIG_DIR/config.template.json" ]; then
    echo "[I] Auto generating patroneos config."
   
    # NOTE: Calling `eval` is generally unsafe and should not be run when the input cannot be trusted.
    # Given that we're running this in a container with all sides controlled by the runner, there is no risk
    eval "cat <<EOF
$(cat "$CONFIG_DIR/config.template.json")
EOF
" > $CONFIG_DIR/config.generated.json 2> /dev/null

    PATRONEOS_ARGS="-configFile /etc/patroneos/config.generated.json $PATRONEOS_ARGS"
fi

echo "[I] Starting patroneos. Args: $PATRONEOS_ARGS"
exec "/usr/local/bin/patroneosd" $PATRONEOS_ARGS
# </Body>