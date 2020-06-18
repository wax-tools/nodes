#!/bin/bash
################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################

EOSIO_SOURCE="$1"
EOSIO_VERSION="$2"

DEB_FILENAME=""
DEB_URL=""

if [[ "$EOSIO_SOURCE" =~ ^file://* ]]; then

    DEB_FILENAME="/tmp/eosio/${EOSIO_SOURCE#"file://"}"

elif [[ "$EOSIO_SOURCE" =~ ^http.* ]]; then

    # We have a DEB URL to download. The filename is the end of the URL
    DEB_URL=$EOSIO_SOURCE
    DEB_FILENAME="/tmp/${EOSIO_SOURCE##*/}"

else
    if [ -z "$EOSIO_VERSION" ]; then
	    echo "[E] In order to continue, you must specify either 'latest' or the release version, e.g. v2.0.5."
	    exit 1
    fi

    EOSIO_SOURCE="https://api.github.com/repos/$EOSIO_SOURCE/releases"

    if [ "$EOSIO_VERSION" = "latest" ]; then
        EOSIO_SOURCE="$EOSIO_SOURCE/latest"
    else
        EOSIO_SOURCE="$EOSIO_SOURCE/tags/$EOSIO_VERSION"
    fi

    DEB_URL=$(/usr/bin/curl -sSL $EOSIO_SOURCE | grep "browser_download_url.*ubuntu-18.04_amd64\.deb" | cut -d '"' -f 4)
	DEB_FILENAME=/tmp/$(/usr/bin/curl -sSL $EOSIO_SOURCE | grep "name.*ubuntu-18.04_amd64\.deb" | cut -d '"' -f 4)
fi

if [ ! -z "$DEB_URL" ]; then
    echo "[I] Downloading .deb to '$DEB_FILENAME' from '$DEB_URL'"
	/usr/bin/curl -SL "$DEB_URL" --output "$DEB_FILENAME" 
fi

if [ ! -f "$DEB_FILENAME" ]; then
    echo "[E] Could not find deb to install: $DEB_FILENAME"
    exit 1
fi

echo "[V] /usr/bin/dpkg -i '$DEB_FILENAME' && rm -f '$DEB_FILENAME'"
/usr/bin/dpkg -i "$DEB_FILENAME"
# It might prove useful to keep the deb around. If we find it's too fattening, yeet!
# rm -f "$DEB_FILENAME"
