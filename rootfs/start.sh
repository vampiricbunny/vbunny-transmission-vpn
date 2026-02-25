#!/bin/bash
set -e

PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "[start] PUID=${PUID} PGID=${PGID}"

# TIMEZONE
if [ -n "${TZ}" ]; then
  cp "/usr/share/zoneinfo/${TZ}" /etc/localtime || true
  echo "${TZ}" > /etc/timezone
else
  cp /usr/share/zoneinfo/UTC /etc/localtime
  echo "UTC" > /etc/timezone
fi

echo "[start] Current date/time: $(date)"

# USER SETUP
source /userSetup.sh

# DIRECTORIES
mkdir -p /data/completed /data/incomplete /data/watch
mkdir -p /config/transmission-home /config/qbittorrent /config/wireguard
chown -R "${PUID}:${PGID}" /data /config

# LOCAL NETWORK
if [ -n "${LOCAL_NETWORK}" ]; then
  echo "[start] Using LOCAL_NETWORK from .env: ${LOCAL_NETWORK}"
  ALLOW_NET="${LOCAL_NETWORK}"
else
  LAN_LINE=$(ip -4 addr show eth0 | grep "inet ")
  LAN_IP=$(echo "$LAN_LINE" | awk '{print $2}')
  LAN_NETWORK=$(ipcalc "$LAN_IP" | grep NETWORK | cut -d= -f2)
  LAN_NETMASK=$(ipcalc "$LAN_IP" | grep NETMASK | cut -d= -f2)
  ALLOW_NET="${LAN_NETWORK}/${LAN_NETMASK}"
  echo "[start] Auto-detected LAN: ${ALLOW_NET}"
fi

# DOCKER SUBNET
DOCKER_SUBNET=$(ip route | grep "172." | grep -v default | awk '{print $1}' | head -n1)
if [ -n "${DOCKER_SUBNET}" ]; then
  echo "[start] Detected Docker subnet: ${DOCKER_SUBNET}"
else
  echo "[start] No docker subnet detected (host mode)"
fi

# VPN + KILL SWITCH
TUN_VALUE="$(echo "${TUN_ENABLED}" | tr '[:upper:]' '[:lower:]')"

if [ "${TUN_VALUE}" = "true" ] || [ "${TUN_VALUE}" = "1" ] || [ "${TUN_VALUE}" = "yes" ]; then
  echo "[start] VPN enabled"

  if [ -z "$(ls -A /config/wireguard/*.conf 2>/dev/null)" ]; then
    echo "[start] ERROR: No WireGuard configs found in /config/wireguard/"
    exit 1
  fi

  /wg-select.sh

  echo "[start] Applying kill-switch"

  iptables -F
  iptables -t nat -F
  iptables -t mangle -F
  iptables -X

  iptables -P INPUT DROP
  iptables -P FORWARD DROP
  iptables -P OUTPUT DROP

  iptables -A INPUT -i lo -j ACCEPT
  iptables -A OUTPUT -o lo -j ACCEPT
  iptables -A INPUT -s 127.0.0.1 -j ACCEPT
  iptables -A OUTPUT -d 127.0.0.1 -j ACCEPT

  iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

  iptables -A INPUT -i wg0 -j ACCEPT
  iptables -A OUTPUT -o wg0 -j ACCEPT

  iptables -A OUTPUT -o wg0 -p udp --dport 53 -j ACCEPT

  iptables -A INPUT -s "${ALLOW_NET}" -j ACCEPT
  iptables -A OUTPUT -d "${ALLOW_NET}" -j ACCEPT

  iptables -A INPUT -s "${ALLOW_NET}" -p tcp --dport 9091 -j ACCEPT
  iptables -A OUTPUT -p tcp --sport 9091 -d "${ALLOW_NET}" -j ACCEPT

  iptables -A INPUT -s "${ALLOW_NET}" -p tcp --dport 8080 -j ACCEPT
  iptables -A OUTPUT -p tcp --sport 8080 -d "${ALLOW_NET}" -j ACCEPT

  if [ -n "${DOCKER_SUBNET}" ]; then
    iptables -A INPUT -s "${DOCKER_SUBNET}" -j ACCEPT
    iptables -A OUTPUT -d "${DOCKER_SUBNET}" -j ACCEPT

    iptables -A INPUT -s "${DOCKER_SUBNET}" -p tcp --dport 9091 -j ACCEPT
    iptables -A OUTPUT -p tcp --sport 9091 -d "${DOCKER_SUBNET}" -j ACCEPT

    iptables -A INPUT -s "${DOCKER_SUBNET}" -p tcp --dport 8080 -j ACCEPT
    iptables -A OUTPUT -p tcp --sport 8080 -d "${DOCKER_SUBNET}" -j ACCEPT
  fi

  iptables -A OUTPUT -p udp --dport 67:68 -j ACCEPT
  iptables -A INPUT -p udp --sport 67:68 -j ACCEPT
else
  echo "[start] VPN disabled"
fi

# APP SELECTION
APP_VALUE="$(echo "${APP}" | tr '[:upper:]' '[:lower:]')"

case "${APP_VALUE}" in
  qbittorrent)
    exec sudo -u "#${PUID}" qbittorrent-nox --profile=/config/qbittorrent --webui-port=8080
    ;;
  transmission|*)
    export TRANSMISSION_HOME=/config/transmission-home
    export TRANSMISSION_DOWNLOAD_DIR=/data/completed
    export TRANSMISSION_INCOMPLETE_DIR=/data/incomplete
    export TRANSMISSION_WATCH_DIR=/data/watch

    python3 /updateSettings.py
    chown -R "${PUID}:${PGID}" /config/transmission-home

    exec sudo -u "#${PUID}" transmission-daemon -f --log-level=error --config-dir /config/transmission-home
    ;;
esac
