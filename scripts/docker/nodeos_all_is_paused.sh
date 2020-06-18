#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
CONTAINER_FILTER=${1:-name=producer}
CONTAINER_EXCLUDE=${2}

CONTAINER_NAMES=$(docker ps --filter "$CONTAINER_FILTER" --format '{{.Names}}') # | grep -v "$CONTAINER_EXCLUDE")

ABSOLUTE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

for CONTAINER_NAME in $CONTAINER_NAMES;
do
    printf "%-40s -> " "$CONTAINER_NAME"
    $ABSOLUTE_PATH/nodeos_is_paused.sh $CONTAINER_NAME
done