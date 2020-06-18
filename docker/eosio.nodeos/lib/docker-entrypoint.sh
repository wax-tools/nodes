#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################

# <UserParameters>
NODEOS_ARGS="$1"
INIT_MODE="$2" # ""|genesis|snapshot
INIT_DATA="$3"
LOGGING_LEVEL="$4"
LOGGING_GELF_ENDPOINT="$5"
LOGGING_GELF_HOST="$6" # (ip|domain):port
# </UserParameters>

# <Locals>
INIT_DATA_PATH="/eos-shared"
# </Locals>

# <Body>
function echoerror() { 
	cat <<< "[ERROR] $@" 1>&2; 
}

function display_help() {
    echo "Missing parameters. Usage:"
    echo "docker-entrypoint.sh init-mode init-data"
    echo
    echo "init-mode - The strategy to use when booting this node."
    echo "    genesis - Start the node from genesis. A genesis.json file must exist"
    echo "    snapshot - Start the node from a snapshot. An existing blocks log must exist otherwise nodeos will error"
    echo "    _blank_ - Start the node from an existing blocks.log and or state file"
    echo
    echo "init-data - Allows extra initialisation data to be provided."
    echo
    echo "    if init-mode = genesis"
    echo "        URL - A genesis file will be downloaded to $INIT_DATA_PATH/genesis.json"
    echo "        filename - The genesis file $INIT_DATA_PATH/filename will be used"
    echo "        _blank_ - The genesis file $INIT_DATA_PATH/genesis.json will be used"
    echo 
    echo "    if init-mode = snapshot"
    echo "        URL - The given snapshot will be downloaded and extracted to $INIT_DATA_PATH/snapshots/"
    echo "        filename - The snapshot file $INIT_DATA_PATH/snapshots/filename will be used"
    echo "        auto - The most recent snapshot found in $INIT_DATA_PATH/snapshots/ will be used"
    echo
}

if [ "$1" = "--help" ]; then
	display_help
	exit 0
fi

if [ "$INIT_MODE" = "genesis" ]; then

	GENESIS_FILE="$INIT_DATA_PATH/genesis.json"

	if [[ "$INIT_DATA" =~ ^http(s)?:// ]]; then

		# Check a genesis file doesn't exist already
		if [[ -f "$GENESIS_FILE" ]]; then
			echoerror "A genesis.json file already exists and would be overwritten."
			exit 2
		fi

		curl -qo $GENESIS_FILE $INIT_DATA 

	elif [ ! -z "$INIT_DATA" ]; then
		
		if [ ! -f "$INIT_DATA_PATH/$INIT_DATA" ]; then
			echoerror "Genesis file not found: $INIT_DATA_PATH/$INIT_DATA"
			exit 2
		fi
		
		# We've been given a file to use as the genesis.json, so use that
		GENESIS_FILE=$INIT_DATA_PATH/$INIT_DATA
	fi

	if [ ! -f "$GENESIS_FILE" ]; then
		echoerror "No genesis.json file found."
		exit 2
	fi

	NODEOS_ARGS="$NODEOS_ARGS --genesis-json $GENESIS_FILE"
	STARTING_WITH=" from genesis"

elif [ "$INIT_MODE" = "snapshot" ]; then

	if [ -z "$INIT_DATA" ]; then

		display_help
		exit 2
	
	elif [ "$INIT_DATA" = "auto" ]; then
		
		# Just take the latest snapshot from the shared-path
		SNAPSHOT="$(ls -t $INIT_DATA_PATH/snapshots/*.bin 2> /dev/null | head -n1)"
		
		if [[ ! -f $SNAPSHOT ]]; then
			echoerror "No snapshots found in $INIT_DATA_PATH/snapshots/"
			exit 2
		fi

	elif [[ "$INIT_DATA" =~ ^http(s)?:// ]]; then
		
		TEMP_DIR="$INIT_DATA_PATH/snapshots/$(mktemp -d -u snapshotXXXXXXXX)"
		mkdir -p $TEMP_DIR

		wget --output-document=- $INIT_DATA | tar xz -C $TEMP_DIR --transform='s/.*\///' --

		SNAPSHOT="$(ls -t $TEMP_DIR/*.bin 2> /dev/null | head -n1)"

		mv $SNAPSHOT $INIT_DATA_PATH/snapshots/
		rm -rf $TEMP_DIR
		
		# TODO - Improve error handling here
		if [[ "$?" -ne 0 ]]; then
			echoerror "Downloading and extracting tar failed: $INIT_DATA"
			exit 2
		fi

		SNAPSHOT=$INIT_DATA_PATH/snapshots/$(basename $SNAPSHOT)
	else
		# We've been given a specific file to use, so use that
		SNAPSHOT="$INIT_DATA_PATH/snapshots/$INIT_DATA"

		if [[ ! -f "$SNAPSHOT" ]]; then
			echoerror "Snapshot file not found: $SNAPSHOT"
			exit 2
		fi
	fi
	
	NODEOS_ARGS="$NODEOS_ARGS --snapshot $SNAPSHOT"
    STARTING_WITH=" with snapshot $SNAPSHOT"

elif [ ! -z "$INIT_MODE" ]; then

	echo "Unknown value for INIT_MODE: $INIT_MODE"
	exit 2

fi

CONFIG_DIR=$(echo $NODEOS_ARGS | sed 's/.*--config-dir \([^ ]*\).*/\1/')
echo ">>> CONFIG_DIR=$CONFIG_DIR, NODEOS_ARGS=$NODEOS_ARGS"
# Make sure a custom configuration file isn't already in play
if [[ ! "$NODEOS_ARGS" =~ "--logconf" ]] && [ ! -f "$CONFIG_DIR/logging.json"  ]; then
    # Check to see if need to invite GELF to the party
    echo ">>> We're looking to generate a logging configuration"
    [ -f "/etc/nodeos/logging.template.gelf.json" ] && echo ">>> logging.template.gelf.json exists!"
    if [ ! -z "$LOGGING_GELF_ENDPOINT" ] && [ ! -z "$LOGGING_GELF_HOST" ] && [ -f "/etc/nodeos/logging.template.gelf.json" ]; then
        echo ">>> Generating GELF log configuraition "
        LOGGING_TEMPLATE="/etc/nodeos/logging.template.gelf.json"
    elif [ ! -z "$LOGGING_LEVEL" ] && [ -f "/etc/nodeos/logging.template.basic.json" ]; then
        echo ">>> Generating basic log config"
        LOGGING_TEMPLATE="/etc/nodeos/logging.template.basic.json"
    fi

    if [ ! -z "$LOGGING_TEMPLATE" ]; then
        echo ">>> We have a tmeplate"
        # NOTE: Calling `eval` is generally unsafe and should not be run when the input cannot be trusted.
        # Given that we're running this in a container with all sides controlled by the runner, there is no risk
        eval "cat <<EOF
$(<$LOGGING_TEMPLATE)
EOF
" > /tmp/logging.generated.json 2> /dev/null
        NODEOS_ARGS="$NODEOS_ARGS --logconf /tmp/logging.generated.json"
    fi
fi

echo "Starting nodeos$STARTING_WITH."
echo "args: $NODEOS_ARGS"
echo

exec "nodeos" $NODEOS_ARGS
# </Body>