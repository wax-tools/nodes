#!/bin/bash

TELEGRAM_CHAT_ID="YOUR_CHAT_ID"
TELEGRAM_BOT_NAME="YOUR_BOT_NAME"
TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN"

TELEGRAM_WEBHOOK=${6:-"https://api.telegram.org/${TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${TELEGRAM_CHAT_ID}%40${TELEGRAM_BOT_NAME}"}

function alert_telegram {
    log_debug "[$CHAIN][$PRODUCERACCT] Sending Telegram notification..."
    RESPONSE=$(curl --silent --get "$TELEGRAM_WEBHOOK" --data-urlencode "text=$1")
    OK=$(echo "$RESPONSE" | jq -e '.ok')

    ([ "$OK" == "true" ] && log_debug "[$CHAIN][$PRODUCERACCT] Telegram notification sent") || log_error "[$CHAIN][$PRODUCERACCT] Error sending Telegram message: $RESPONSE"
}