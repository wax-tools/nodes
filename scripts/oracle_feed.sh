# Get price data from source
# curl https://api.coinlore.net/api/coin/markets/?id=32238
CHAIN=${1:-wax}
PRODUCER_NAME=${2:-eosdublinwow}
CLAIM_PERMISSION=${3:-$PRODUCER_NAME@oracle}
WALLET_PASSWORD=${4}
WALLET_CONTAINER=${5:-scheduler.eosio.keosd}
CLEOS=${6:-"cleos"}
WALLET_NAME=${7:-oracle}

PAIRS=("WAXPBTC" "WAXPUSD")
URL="https://api.hitbtc.com/api/2/public/ticker?symbols=$(join_by , "${PAIRS[@]}")"

# Include our logging helpers
source /usr/local/bin/eosdublin/logging.sh
source /usr/local/bin/eosdublin/docker_cleos.sh
_LOG_LEVEL=$_LOG_LEVEL_VERBOSE

function join_by { local IFS="$1"; shift; echo "$*"; }
function round { echo $(printf %.$2f $(echo "scale=$2;(((10^$2)*$1)+0.5)/(10^$2)" | bc)); }
function format {
    SCALE=0
    RESULT=0
    if [ "${1#*"BTC"}" != "$1" ]; then
        RESULT=$(echo "$2 * 100000000" | bc)
    elif [ "${1#*"USD"}" != "$1" ]; then
        RESULT=$(echo "$2 * 10000" | bc)
    fi
    echo $(round $RESULT 0)
}

DATA=$(curl --silent "$URL" --stderr /dev/null)
declare -a TRX

for PAIR in "${PAIRS[@]}"
do
    VALUE=$(echo "$DATA" | jq -r --arg PAIR "$PAIR" -e '[.[] | select(.symbol==$PAIR)][0].ask')
    [ ! -z "$VALUE" ] && TRX+=("{ \"value\": $(format $PAIR $VALUE), \"pair\": \"$(echo "$PAIR" | tr '[:upper:]' '[:lower:]')\" }")
done

TRX=$(join_by , "${TRX[@]}")

log_verbose "Pushing data => $TRX"

log_verbose "[$CHAIN] Unlocking wallet..."
unlock_wallet
log_verbose "[$CHAIN] Wallet unlocked."
execute_cleos_command "pushing price feed" "push action delphioracle write '{\"owner\":\"$BP_NAME\", \"quotes\": [$TRX]}' -p $CLAIM_PERMISSION"