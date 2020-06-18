#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
[[ -f "$SCRIPT_PATH/.env" ]] && source "$SCRIPT_PATH/.env"

# This file is used to start a container running nodeos for the given chain, environment and role
# It is expected that the node have a valid blocks.log and state in place, otherwise the node will fail to boot.
# Any nodeos arguments passed in here will be forwarded directly to nodeos
CHAIN="${1}"
ENVRIONMENT="${2}"
EOSIO_VERSION="${3}"
NODEOS_ARGS="${4}"
INIT_MODE="${5}"
INIT_DATA="${6}"
EOSIO_IMAGE="${7:-$NODEOS_DOCKER_IMAGE}" # Default value imported from .env
NODEOS_DATA_ROOT="${8:-$NODEOS_DATA_ROOT}" # Default value imported from .env
NODEOS_CONFIG_ROOT="${9:-$NODEOS_CONFIG_ROOT}" # Default value imported from .env
DOCKER_NETWORK_GATEWAY_NAME="${10:-$DOCKER_NETWORK_GATEWAY_NAME}" # Default value imported from .env
DOCKER_COMPOSE_ARGS="${11}"
NODEOS_LOGGING_LEVEL="${12:-$NODEOS_LOGGING_LEVEL}"
NODEOS_LOGGING_GELF_ENDPOINT="${13:-$NODEOS_GELF_ENDPOINT}"
NODEOS_LOGGING_GELF_HOST="${14:-"$CHAIN-$ENVIRONMENT-$ROLE-$(hostname)"}"

NODEOS_USERNAME="${CHAIN}${ENVRIONMENT}"
NODEOS_USERID=$(id -u "$NODEOS_USERNAME")
NODEOS_GROUPID=$(getent group $OS_GROUP_EOSIO | cut -d: -f3)

make up-$CHAIN-$ENVRIONMENT-cerberus \
EOSIO_VERSION="$EOSIO_VERSION" \
NODEOS_USER="$NODEOS_USERID" \
NODEOS_GROUP="$NODEOS_GROUPID" \
NODEOS_ARGS="$NODEOS_ARGS" \
INIT_DATA="$INIT_DATA" \
INIT_MODE="$INIT_MODE" \
EOSIO_IMAGE="$EOSIO_IMAGE" \
CONFIG_ROOT_PATH="$NODEOS_CONFIG_ROOT" \
DATA_ROOT_PATH="$NODEOS_DATA_ROOT" \
DOCKER_NETWORK_GATEWAY_NAME="$DOCKER_NETWORK_GATEWAY_NAME" \
DOCKER_COMPOSE_ARGS="$DOCKER_COMPOSE_ARGS"
LOGGING_LEVEL="$NODEOS_LOGGING_LEVEL" \
LOGGING_GELF_ENDPOINT="$NODEOS_LOGGING_GELF_ENDPOINT" \
LOGGING_GELF_HOST="$NODEOS_LOGGING_GELF_HOST"
