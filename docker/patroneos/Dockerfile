################################################################################
#
# Created by Sam Noble for eosdublinwow https://eosdublin.com
# Visit https://github.com/wax-tools for details.
#
#################################################################################
FROM golang:stretch as builder

ARG VERSION=v2.0.0

RUN mkdir -p /usr/src/patroneos && \ 
    curl -sSL "https://github.com/EOSIO/patroneos/archive/$VERSION.tar.gz" | tar -zxvf - -C /usr/src/patroneos --strip-components=1 && \
    cd /usr/src/patroneos && \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -ldflags '-w -extldflags "-static"' -o patroneosd *.go

FROM alpine

COPY --from=builder /usr/src/patroneos/patroneosd /usr/local/bin/patroneosd
COPY lib/docker-entrypoint.sh /usr/local/bin/
COPY lib/config.template.json /etc/patroneos/

WORKDIR /usr/local/bin

ENTRYPOINT ["docker-entrypoint.sh"]
