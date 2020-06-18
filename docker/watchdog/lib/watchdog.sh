#! /bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
#/ Usage: watchdog.sh [options]
#/
#/     -h, --help               show help text
#/     --version                show version
#/     -c, --chain name         the name of the chain to monitor. E.g. telos, telos-testnet
#/     -a, --api url            an API for the chain. Ideally this is not connected to the producer being monitored
#/     -p, --producer name      the account name of the producer to monitor
#/     -s, --schedule-grace     the number of seconds to wait between checks if the producer is not in the active schedule
#/
#/ Parse TomDoc'd shell scripts and generate pretty documentation from it.
#
# Written by Sam Noble @ eosDublin <sam@eosdublin.com>
set -e
# test -n "$WATCHDOG_DEBUG" && set -x

WATCHDO_VERSION="0.1.0"
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Includes
source /usr/local/bin/eosdublin/logging.sh

# TODO - Auto include these from a notify folder. Have them register themselves in an array.
[ -f "$SCRIPT_PATH/slack.sh" ] && source "${SCRIPT_PATH}/slack.sh"
[ -f "$SCRIPT_PATH/telegram.sh" ] && source "${SCRIPT_PATH}/telegram.sh"
[ -f "$SCRIPT_PATH/pagertree.sh" ] && source "${SCRIPT_PATH}/pagertree.sh"

# while test "$#" -ne 0; do
#     case "$1" in
#     -h|--help)
#         grep '^#/' <"$0" | cut -c4-; exit 0 ;;
#     --version)
#         echo "watchdog.sh version $WATCHDOG_VERSION"; exit 0 ;
#     -a|--api)
#         API=generate_text; shift ;;
#     -m|--m|--ma|--mar|--mark|--markd|--markdo|--markdow|--markdown)
#         generate=generate_markdown; shift ;;
#     -a|--a|--ac|--acc|--acce|--acces|--access)
#         test "$#" -ge 2 || { echo >&2 "error: $1 requires an argument"; exit 1; }
#         access="$2"; shift 2 ;;
#     --)
#         shift; break ;;
#     -|[!-]*)
#         break ;;
#     -*)
#         echo >&2 "error: invalid option '$1'"; exit 1 ;;
#     esac
# done

CHAIN="${1}"
PRODUCERACCT="${2}"
PASS="${3}"
API="${4:-http://$CHAIN.eosdublin.io}" # Prefer HTTP over HTTPS for speed. Perhaps offer two endpoints, one for reading, one for writing
_LOG_LEVEL="${5:-${WATCHDOG_LOG_LEVEL:-$_LOG_LEVEL_VERBOSE}}"
MISSED_ROUNDS_THRESHOLD_WARNING=${6:-2}
MISSED_ROUNDS_THRESHOLD_ERROR=${7:-4}
GRACE=${8:-${WATCHDOG_GRACE:-120}} # If a single block hasn't been produced within 120 seconds, a round has been missed (or the count was reset)
SCHEDULE_GRACE=${9:-${WATCHDOG_SCHEDULE_GRACE:-252}} # The interval to wait between checks if the prouducer is not in the active schedule.
INTERVAL=${10:-${WATCHDOG_INTERVAL:-5}}

