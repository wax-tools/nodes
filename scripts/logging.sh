#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
_LOG_LEVEL_ERROR=0
_LOG_LEVEL_WARNING=1
_LOG_LEVEL_INFO=2
_LOG_LEVEL_VERBOSE=3
_LOG_LEVEL_DEBUG=4
_LOG_LEVEL=$_LOG_LEVEL_INFO

function writeout() {
    printf "%s%s%s\n" "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")]" "$1" "$2"
}

function writeerror() {
    # writeout "$1" "$2" >&2
    printf "%s%s%s\n" "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")]" "$1" "$2" >&2
}

function log_error() { 
	([ $_LOG_LEVEL -ge $_LOG_LEVEL_ERROR ] && writeerror "[E]" "$*" || :)
}

function log_warning() { 
    ([ $_LOG_LEVEL -ge $_LOG_LEVEL_WARNING ] && writeerror "[W]" "$*" || :)
}

function log_info() {
    ([ $_LOG_LEVEL -ge $_LOG_LEVEL_INFO ] && writeout "[I]" "$1" || :)
}

function log_verbose() { 
	([ $_LOG_LEVEL -ge $_LOG_LEVEL_VERBOSE ] && writeout "[V]" "$*" || :)
}

function log_debug() {
    ([ $_LOG_LEVEL -ge $_LOG_LEVEL_DEBUG ] && writeout "[D]" "$*" || :)
}