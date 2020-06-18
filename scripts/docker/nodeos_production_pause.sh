#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
CONTAINER_NAME=$1

ABSOLUTE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$ABSOLUTE_PATH/nodeos_request.sh" "$CONTAINER_NAME" producer/pause POST

echo .
