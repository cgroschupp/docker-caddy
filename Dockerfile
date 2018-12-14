FROM golang:alpine3.7 as builder

ARG version="0.11.1"

RUN apk --no-cache add git

RUN go get -d github.com/mholt/caddy/caddy
RUN go get -d github.com/caddyserver/builds

RUN go get -d github.com/freman/caddy-reauth

RUN cd /go/src/github.com/mholt/caddy \
  && git checkout "v${version}"

# Include plugins
RUN printf "package caddyhttp\nimport _ \"github.com/freman/caddy-reauth\"" > /go/src/github.com/mholt/caddy/caddyhttp/reauth.go

RUN cd /go/src/github.com/mholt/caddy/caddy \
  && git checkout -f \
  && go run build.go

FROM alpine:3.7

ENV CADDYPATH /etc/caddy/ssl
LABEL caddy_version="0.11.0"

ADD Caddyfile /etc/
COPY --from=builder /go/src/github.com/mholt/caddy/caddy/caddy /usr/bin/caddy

RUN apk --no-cache add libcap ca-certificates \
 && setcap cap_net_bind_service=+ep /usr/bin/caddy \
 && adduser -D -H caddy \
 && mkdir -p /etc/caddy/ssl \
 && chown caddy /etc/caddy/ssl

EXPOSE 80 443

USER caddy
VOLUME /etc/caddy/ssl

ENTRYPOINT ["/usr/bin/caddy"]

CMD ["-quic", "--conf", "/etc/Caddyfile"]
