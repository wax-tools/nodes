#!/bin/bash
VERSION=${1:-$(cat version.txt)}

if [ -f "$VERSION.tar.gz" ]; then
  echo "A file named $VERSION.tar.gz already exists."
  exit
fi

if [ -d ./src ]; then
  echo "A directory named 'src' already exists."
  exit
fi

mkdir src
curl -L --silent "https://github.com/EOSIO/patroneos/archive/$VERSION.tar.gz" | tar -zxvf - -C ./src --strip-components=1
# wget -qO- "https://github.com/EOSIO/patroneos/archive/$VERSION.tar.gz" | tar -zxvf - -C ./src --strip-components=1

docker build --no-cache --tag=waxtools/patroneos:"$VERSION" .
rm -rf ./src/
