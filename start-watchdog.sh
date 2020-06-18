#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
API_URL=$1
EOSIO_ACCOUNT_NAME=$2
WATCHDOG_VERSION=${3:-$(cat docker/watchdog/version.txt)}

make watchdog \
API_URL="$API_URL" \
EOSIO_ACCOUNT_NAME="$EOSIO_ACCOUNT_NAME"
WATCHDOG_VERSION="$WATCHDOG_VERSION"