# The value of unpaid_blocks before a round
LAST_UNPAID_BLOCKS=-1
# Timestamp for the last produced block
LAST_BLOCK_PRODUCED=$(date -u +%s)
# Periodically updated with the head block number for reference
LAST_BLOCK_NUMBER_SEEN=0
# 1 if producing, otherwise 0. Tracks whether a BP has produced in a given period
IS_PRODUCING=0
# The number of blocks that were produced by the BP in the last round
BLOCKS_PRODUCED_LAST_ROUND=0
# The cumulative number of rounds that have been missed
MISSED_ROUNDS=0
# The number of missed rounds in the last block
MISSED_BLOCKS=0
# The consecutive number of rounds with missed blocks
CONSECUTIVE_INCOMPLETE_ROUNDS=0
# A cumulative count of consecutive rounds with missed blocks. E.g. if a BP misses 2 blocks for 5 rounds, this will be 10. 
CONSECUTIVE_MISSED_BLOCKS=0
# Used to determine if a BP was removed from the schedule
IS_ACTIVE_PRODUCER=0
# Tracks the number of API errors in order to raise an alert
API_ERRORS=0
# The number of blocks producer per round. This is 12 on most EOSIO chains.
EXPECTED_BLOCKS_PER_ROUND=12
# The number of seconds allowance for a head block of an API
API_HEAD_BLOCK_TOLERANCE_S=180
# Used to track the active producer
ACTIVE_PRODUCER=""

# TODO
#  - Configure the number of blocks that can be missed rather than time based
#       An escalation approach is required here.
#           1. Missed rounds 1,2 - Send alert
#           2. Missed rounds 4+ - Initiate phone call
#           3. Missed rounds 8+ - Unregister
# - When an API is unavailable, it reports the producer as being removed from the schedule. This should be reported as an error

# Edgecases
# Block producer is just voted in
#   It's possible that LAST_BLOCK_PRODUCED could be very old.


# ISSUES
# - Telos testnet resets unpaid blocks after a certain amount of time which cause false positives to occur
#       We need to understand when the unpaid_blocks is reset, either because of a claim or a bug.
#       Do a simple check that when UNPAID_BLOCKS < LAST_UNPAID_BLOCKS, ignore the check. It's not ideal as
#       missed blocks won't be detected, but we don't really know the numbers inbetween. E.g. unpaid_blocks = 100
#       On the next round, it's 4. It could be that it hit 108, then was reset, so the total number of blocks from the
#       last round is 12, but we only see 4. Alternatively, 
# - When a producer is brought in to the schedule, but isn't yet producing blocks, false missed rounds will occur
#       Why does this happen? Is system listproducers introducing producers that are pending?
#       It could be that the check happens early on in the round, so the BP appears, but it's not their time to produce
#           for a few rounds (I think it takes around 4 minutes for a new schedule to become active) so need to handle this

# Known Issues

# If a call to the API to get BP info fails, it can appear that the BP has been removed from the schedule.
# This happens if the API fails to respond, or the request doesn't complete.
#       Fix this by checking the response from curl. The --fail flag is one option, but doesn't let us know if the URL
#       is valid. 
#           - Failures due to an invalid URL need to be alerted on. DNS issues could cause failures here which are to be expected
#           - Failures due to network connectivity need to be logged. If there is no connectivity, it's most likely not possible to send alerts either.


function send_message {
    alert_telegram "$1"
    alert_slack "$1"
}

function health_check {

    if [ "$MISSED_ROUNDS" -gt "0" ]; then
        # Check how many rounds we've missed
        if [ "$MISSED_ROUNDS" -le "$MISSED_ROUNDS_THRESHOLD_WARNING" ]; then
            # This is the first or second missed round. Just send a message out
            send_message "⛔ $CHAIN: $PRODUCERACCT missed a round ($MISSED_ROUNDS)"
        elif [ "$MISSED_ROUNDS" -le "$MISSED_ROUNDS_THRESHOLD_ERROR" ]; then
            # We've missed 4 rounds in a row, escalate
            send_message "⛔ $CHAIN: $PRODUCERACCT missed a round ($MISSED_ROUNDS)"
        elif [ "$MISSED_ROUNDS" -gt "$MISSED_ROUNDS_THRESHOLD_ERROR" ]; then
            # Here, we should only unregister once.
            # Ultimately, we want to switch keys
            unregproducer
        fi
    fi

    # If rounds aren't an issue, are we missing blocks?
    if [ "$CONSECUTIVE_INCOMPLETE_ROUNDS" -gt "0" ]; then
        # We had an incomplete round
        send_message "⚠️ $CHAIN: $PRODUCERACCT missed $1 blocks ($CONSECUTIVE_MISSED_BLOCKS/$CONSECUTIVE_INCOMPLETE_ROUNDS ~#$LAST_BLOCK_NUMBER_SEEN)"
    fi
}

