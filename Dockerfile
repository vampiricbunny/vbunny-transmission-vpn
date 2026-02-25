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
    tzdata

ENV USE_VPN="true" \
    APP="transmission" \
    MULLVAD_COUNTRY="" \
    MULLVAD_CITY="" \
    LOCAL_NETWORK="" \
    PUID="1000" \
    PGID="100" \
    TZ="America/Los_Angeles" \
    TRANSMISSION_HOME="/config/transmission-home" \
    TRANSMISSION_RPC_PORT="9091" \
    TRANSMISSION_RPC_USERNAME="" \
    TRANSMISSION_RPC_PASSWORD="" \
    TRANSMISSION_DOWNLOAD_DIR="/data/completed" \
    TRANSMISSION_INCOMPLETE_DIR="/data/incomplete" \
    TRANSMISSION_WATCH_DIR="/data/watch" \
    TRANSMISSION_UMASK="2"

# Copy scripts
COPY rootfs/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh || true

VOLUME ["/data", "/config", "/config/wireguard"]


EXPOSE 9091 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
