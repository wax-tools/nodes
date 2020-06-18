#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################

EOSIO_VERSION="${1:-latest}"
EOSIO_IMAGE="${2:-eosdublin/eosio}"
DOCKER_ARGS="$3"
DOCKER_BUILD_ARGS="$4"

docker $DOCKER_ARGS build $DOCKER_BUILD_ARGS \
--build-arg EOSIO_IMAGE="$EOSIO_IMAGE" \
--build-arg EOSIO_VERSION="$EOSIO_VERSION" \
--tag=$EOSIO_IMAGE.nodeos:$EOSIO_VERSION .
