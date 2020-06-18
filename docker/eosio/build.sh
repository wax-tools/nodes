#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################

# SOURCE - This can be one of the following:
#   DEB - Absolute path to a deb file, e.g. file:///tmp/eosio-1.0.deb
#   URL - Pass a full URL https://yoururl.com/eosio-1.0.deb
#   Git Repo - Pass the name of a Github repo that has releases with debs

EOSIO_VERSION="${1:-latest}"
EOSIO_SOURCE="${2:-EOSIO/eos}"
IMAGE_NAME="${3:-eosio}"
DOCKER_ARGS="${4}"
DOCKER_BUILD_ARGS="${5}"

function display_help() {
    
    echo
    [ ! -z "$@" ] && { echo "$@"; echo; }
    
    echo "Usage:"
    echo "        build.sh version source image-name docker-args docker-build-args"
    echo
    echo "version - The version of EOSIO to install. This is used to tag the image."
    echo "source - Can be a URL (http://t.io/my.deb), a filename (file://my.deb) or a Github Repo e.g. (eosio/eos)"
    echo "image-name - The desired name for the image"
    echo "docker-args - Args to pass to Docker"
    echo "docker-build-args - Args to pass to the build subcommand of Docker"
    echo
    exit
}

[ "$VERSION" = "--help" ] && display_help

docker $DOCKER_ARGS build $DOCKER_BUILD_ARGS \
--network=host \
--build-arg eosio_version=$EOSIO_VERSION \
--build-arg eosio_source=$EOSIO_SOURCE \
--tag=eosdublin/$IMAGE_NAME:$EOSIO_VERSION .
