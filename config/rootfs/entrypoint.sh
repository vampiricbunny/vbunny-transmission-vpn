#!/bin/bash
set -e

# Validate required environment variables
if [ -z "$MULLVAD_ACCOUNT" ]; then
  echo "ERROR: MULLVAD_ACCOUNT not set"
  exit 1
fi

# Validate multihop configuration
if [ -n "$MULLVAD_MULTIHOP_ENTRY" ] || [ -n "$MULLVAD_MULTIHOP_EXIT" ]; then
  if [ -z "$MULLVAD_MULTIHOP_ENTRY" ] || [ -z "$MULLVAD_MULTIHOP_EXIT" ]; then
    echo "ERROR: Both MULLVAD_MULTIHOP_ENTRY and MULLVAD_MULTIHOP_EXIT must be set for multihop"
    exit 1
  fi
fi

# Create TUN device if it doesn't exist
if [ ! -c /dev/net/tun ]; then
  mkdir -p /dev/net
  mknod /dev/net/tun c 10 200 || true
fi

# Apply global permissions if enabled
if [ "${GLOBAL_APPLY_PERMISSIONS}" = "true" ] && [ -n "$PUID" ] && [ -n "$PGID" ]; then
  echo "Applying permissions for PUID: $PUID, PGID: $PGID"
  # Change ownership of volumes
  chown -R "$PUID:$PGID" /config 2>/dev/null || true
  chown -R "$PUID:$PGID" /data 2>/dev/null || true
fi

# Setup WireGuard and firewall
/usr/local/bin/wg-setup.sh
/usr/local/bin/firewall.sh

# Start the appropriate torrent client
case "$APP" in
  transmission)
    echo "Starting Transmission..."
    exec /usr/local/bin/app-transmission.sh
    ;;
  qbittorrent)
    echo "Starting qBittorrent..."
    exec /usr/local/bin/app-qbittorrent.sh
    ;;
  *)
    echo "ERROR: Unknown APP=$APP (must be 'transmission' or 'qbittorrent')"
    exit 1
    ;;
esac