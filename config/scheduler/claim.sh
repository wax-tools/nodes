#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################

CHAIN=${1^^}
PRODUCER_NAME=${2:-eosdublinwow}
CLAIM_PERMISSION=${3:-$PRODUCER_NAME@active}
API_URI=${4:-"http://$CHAIN.eosdublin.io"}
WALLET_PASSWORD=${5}
WALLET_CONTAINER=${6:-scheduler.eosio.keosd}
CLEOS=${7:-"cleos"}
WALLET_NAME=${8:-claimrewards}

# Include our logging helpers
source /usr/local/bin/eosdublin/logging.sh
_LOG_LEVEL=$_LOG_LEVEL_VERBOSE

CLEOS="$CLEOS --wallet-url unix:///eosio-wallet/keosd.sock -u $API_URI"
STANDARD=":EOS:"

# Executes a command inside the given Docker container
function execute_docker() {
    target_container="$1"
    command="$2"
    docker exec -t $target_container /bin/bash -c "$command" 2>&1
}

function execute_cleos_command() {
    context="$1"
    command="$2"

    docker_result=$(execute_docker $WALLET_CONTAINER "$CLEOS $command")
    docker_result_code=$?

    process_result "$docker_result_code" "$docker_result" "$context"
}

function process_result {
    result_code="$1"
    result="$2"
    context="$3"

    log_debug "[$CHAIN][process_result] ($result_code) -> $result"

    # Return early if everything is ok
    [ $result_code -eq 0 ] && return

    result=$(echo "$result" | sed -e "s/\x1b\[.\{1,5\}m//g")
    
    # Sometimes we get an unhelpful trailing message...
    [[ "${result##*$'\n'}" =~ "pending console output:" ]] && result=$(echo "$result" | head -n -1)

    log_debug "[$CHAIN][process_result] Sanitized result -> $result"

    # After executing 'docker exec', we received a non-zero exit code. Determine the cause here.
    if [[ "$result" =~ "executed transaction:" ]]; then
        log_info "[$CHAIN] ${result%%$'\n'*}"
    elif [[ "$result" =~ "Error 3120007: Already unlocked" ]]; then
        # Error Details:
        # Wallet is already unlocked: $WALLET_NAME
        log_verbose "[$CHAIN] ${result##*$'\n'}"
        return
    elif [[ "$result" =~ "already claimed rewards within past day" ]]; then
        # Error 3050003: eosio_assert_message assertion failure
        # Error Details:
        # assertion failure with message: already claimed rewards within past day
        # pending console output:
        log_verbose "[$CHAIN] $PRODUCER_NAME has already claimed in the last 24 hours"
        return
    elif [[ "$result" =~ "Error 3120002: Nonexistent wallet" ]]; then
        # Are you sure you typed the wallet name correctly?
        # Error Details:
        # Unable to open file: <WALLET_FILE_PATH>
        log_error "[$CHAIN] Error $context. ${result##*$'\n'}"
    elif [[ "$result" =~ "Error 3120005: Invalid wallet password" ]]; then
        # Are you sure you are using the right password?
        # Error Details:
        # Invalid password for wallet: "<WALLET_FILE_PATH>"
        log_error "[$CHAIN] Error $context. ${result##*$'\n'}"
    elif [[ "$result" =~ "Error 3090004: Missing required authority" ]]; then
        # Ensure that you have the related authority inside your transaction!;
        # If you are currently using 'cleos push action' command, try to add the relevant authority using -p option.
        # Error Details:
        # missing authority of $PRODUCER_NAME
        # pending console output:
        log_error "[$CHAIN] Error $context. ${result##*$'\n'}"
    elif [[ "$result" =~ "Error 3010001: Invalid name" ]]; then
        # Name should be less than 13 characters and only contains the following symbol .12345abcdefghijklmnopqrstuvwxyz
        # Error Details:
        # Name not properly normalized <...> 
        log_error "[$CHAIN] Invlid account name. ${result##*$'\n'}"
    elif [[ "$result" =~ "Error 3200004: fail to resolve host" ]]; then
        # Error Details:
        # Error resolving "$API_URL" : Host not found (authoritative)
        log_error "[$CHAIN] ${result##*$'\n'}"
    elif [[ "$result" =~ "Error 3090003: Provided keys, permissions, and delays do not satisfy declared authorizations" ]]; then
        # Ensure that you have the related private keys inside your wallet and your wallet is unlocked.
        # Error Details:
        # transaction declares authority '{"actor":"","permission":""}', but does not have signatures for it.
        log_error "[$CHAIN] ${result##*$'\n'}"
    elif [[ "$result" =~ "Error 3120006: No available wallet" ]]; then
        # Ensure that you have created a wallet and have it open
        # Error Details:
        # You don't have any wallet!
        log_error "[$CHAIN] ${result##*$'\n'}"
    elif [[ "$result" =~ "Error: No such container" ]]; then
        log_error "[$CHAIN] Docker error. '${result##*$' '}'"
    else
        log_error "[$CHAIN] Unknown error $context. Error data: $result"
    fi

    exit $result_code
}

function unlock_wallet() {
    log_verbose "[$CHAIN] Unlocking wallet..."
    execute_cleos_command "unlocking wallet" "wallet unlock --name $WALLET_NAME --password $WALLET_PASSWORD" 
    log_verbose "[$CHAIN] Wallet unlocked."
}

function claim_default() {
    unlock_wallet
    log_verbose "[$CHAIN] Calling eosio.claimrewards..."
    execute_cleos_command "claiming rewards" "push action eosio claimrewards '{\"owner\":\"$PRODUCER_NAME\"}' -p $CLAIM_PERMISSION" 
    log_verbose "[$CHAIN] Done."
}

function claim_wax() {
    unlock_wallet
    execute_cleos_command "claiming rewards" "push action eosio claimgbmprod '{\"owner\":\"$PRODUCER_NAME\"}' -p $CLAIM_PERMISSION"
    execute_cleos_command "claiming rewards" "push action eosio claimgenesis '{\"claimer\":\"$PRODUCER_NAME\"}' -p $CLAIM_PERMISSION"
    execute_cleos_command "claiming rewards" "push action eosio claimgbmvote '{\"owner\":\"$PRODUCER_NAME\"}' -p $CLAIM_PERMISSION"
}

log_info "[$CHAIN] Claiming rewards for $PRODUCER_NAME against $API_URI"

if [ "$CHAIN" = "WAX" ]; then
    claim_wax
elif [ "$CHAIN" = "FIO" ]; then
    claim_fio
elif [[ "$STANDARD" =~ ":$CHAIN:" ]]; then
    claim_default
else
    process_result 1 "$3"
    log_error "[_ALL_] Unknown chain '$CHAIN'"
fi
