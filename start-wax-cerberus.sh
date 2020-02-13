#!/bin/bash
[[ -f .env ]] && source .env

# This file is used to start a container running nodeos for the given chain, environment and role
# It is expected that the node have a valid blocks.log and state in place, otherwise the node will fail to boot.
# Any nodeos arguments passed in here will be forwarded directly to nodeos
ENVRIONMENT=$1
NODEOS_ARGS=$2
INIT_DATA=$3
INIT_MODE=$4
EOSIO_VERSION=${5:-latest}
EOSIO_IMAGE=${6:-$NODEOS_DOCKER_IMAGE} # Default value imported from .env
NODEOS_DATA_ROOT=${7:-$NODEOS_DATA_ROOT} # Default value imported from .env
NODEOS_CONFIG_ROOT=${8:-$NODEOS_CONFIG_ROOT} # Default value imported from .env

NODEOS_USERNAME=wax${ENVRIONMENT}
NODEOS_USERID=$(id -u "$NODEOS_USERNAME")
NODEOS_GROUPID=$(getent group $OS_GROUP_EOSIO | cut -d: -f3)

make up-$ENVRIONMENT-cerberus \
EOSIO_VERSION=$EOSIO_VERSION \
NODEOS_USER="$NODEOS_USERID" \
NODEOS_GROUP="$NODEOS_GROUPID" \
NODEOS_ARGS="$NODEOS_ARGS" \
INIT_MODE="$INIT_MODE" \
INIT_DATA="$INIT_DATA" \
EOSIO_IMAGE="$EOSIO_IMAGE" \
CONFIG_ROOT_PATH="$NODEOS_CONFIG_ROOT" \
DATA_ROOT_PATH="$NODEOS_DATA_ROOT" 
