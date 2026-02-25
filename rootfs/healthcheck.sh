#!/bin/bash
set -e

# If VPN mode, ensure wg0 is up
if [ "$USE_VPN" = "true" ]; then
  if ! ip link show wg0 >/dev/null 2>&1; then
    echo "wg0 interface missing"
    exit 1
  fi
fi

# Check WebUI based on APP
if [ "$APP" = "qbittorrent" ]; then
  curl -s -f -I http://localhost:8080 >/dev/null 2>&1 || exit 1
else
  curl -s -f -I http://localhost:9091 >/dev/null 2>&1 || exit 1
fi

exit 0
