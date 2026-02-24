#!/bin/bash

# Check WireGuard interface
if ! wg show wg0 >/dev/null 2>&1; then
  echo "WireGuard interface not found"
  exit 1
fi

# Check if we have at least one peer
PEERS=$(wg show wg0 peers | wc -l)
if [ "$PEERS" -lt 1 ]; then
  echo "No WireGuard peers"
  exit 1
fi

# Check if the interface has an IP
if ! ip addr show wg0 | grep -q "inet "; then
  echo "WireGuard interface has no IPv4 address"
  exit 1
fi

# Check handshake (optional - comment out if too strict)
LATEST_HANDSHAKE=$(wg show wg0 latest-handshakes | awk '{print $2}')
NOW=$(date +%s)
if [ -n "$LATEST_HANDSHAKE" ] && [ "$LATEST_HANDSHAKE" -gt 0 ]; then
  HANDSHAKE_AGE=$((NOW - LATEST_HANDSHAKE))
  if [ "$HANDSHAKE_AGE" -gt 180 ]; then
    echo "Warning: No recent handshake (${HANDSHAKE_AGE}s old)"
    # Don't exit, just warn
  fi
fi

# Check if the torrent client is responding
case "$APP" in
  transmission)
    if ! curl -s -f -I http://localhost:9091 >/dev/null 2>&1; then
      echo "Transmission web UI not responding"
      exit 1
    fi
    ;;
  qbittorrent)
    if ! curl -s -f -I http://localhost:8080 >/dev/null 2>&1; then
      echo "qBittorrent web UI not responding"
      exit 1
    fi
    ;;
esac

# Optional: Test external connectivity (uncomment if you want this check)
# if ! curl -s --max-time 5 https://am.i.mullvad.net/connected | grep -q "You are connected"; then
#   echo "Not connected to Mullvad"
#   exit 1
# fi

echo "Health check passed"
exit 0