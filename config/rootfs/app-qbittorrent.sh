#!/bin/bash
set -e

mkdir -p /data/qbittorrent

# Copy default config if it doesn't exist
if [ ! -f /data/qbittorrent/qbittorrent.conf ] && [ -f /config/qbittorrent.conf ]; then
  cp /config/qbittorrent.conf /data/qbittorrent/qbittorrent.conf
fi

# Apply forwarded port if available (qBittorrent requires more complex config)
if [ -f /data/wg/forwarded_port ]; then
  PORT=$(cat /data/wg/forwarded_port)
  if [ -n "$PORT" ]; then
    echo "Forwarded port $PORT is available. Configure it manually in qBittorrent WebUI if needed."
    # Note: qBittorrent doesn't easily support command-line port configuration
  fi
fi

exec qbittorrent-nox \
  --profile=/data/qbittorrent \
  --webui-port=8080