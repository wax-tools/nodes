#!/bin/bash
SLACK_WEBHOOK="YOUR_WEB_HOOK"

function alert_slack {
    log_debug "[$CHAIN][$PRODUCERACCT] Sending Slack notification..."
    RESPONSE=$(curl --silent -X POST -H 'Content-type: application/json' --data "{\"text\":\"$1\"}" "$SLACK_WEBHOOK")
    
    ([ "$RESPONSE" == "ok" ] && log_debug "[$CHAIN][$PRODUCERACCT] Slack notification sent") || log_error "[$CHAIN][$PRODUCERACCT] Error sending Slack message: $RESPONSE"
}