function unregproducer {
    log_error "[$CHAIN][$PRODUCERACCT] has missed $MISSED_ROUNDS rounds, unregistering"
    log_warning "[$CHAIN][$PRODUCERACCT] Unregistering"

    # cleos wallet unlock --password $PASS -n watchdog > /dev/null 2> /dev/null
    # cleos -u "$API" system unregprod "$PRODUCERACCT" -p "$PRODUCERACCT"@watchdog
    # cleos wallet lock -n watchdog > /dev/null 2> /dev/null
}

log_info "[$CHAIN][$PRODUCERACCT] Woof! Watchdog started. API: $API"

# Really, these checks are only important once a producer is meant to have produced.
# Look at the head block and determine the producer. Look at the schedule and find 
# PRODUCERACCT in the schedule. Sleep until after they should have produced, plus some buffer

while true;
do
    # Get the head info to figure out who is producing and how long we should wait until we want to check again
    # Check the current producer.
    # Is it us?
        # Sleep 6 seconds
    # Where are they in the schedule? Sleep until after we should be in schedule
    CHAIN_INFO=$(curl --sSL --stderr /dev/null "$API/v1/chain/get_info")
    if [ "$?" -ne "0" ] || [ -z "$CHAIN_INFO" ] || [ "${CHAIN_INFO#*server_version}" = "$CHAIN_INFO" ]; then
        log_error "[$CHAIN][$PRODUCERACCT] Error $? fetching chain info: $API/v1/chain/get_info"
        API_ERRORS=$((API_ERRORS+1))
        sleep 10
        continue
    fi

    log_debug "[$CHAIN] get_info -> $CHAIN_INFO"

    # Check to see if this API is up to date. It's ok to have something behind, but if it's hours behind
    # it's not so useful.
    HEAD_BLOCK_TIME=$(echo $CHAIN_INFO | jq -r '.head_block_time')

    if [ ! -z "$HEAD_BLOCK_TIME" ]; then
        MS=${HEAD_BLOCK_TIME: -3}
        HEAD_BLOCK_TIMESTAMP=$(echo $HEAD_BLOCK_TIME | sed 's/T/ /' | sed -E 's/(:[0-9]+)\.[0-9]+/\1/g' | date +%s -f -)
        NOW=$(date -u +"%s")
        AGE=$((NOW-HEAD_BLOCK_TIMESTAMP))
        if [ "$AGE" -gt "$API_HEAD_BLOCK_TOLERANCE_S" ]; then
            API_ERRORS=$((API_ERRORS+1))
            log_warning "[$CHAIN][$PRODUCERACCT] Head block is ${AGE}s behind ($API -> .head_block_time: $HEAD_BLOCK_TIME)"
        fi
    fi

    ACTIVE_PRODUCER=$(echo $CHAIN_INFO | jq -r '.head_block_producer')
    # If active_producer == produceracct, we need to wait 6 seconds so that we run after they have produced.
    # Run this check early as we already have the data and can avoid subsequent API calls if possible.
    if [ "$PRODUCERACCT" = "$ACTIVE_PRODUCER" ]; then
        log_verbose "[$CHAIN][$PRODUCERACCT] will stop producing in ~6s"
        sleep 6
    fi

    PRODUCER_SCHEDULE=$(curl --silent "$API/v1/chain/get_producer_schedule" --stderr /dev/null --data-binary '{"json":true}')
    if [ "$?" -ne "0" ] || [ -z "$PRODUCER_SCHEDULE" ] || [ "${PRODUCER_SCHEDULE#*version}" = "$PRODUCER_SCHEDULE" ]; then
        log_error "[$CHAIN][$PRODUCERACCT] Error $? fetching schedule info: $API/v1/chain/get_producer_schedule"
        API_ERRORS=$((API_ERRORS+1))
        sleep 10
        continue
    fi

    log_debug "[$CHAIN][$PRODUCERACCT] get_producer_schedule -> $PRODUCER_SCHEDULE"

    # Check that the producer is in the current schedule
    BP_SCHEDULE=$(echo $PRODUCER_SCHEDULE | jq --arg PRODUCERACCT "$PRODUCERACCT" -e '.active.producers[] | select(.producer_name==$PRODUCERACCT)')

    if [ -z "$BP_SCHEDULE" ]; then
        # If this happens after seeing the producer produce, it means they've unregistered or been kicked. 
        if [ "$IS_ACTIVE_PRODUCER" -eq "1" ]; then
            send_message "ℹ️ [$CHAIN][$PRODUCERACCT] has been removed from the schedule"
            log_warning "[$CHAIN][$PRODUCERACCT] has been removed from the schedule"
        else
            log_info "[$CHAIN][$PRODUCERACCT] is not in the active schedule. Sleeping for ${SCHEDULE_GRACE} seconds"
        fi

        IS_ACTIVE_PRODUCER=0
        sleep $SCHEDULE_GRACE
        continue
    fi

    # Get the producer list and try to retireve the unpaid blocks. If nothing is returned, the producer isn't registered and isn't in the top 21.
    # NOTE: A producer can exist in this list before they are rotated in by a new schedule. Need to check this and the schedule.
    BP_INFO=$(curl -sSL "$API/v1/chain/get_producers" --stderr /dev/null --data-binary '{"json":true,"limit":21}' | jq --arg PRODUCERACCT "$PRODUCERACCT" -e '.rows[] | select(.owner==$PRODUCERACCT)')

    # If we didn't get a value, the producer isn't registered
    if [ -z "$BP_INFO" ]; then
        # TODO - Why couldn't we get the info? Did they unregister even though they are in the schedule?
        log_warning "[$CHAIN][$PRODUCERACCT] Unable to retrieve producer info. Sleeping for ${SCHEDULE_GRACE} seconds"
        sleep ${SCHEDULE_GRACE}
        # Required for when a BP enters the schedule, but hasn't produced any blocks before the check runs
        LAST_BLOCK_PRODUCED=$(date +%s)
        continue
    fi

    PRODUCERS_IN_SCHEDULE=$(echo "$PRODUCER_SCHEDULE" | jq '.active.producers | length')
    SCHEDULE_DURATION=$((PRODUCERS_IN_SCHEDULE*EXPECTED_BLOCKS_PER_ROUND/2)) # Assuming 2 blocks per second
    OUR_POSITION=$(echo "$PRODUCER_SCHEDULE" | jq --arg PRODUCERACCT "$PRODUCERACCT" '.active.producers | map(.producer_name == $PRODUCERACCT) | index(true)')
    CURRENT_INDEX=$(echo "$PRODUCER_SCHEDULE" | jq --arg PRODUCERACCT "$ACTIVE_PRODUCER" '.active.producers | map(.producer_name == $PRODUCERACCT) | index(true)')

    ROUNDS_UNTIL_PRODUCTION=$((PRODUCERS_IN_SCHEDULE-CURRENT_INDEX+OUR_POSITION))
    [ "$ROUNDS_UNTIL_PRODUCTION" -gt "$PRODUCERS_IN_SCHEDULE" ] && ROUNDS_UNTIL_PRODUCTION=$((ROUNDS_UNTIL_PRODUCTION-21))
    PRODUCTION_STARTS_IN=$((ROUNDS_UNTIL_PRODUCTION*EXPECTED_BLOCKS_PER_ROUND/2))

    log_verbose "[$CHAIN][$PRODUCERACCT] will start production in ~${PRODUCTION_STARTS_IN}s Active producer: $ACTIVE_PRODUCER."

    if [ "$((PRODUCTION_STARTS_IN+6))" -lt "$SCHEDULE_DURATION" ]; then
        # log_verbose "[$CHAIN][$PRODUCERACCT] Sleeping for $(((ROUNDS_UNTIL_PRODUCTION*EXPECTED_BLOCKS_PER_ROUND)/2))s"
        # sleep $(((ROUNDS_UNTIL_PRODUCTION*EXPECTED_BLOCKS_PER_ROUND)/2))]
        :;
    fi

    UNPAID_BLOCKS=$(echo "$BP_INFO" | jq -r '.unpaid_blocks')

    if [ "$LAST_UNPAID_BLOCKS" -eq -1 ]; then
        
        log_verbose "[$CHAIN] Initialising script. $BP_INFO"

        LAST_UNPAID_BLOCKS=$UNPAID_BLOCKS
        LAST_BLOCK_PRODUCED=$(date +%s)

        # Wait until the producer has finished their round, otherwise we run the risk of
        # a false positive as we've started in the middle of the producer's round.
        if [ "$ACTIVE_PRODUCER" = "$PRODUCERACCT" ]; then
            log_verbose "[$CHAIN][$PRODUCERACCT] is active during initialisation, sleeping until they're done"
            # Sleep until the end of the round
            sleep 6
        else
            sleep 1
        fi
    elif [ "$UNPAID_BLOCKS" -lt "$LAST_UNPAID_BLOCKS" ]; then

        # Edge-cases: 
        #   - Blocks were discarded due to a fork. This can happen if the API being queried is the producer or a direct peer.
        #   - In theory, the differance should be less than or equal to the MISSED_BLOCKS
        # TODO
        #   - Look at the last_claim_time for the BP to see if they claimed since the last check.
        #     If not, then blocks were removed from count due to missed blocks not propagating through the network
        #     Adjust our numbers and go again to see if any blocks were actually missed.
        #   - How to handle Telos style issues whereby unpaid blocks regularly resets

        DIFF=$((LAST_UNPAID_BLOCKS-UNPAID_BLOCKS))

        # Missed blocks can be different to the 'diff' here. E.g. missed = 0 and diff = 1
        # If the account hasn't claimed, and the drop is less than 12 blocks, adjust and continue,
        # otherwise there's a bug on the chain like Telos Testnet where blocks are reset now and then.
        
        if [ "${DIFF}" -eq "${MISSED_BLOCKS}" ]; then
            log_info "[$CHAIN][$PRODUCERACCT] Adjusting unpaid blocks due to ${MISSED_BLOCKS} rejected blocks"
            # One or more blocks from the last round did not qualify, so decrease our count
            LAST_UNPAID_BLOCKS=$((LAST_UNPAID_BLOCKS-DIFF))
            BLOCKS_PRODUCED_LAST_ROUND=$((BLOCKS_PRODUCED_LAST_ROUND-DIFF))
        else
            log_debug "[$CHAIN][$PRODUCERACCT] Unpaid blocks dropped by ${DIFF} (prv: ${LAST_UNPAID_BLOCKS}, now: ${UNPAID_BLOCKS}, miss: ${MISSED_BLOCKS}, last: ${BLOCKS_PRODUCED_LAST_ROUND})"
            LAST_UNPAID_BLOCKS=$UNPAID_BLOCKS
            LAST_BLOCK_PRODUCED=$(date -u +%s)
        fi

    elif [ "$UNPAID_BLOCKS" -gt "$LAST_UNPAID_BLOCKS" ]; then

        IS_PRODUCING=1
        IS_ACTIVE_PRODUCER=1
        BLOCKS_PRODUCED_LAST_ROUND=$((BLOCKS_PRODUCED_LAST_ROUND + UNPAID_BLOCKS - LAST_UNPAID_BLOCKS))
        LAST_UNPAID_BLOCKS=$UNPAID_BLOCKS
        LAST_BLOCK_PRODUCED=$(date -u +%s)
        LAST_BLOCK_NUMBER_SEEN=$(echo $CHAIN_INFO | jq '.head_block_num')
        log_verbose "[$CHAIN][$PRODUCERACCT] $PRODUCERACCT has produced $BLOCKS_PRODUCED_LAST_ROUND blocks"

        if [ "$MISSED_ROUNDS" -gt "0" ]; then
            send_message "✅ $PRODUCERACCT is producing again after missing $MISSED_ROUNDS rounds."
            MISSED_ROUNDS=0
        fi

        sleep 1 # Wait until the end of the round

    elif [ "$UNPAID_BLOCKS" = "$LAST_UNPAID_BLOCKS" ]; then
        NOW=$(date +%s)
        DELTA=$((NOW-LAST_BLOCK_PRODUCED))

        # Have we have produced since the last check?
        if [ "$IS_PRODUCING" == "1" ]; then
            # Did we miss any blocks this round?
            if [ "$BLOCKS_PRODUCED_LAST_ROUND" -lt "$EXPECTED_BLOCKS_PER_ROUND" ]; then
            
                MISSED_BLOCKS=$((EXPECTED_BLOCKS_PER_ROUND-BLOCKS_PRODUCED_LAST_ROUND))
                CONSECUTIVE_INCOMPLETE_ROUNDS=$((CONSECUTIVE_INCOMPLETE_ROUNDS+1))
                CONSECUTIVE_MISSED_BLOCKS=$((CONSECUTIVE_MISSED_BLOCKS+MISSED_BLOCKS))

                # Get the head block for debugging
                log_warning "[$CHAIN][$PRODUCERACCT] missed $MISSED_BLOCKS block(s) (~#$LAST_BLOCK_NUMBER_SEEN)"
                health_check $MISSED_BLOCKS
            else
                log_info "[$CHAIN][$PRODUCERACCT] produced $EXPECTED_BLOCKS_PER_ROUND blocks in the last round."
                CONSECUTIVE_INCOMPLETE_ROUNDS=0
                CONSECUTIVE_MISSED_BLOCKS=0
            fi

            BLOCKS_PRODUCED_LAST_ROUND=0
            IS_PRODUCING=0
        
        elif [ "$DELTA" -gt "$GRACE" ]; then
            
            MISSED_ROUNDS=$((MISSED_ROUNDS+1))

            printf "[$CHAIN][$PRODUCERACCT] missed a round ($MISSED_ROUNDS total) \n \
                       \tNo blocks produced for ${DELTA}s. Unpaid = $UNPAID_BLOCKS, \n \
                       \tLast Unpaid = $LAST_UNPAID_BLOCKS, Timestamp = ${NOW}, \n \
                       \tLastCheck = ${LAST_BLOCK_PRODUCED} \n \
                       \t$BP_INFO"

            health_check
            
        else
            log_debug "[$CHAIN][$PRODUCERACCT] has not produced on $CHAIN in the last $DELTA seconds."
        fi

        sleep $INTERVAL
    else
        log_warning "[$CHAIN][$PRODUCERACCT] Unknown state"
        printf "[D][$CHAIN][$PRODUCERACCT] Missed rounds: $MISSED_ROUNDS\n \
                       \tCMB:$CONSECUTIVE_MISSED_BLOCKS/CIR:$CONSECUTIVE_INCOMPLETE_ROUNDS ~#$LAST_BLOCK_NUMBER_SEEN\n \
                       \tUnpaid = $UNPAID_BLOCKS, Missed rounds = $MISSED_ROUNDS\n \
                       \tLast Unpaid = $LAST_UNPAID_BLOCKS, Timestamp = ${NOW}, \n \
                       \tLastBlockProduced = ${LAST_BLOCK_PRODUCED} \n \
                       \t$BP_INFO"
    fi
done

