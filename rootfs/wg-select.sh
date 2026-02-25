#!/bin/bash
set -e

WG_DIR="/config/wireguard"
WG_DST="/etc/wireguard/wg0.conf"

if [ ! -d "$WG_DIR" ]; then
  echo "[wg-select] ERROR: $WG_DIR missing. Add Mullvad configs."
  exit 1
fi

COUNTRY="$(echo "$MULLVAD_COUNTRY" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
CITY="$(echo "$MULLVAD_CITY" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"

# Build search pattern
if [ -z "$COUNTRY" ] && [ -z "$CITY" ]; then
  # Random from all configs
  MATCHES=( "$WG_DIR"/*.conf )
elif [ -n "$COUNTRY" ] && [ -z "$CITY" ]; then
  # Random city in country
  MATCHES=( "$WG_DIR"/${COUNTRY}-*-wg-*.conf )
else
  # Exact match
  MATCHES=( "$WG_DIR"/${COUNTRY}-${CITY}-wg-*.conf )
fi

if [ ${#MATCHES[@]} -eq 0 ]; then
  echo "[wg-select] ERROR: No matching WireGuard configs found."
  exit 1
fi

# Pick random config
SELECTED="${MATCHES[$RANDOM % ${#MATCHES[@]}]}"

echo "[wg-select] Selected: $(basename "$SELECTED")"

mkdir -p /etc/wireguard
cp "$SELECTED" "$WG_DST"
chmod 600 "$WG_DST"

wg-quick up wg0
wg show wg0 || true
