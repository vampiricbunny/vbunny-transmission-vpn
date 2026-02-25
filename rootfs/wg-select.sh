#!/bin/bash
set -e

WG_DIR="/config/wireguard"
WG_DST="/etc/wireguard/wg0.conf"

mkdir -p /etc/wireguard

COUNTRY="$(echo "${MULLVAD_COUNTRY}" | tr '[:upper:]' '[:lower:]')"
CITY="$(echo "${MULLVAD_CITY}" | tr '[:upper:]' '[:lower:]')"

mapfile -t ALL_CONFIGS < <(find "${WG_DIR}" -maxdepth 1 -name "*.conf" -type f | sort)

if [ ${#ALL_CONFIGS[@]} -eq 0 ]; then
  echo "[wg-select] ERROR: No configs found"
  exit 1
fi

MATCHES=()

if [ -z "${COUNTRY}" ] && [ -z "${CITY}" ]; then
  MATCHES=("${ALL_CONFIGS[@]}")
elif [ -n "${COUNTRY}" ] && [ -z "${CITY}" ]; then
  for c in "${ALL_CONFIGS[@]}"; do
    base="$(basename "$c" .conf | tr '[:upper:]' '[:lower:]')"
    [[ "$base" == *"$COUNTRY"* ]] && MATCHES+=("$c")
  done
else
  for c in "${ALL_CONFIGS[@]}"; do
    base="$(basename "$c" .conf | tr '[:upper:]' '[:lower:]')"
    [[ "$base" == *"$COUNTRY"* && "$base" == *"$CITY"* ]] && MATCHES+=("$c")
  done
fi

if [ ${#MATCHES[@]} -eq 0 ]; then
  echo "[wg-select] ERROR: No matching configs"
  exit 1
fi

SELECTED="${MATCHES[$((RANDOM % ${#MATCHES[@]}))]}"

cp "${SELECTED}" "${WG_DST}"
chmod 600 "${WG_DST}"

wg-quick up wg0
sleep 2
