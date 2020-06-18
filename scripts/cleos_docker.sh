function execute_docker() {
    target_container="$1"
    command="$2"
    docker exec -t $target_container /bin/bash -c "$command" 2>&1
}

function execute_cleos_command() {
    context="$1"
    command="$2"

    docker_result=$(execute_docker $WALLET_CONTAINER "$CLEOS $command")
    docker_result_code=$?

    process_result "$docker_result_code" "$docker_result" "$context"
}

function unlock_wallet() {
    execute_cleos_command "unlocking wallet" "wallet unlock --name $WALLET_NAME --password $WALLET_PASSWORD" 
}

