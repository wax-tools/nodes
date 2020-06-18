#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
DOMAINS="$1"
DRY_RUN=${2:-1}
ADMIN_EMAIL=${3:-"admin@eosdublin.com"}
CERTBOT_LISTEN_PORT=${4:-53211}
LE_BASE=${5:-"/eosio/config/certbot/certs"}
HAPROXY_CONTAINER_NAME=${6:-api-gateway}
HAPROXY_NETWORK_NAME=${7:-api-gateway}

if [ "$DOMAINS" == "" ]; then
    echo ">>> No domains specified. Multiple domains can be specified, delimited by a semi-colon (;)"
    exit 1
fi

DOMAIN="${DOMAINS%%;*}"
CERTBOT_PARAMS=$([ "$DRY_RUN" -eq 1 ] && echo "--dry-run" || echo "--force-renewal")
CERTBOT_DOMAIN_STRINGS=""
DOMAIN_CERT_FILE="$LE_BASE/live/$DOMAIN/privkey.pem"
CERT_LAST_UPDATED=0
CERT_UPDATED=0

echo ">>> DOMAIN: $DOMAIN"
echo ">>> Checking if $DOMAIN_CERT_FILE exists..."

if [ -f $DOMAIN_CERT_FILE ]; then
    echo ">>> Certificate exists, checking last update time"
    CERT_LAST_UPDATED=$(date +%s -r $DOMAIN_CERT_FILE)
fi

IFS=';' read -ra LIST <<<"$DOMAINS"
for i in "${LIST[@]}"; do
    CERTBOT_DOMAIN_STRINGS="$CERTBOT_DOMAIN_STRINGS -d $i"
done

echo ">>> Running certbot with: certonly --keep-until-expiring --agree-tos -m $ADMIN_EMAIL --preferred-challenges=http --standalone --http-01-port $CERTBOT_LISTEN_PORT $CERTBOT_DOMAIN_STRINGS $CERTBOT_PARAMS"

docker run -it --rm --name certbot \
-v "$LE_BASE/:/etc/letsencrypt" \
-v "$LE_BASE/:/var/lib/letsencrypt" \
--network=$HAPROXY_NETWORK_NAME \
certbot/certbot certonly --non-interactive --keep-until-expiring --agree-tos -m $ADMIN_EMAIL --preferred-challenges=http --standalone --http-01-port $CERTBOT_LISTEN_PORT $CERTBOT_DOMAIN_STRINGS $CERTBOT_PARAMS

if [ -f $DOMAIN_CERT_FILE ]; then
    echo ">>> Certificate exists. Checking if it was updated/created"
    CERT_UPDATED=$(date +%s -r $DOMAIN_CERT_FILE)
fi

echo "CERT_UPDATED: $CERT_UPDATED, CERT_LAST_UPDATED: $CERT_LAST_UPDATED"

if [ "$CERT_UPDATED" -ne "$CERT_LAST_UPDATED" ]; then
    echo ">>> Certificate updated. Updating HAProxy"
    # Update the certificate
    cat $LE_BASE/live/$DOMAIN/fullchain.pem $LE_BASE/live/$DOMAIN/privkey.pem > /etc/ssl/private/$DOMAIN.pem
    # Notify HAProxy to reload its config
    docker kill -s HUP $HAPROXY_CONTAINER_NAME
fi

echo "Done"
