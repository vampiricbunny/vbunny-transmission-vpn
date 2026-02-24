FROM alpine:3.19

RUN apk add --no-cache \
    wireguard-tools \
    iptables \
    iproute2 \
    curl \
    jq \
    bash \
    ca-certificates \
    transmission-daemon \
    qbittorrent-nox \
    tzdata \
    ip6tables

ENV MULLVAD_ACCOUNT="" \
    MULLVAD_COUNTRY="us" \
    MULLVAD_CITY="" \
    MULLVAD_PORT="51820" \
    MULLVAD_MULTIHOP_ENTRY="" \
    MULLVAD_MULTIHOP_EXIT="" \
    WG_KEY_RENEW_DAYS="0" \
    APP="transmission" \
    TZ="UTC"

COPY rootfs/*.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=30s CMD /usr/local/bin/healthcheck.sh

VOLUME ["/data"]

EXPOSE 9091 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]