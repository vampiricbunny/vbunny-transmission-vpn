#!/bin/bash
set -e

WG_DIR="/config/wireguard"
WG_DST="/etc/wireguard/wg0.conf"

if [ ! -d "$WG_DIR" ]; then
  echo "[wg-select] ERROR: $WG_DIR does not exist. Extract Mullvad 'Download all' ZIP there."
  exit 1
fi

if [ -z "$MULLVAD_COUNTRY" ] || [ -z "$MULLVAD_CITY" ]; then
  echo "[wg-select] ERROR: MULLVAD_COUNTRY and MULLVAD_CITY must be set"
  exit 1
fi

# Example filenames: se-sto-wg-001.conf, nl-ams-wg-001.conf, etc.
PATTERN="${MULLVAD_COUNTRY}-${MULLVAD_CITY}-wg-*.conf"
MATCHES=( "$WG_DIR"/$PATTERN )

if [ ! -e "${MATCHES[0]}" ]; then
  echo "[wg-select] ERROR: No config matching pattern $PATTERN in $WG_DIR"
  exit 1
fi

SELECTED="${MATCHES[0]}"

echo "[wg-select] Using config: $(basename "$SELECTED")"

mkdir -p /etc/wireguard
cp "$SELECTED" "$WG_DST"
chmod 600 "$WG_DST"

echo "[wg-select] Bringing up WireGuard interface wg0"
wg-quick up wg0

echo "[wg-select] wg0 status:"
wg show wg0 || true
