################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################

ARG EOSIO_IMAGE=eosdublin/eosio
ARG EOSIO_VERSION=latest

FROM $EOSIO_IMAGE:$EOSIO_VERSION

# No user is defined here. It is expected that the container be run with an appropriate user

COPY lib/docker-entrypoint.sh /usr/local/bin/
COPY lib/logging.template.*.json /etc/nodeos/

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
