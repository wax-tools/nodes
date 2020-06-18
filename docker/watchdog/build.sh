#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

VERSION=${1:-$(cat $SCRIPT_PATH/version.txt)}
DOCKER_BUILD_ARGS="$2"
DOCKER_ARGS="$3"

docker $DOCKER_ARGS build $DOCKER_BUILD_ARGS --tag=eosdublin/watchdog:"$VERSION" "$SCRIPT_PATH"
