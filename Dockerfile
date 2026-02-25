FROM alpine:3.20

RUN apk add --no-cache \
    bash \
    curl \
    tzdata \
    sudo \
    python3 \
    iptables \
    wireguard-tools \
    openresolv \
    transmission-daemon \
    qbittorrent-nox

RUN mkdir -p /config /data /etc/wireguard /defaults

COPY rootfs/start.sh /start.sh
COPY rootfs/userSetup.sh /userSetup.sh
COPY rootfs/updateSettings.py /updateSettings.py
COPY rootfs/wg-select.sh /wg-select.sh
COPY rootfs/transmission-default-settings.json /defaults/transmission-default-settings.json
COPY rootfs/qbittorrent.conf /defaults/qbittorrent.conf

RUN chmod +x /start.sh /userSetup.sh /wg-select.sh

RUN echo "appuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

VOLUME ["/config", "/data", "/config/wireguard"]

EXPOSE 9091 8080

ENTRYPOINT ["/start.sh"]
