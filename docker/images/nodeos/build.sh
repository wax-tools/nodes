#!/bin/bash
WAX_VERSION=${1:-latest}
WAX_IMAGE=${2:-waxteam/production}
DOCKER_ARGS=$3
DOCKER_BUILD_ARGS=$4

ABSOLUTE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

docker $DOCKER_ARGS build $DOCKER_BUILD_ARGS --build-arg WAX_IMAGE=$WAX_IMAGE --build-arg WAX_IMAGE_VERSION=$WAX_VERSION --tag=waxtools/nodeos:$WAX_VERSION $ABSOLUTE_PATH
