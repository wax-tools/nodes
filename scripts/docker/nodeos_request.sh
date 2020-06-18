#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
CONTAINER_NAME=$1
URL=$2
METHOD=${3:-GET}

# Get the container IP address.
# NOTE: If the container is connected to more than one network, this will fail.
IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CONTAINER_NAME")

if [[ "$IP" == "" ]]; then
    echo "Container $CONTAINER_NAME not found."
    exit 1
fi

echo "Executing: $METHOD http://$IP:8888/v1/$URL"

curl --request "$METHOD" \
  --url http://$IP:8888/v1/$URL \
  --header 'content-type: application/x-www-form-urlencoded; charset=UTF-8'

echo ""