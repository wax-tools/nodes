#!/bin/bash
CONTAINER_FILTER=${1:-name=testnet|production}
CONTAINER_EXCLUDE=${2:-cerberus\|watchdog}

CONTAINER_NAMES=$(docker ps --filter "$CONTAINER_FILTER" --format '{{.Names}}' | grep -v "$CONTAINER_EXCLUDE")

for CONTAINER_NAME in $CONTAINER_NAMES;
do
    # Get the PID of the container
    CONTAINER_PID=$(docker inspect $CONTAINER_NAME --format "{{.State.Pid}}")

    # Get the processor affinity for this PID
    AFFINITY=$(taskset -cp $CONTAINER_PID)

    # Write out to screen
    echo "$CONTAINER_NAME -> $AFFINITY"
done