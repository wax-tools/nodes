#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
EOSIO_VERSION=${1:-v2.0.4}
EOSIO_IMAGE=${2:-eosdublin/eosio}
CONTAINER_NAME=${3:-keosd}
ENV_FILE=${4:-"../../.env"}

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$SCRIPT_PATH/$ENV_FILE"

docker run -d --rm -i \
--name $CONTAINER_NAME \
--volume ~/:/root:ro \
--volume $KEOSD_WALLET_ROOT/default:/eosio-wallet \
--volume $SCRIPT_PATH/eosio:/scripts:ro \
$EOSIO_IMAGE:$EOSIO_VERSION \
/bin/bash -c "keosd --data-dir /eosio-wallet --config-dir /eosio-wallet"
