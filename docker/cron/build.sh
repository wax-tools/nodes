#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################

CONTAINER_NAME=${1:-cron}
DOCKER_ARGS="$2"
DOCKER_BUILD_ARGS="$3"

docker $DOCKER_ARGS build $DOCKER_BUILD_ARGS \
--network=host \
--tag=eosdublin/$CONTAINER_NAME:latest .
