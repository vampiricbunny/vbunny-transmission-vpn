#!/bin/bash
set -e

###############################################################################
# Timezone
###############################################################################
if [ -n "$TZ" ]; then
  ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime || true
  echo "$TZ" > /etc/timezone || true
fi

###############################################################################
# Create required directories
###############################################################################
mkdir -p /data/completed /data/incomplete /data/watch /data/qbittorrent

###############################################################################
# User / Group setup
###############################################################################
if [ -n "$PUID" ] && [ -n "$PGID" ]; then
  addgroup -g "$PGID" appgroup 2>/dev/null || true
  adduser -D -G appgroup -u "$PUID" appuser 2>/dev/null || true
  chown -R "$PUID:$PGID" /data /config || true
fi

###############################################################################
# Normalize USE_VPN value (true/false/yes/no/1/0)
###############################################################################
VPN_VALUE="$(echo "$USE_VPN" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"

if [ "$VPN_VALUE" = "true" ] || [ "$VPN_VALUE" = "yes" ] || [ "$VPN_VALUE" = "1" ]; then
  echo "[entrypoint] VPN mode enabled"
  /usr/local/bin/wg-select.sh
  /usr/local/bin/firewall.sh
else
  echo "[entrypoint] Direct mode (no VPN)"
fi

###############################################################################
# App selection (Transmission or qBittorrent)
###############################################################################
APP_VALUE="$(echo "$APP" | tr '[:upper:]' '[:lower:]')"

case "$APP_VALUE" in
  qbittorrent)
    echo "[entrypoint] Starting qBittorrent"
    exec /usr/local/bin/app-qbittorrent.sh
    ;;
  transmission|*)
    echo "[entrypoint] Starting Transmission"
    exec /usr/local/bin/app-transmission.sh
    ;;
esac
