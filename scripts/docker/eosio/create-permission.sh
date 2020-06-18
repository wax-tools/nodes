#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
CLEOS=$1
ACCOUNT_NAME=$2
PERMISSION_NAME=$3
PUBLIC_KEY=$4
PARENT_AUTHORITY=${5:-active}
AUTHORITY=${6:-active}
CONTRACT=$7
ACTION=$8

$CLEOS set account permission $ACCOUNT_NAME $PERMISSION_NAME $PUBLIC_KEY $PARENT_AUTHORITY -p $ACCOUNT_NAME@$AUTHORITY
$CLEOS set action permission $ACCOUNT_NAME $CONTRACT $ACTION $PERMISSION_NAME