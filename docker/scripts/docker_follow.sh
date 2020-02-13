#!/bin/bash
CONTAINER_NAME=$1
docker logs --follow --tail 10 "$CONTAINER_NAME"
