#/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
API_URL="https://wax.eosdublin.io"
SAFE_ARGS="$(printf "${1+ %q}" "$@")"

cleos --url $API_URL --wallet-url unix:///eosio-wallet/keosd.sock "$@"
