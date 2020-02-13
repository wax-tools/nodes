FROM golang:stretch as builder

ADD ./src /src

RUN cd /src && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -ldflags '-w -extldflags "-static"' -o patroneosd *.go

FROM alpine

COPY --from=builder /src/patroneosd /usr/bin/patroneosd

WORKDIR /etc/patroneos

ENTRYPOINT ["/usr/bin/patroneosd"]
