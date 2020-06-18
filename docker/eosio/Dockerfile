################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
FROM ubuntu:18.04

# Install required packages
RUN apt-get update && \
DEBIAN_FRONTEND=noninteractive apt-get -y install openssl ca-certificates curl wget build-essential libicu60 libusb-1.0-0 libcurl3-gnutls jq && \
rm -rf /var/lib/apt/lists/*

COPY ./lib /tmp/eosio/

# Arguments that may be overridden by the user
ARG eosio_version=latest
ARG eosio_source=EOSIO/eos

RUN /tmp/eosio/install_eosio.sh $eosio_source $eosio_version && \
rm -rf /tmp/eosio && \
rm -rf /var/lib/apt/lists/*
