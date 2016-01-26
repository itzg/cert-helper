FROM alpine:3.3

MAINTAINER itzg

RUN apk update && \
  apk add \
    bash \
    openssl

VOLUME ["/ca","/certs"]
WORKDIR "/certs"

COPY certs.sh /certs.sh

ENTRYPOINT ["/certs.sh"]
CMD ["create"]
