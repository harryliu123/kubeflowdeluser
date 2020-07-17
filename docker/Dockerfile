FROM alpine:3.8 as builder
ARG K8S_VERSION=v1.16.4
COPY entrypoint.sh /
COPY run.sh /
RUN set -x                  && \
    apk --update upgrade    && \
    apk add ca-certificates && \
    rm -rf /var/cache/apk/* && \
    wget -O /kubectl https://storage.googleapis.com/kubernetes-release/release/$K8S_VERSION/bin/linux/amd64/kubectl && \
    wget -O /jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
    chmod +x /kubectl /jq /entrypoint.sh /run.sh

FROM alpine:3.8
ARG ldaphost 
ARG basedn
ARG basednpw
ARG bindDN
ARG rancherurl
ARG BearerToken
ARG clusterid

COPY --from=builder /kubectl /usr/local/bin/kubectl
COPY --from=builder /jq /usr/local/bin/jq
COPY --from=builder /entrypoint.sh /entrypoint.sh
COPY --from=builder /run.sh /usr/local/bin/run.sh
RUN apk add --update openldap-clients bash && \
    rm -rf /var/cache/apk/*

ENTRYPOINT ["/entrypoint.sh"]
CMD ["run.sh"]
