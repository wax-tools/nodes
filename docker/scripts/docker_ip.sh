#!/bin/bash
CONTAINER_NAME=$1
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CONTAINER_NAME"
