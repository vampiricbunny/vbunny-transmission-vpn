#!/bin/bash
set -e

QBT_DIR="/data/qbittorrent"
mkdir -p "$QBT_DIR"

# Seed config if missing
if [ ! -f "$QBT_DIR/qbittorrent.conf" ] && [ -f /config/qbittorrent.conf ]; then
  echo "[app-qbittorrent] Seeding config from /config/qbittorrent.conf"
  cp /config/qbittorrent.conf "$QBT_DIR/qbittorrent.conf"
fi

# Ownership
if [ -n "$PUID" ] && [ -n "$PGID" ]; then
  chown -R "$PUID:$PGID" "$QBT_DIR" /data || true
  su_exec="su -s /bin/bash appuser -c"
else
  su_exec=""
fi

echo "[app-qbittorrent] Starting qBittorrent WebUI on 8080"

CMD="qbittorrent-nox --profile=\"$QBT_DIR\" --webui-port=8080"

if [ -n "$su_exec" ]; then
  eval $su_exec "\"$CMD\""
else
  eval "$CMD"
fi
