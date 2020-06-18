################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
FROM ubuntu:18.04

# Install required packages
RUN apt-get update && \
DEBIAN_FRONTEND=noninteractive apt-get -y install curl jq && \
rm -rf /var/lib/apt/lists/*

# Add watchdog script
WORKDIR /opt/watchdog
ADD ./lib/ /opt/watchdog/

ENTRYPOINT [ "/opt/watchdog/watchdog.sh" ]
CMD [ "$CHAIN", "$PRODUCERACCT", "$WALLET_PASSWORD", "$API_URL", "$ALERT_WEBHOOK" ]