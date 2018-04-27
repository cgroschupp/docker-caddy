FROM golang:alpine3.7 as builder

ARG version="0.10.14"

RUN apk --no-cache add git

RUN go get -d github.com/mholt/caddy/caddy
RUN go get -d github.com/caddyserver/builds

RUN cd /go/src/github.com/mholt/caddy \
  && git checkout "v${version}"

RUN cd /go/src/github.com/mholt/caddy/caddy \
  && git checkout -f \
  && go run build.go

RUN ls -al /go/src/github.com/mholt/caddy/caddy/caddy

FROM alpine:3.7

LABEL caddy_version="0.10.14"

ADD Caddyfile /etc/
COPY --from=builder /go/src/github.com/mholt/caddy/caddy/caddy /usr/bin/caddy

RUN apk --no-cache add libcap \
 && setcap cap_net_bind_service=+ep /usr/bin/caddy \
 && adduser -D caddy

EXPOSE 80 443

USER caddy

ENTRYPOINT ["/usr/bin/caddy"]

CMD ["-quic", "--conf", "/etc/Caddyfile"]
