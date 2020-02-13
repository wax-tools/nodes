#!/bin/bash
CONTAINER_NAME=$1

ABSOLUTE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$ABSOLUTE_PATH/nodeos_request.sh" "$CONTAINER_NAME" producer/pause POST

echo ""
