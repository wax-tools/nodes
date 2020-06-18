#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
CLEOS=${1}
SIGNING_KEY=${2}
PRODUCER_NAME=${3:-eosdublinwow}
URL=${4:-"https://www.eosdublin.com"}
LOCATION=${5:-372}

$CLEOS system regproducer $PRODUCER_NAME $SIGNING_KEY $URL $LOCATION -p $PRODUCER_NAME@active
