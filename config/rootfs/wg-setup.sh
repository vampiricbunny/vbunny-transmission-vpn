#!/bin/bash
set -e

WG_CONF="/etc/wireguard/wg0.conf"
STATE_DIR="/data/wg"
mkdir -p "$STATE_DIR"

# Key rotation logic
NEED_NEW_KEY=1

if [ -f "$STATE_DIR/privatekey" ] && [ -f "$STATE_DIR/created_at" ]; then
  if [ "${WG_KEY_RENEW_DAYS:-0}" -eq 0 ]; then
    NEED_NEW_KEY=0
  else
    CREATED=$(cat "$STATE_DIR/created_at")
    NOW=$(date +%s)
    AGE_DAYS=$(( (NOW - CREATED) / 86400 ))
    if [ "$AGE_DAYS" -lt "$WG_KEY_RENEW_DAYS" ]; then
      NEED_NEW_KEY=0
    fi
  fi
fi

if [ "$NEED_NEW_KEY" -eq 1 ]; then
  wg genkey | tee "$STATE_DIR/privatekey" | wg pubkey > "$STATE_DIR/publickey"
  date +%s > "$STATE_DIR/created_at"
fi

PRIVATE_KEY=$(cat "$STATE_DIR/privatekey")
PUBLIC_KEY=$(cat "$STATE_DIR/publickey")

# Build Mullvad API request
DATA="account=$MULLVAD_ACCOUNT&pubkey=$PUBLIC_KEY"
[ -n "$MULLVAD_COUNTRY" ] && DATA="$DATA&country=$MULLVAD_COUNTRY"
[ -n "$MULLVAD_CITY" ] && DATA="$DATA&city=$MULLVAD_CITY"
[ -n "$MULLVAD_PORT" ] && DATA="$DATA&port=$MULLVAD_PORT"

if [ -n "$MULLVAD_MULTIHOP_ENTRY" ] && [ -n "$MULLVAD_MULTIHOP_EXIT" ]; then
  DATA="$DATA&multihop=true&entry=$MULLVAD_MULTIHOP_ENTRY&exit=$MULLVAD_MULTIHOP_EXIT"
fi

# Request WireGuard config from Mullvad with retry logic
echo "Requesting WireGuard configuration from Mullvad..."
for i in {1..5}; do
  RESP=$(curl -fsS -X POST "https://api.mullvad.net/wg/" -d "$DATA" 2>/dev/null) && break
  echo "Mullvad API attempt $i failed, retrying in 5s..."
  sleep 5
done

if [ -z "$RESP" ]; then
  echo "ERROR: Failed to get WireGuard config from Mullvad after 5 attempts"
  exit 1
fi

# Validate response
if ! echo "$RESP" | jq -e '.endpoint and .ip and .pubkey' >/dev/null 2>&1; then
  echo "ERROR: Invalid response from Mullvad API"
  echo "$RESP" | jq '.'
  exit 1
fi

ENDPOINT=$(echo "$RESP" | jq -r '.endpoint')
ADDR4=$(echo "$RESP" | jq -r '.ip')
ADDR6=$(echo "$RESP" | jq -r '.ip6 // empty')
PEER_PUBKEY=$(echo "$RESP" | jq -r '.pubkey')

# Save forwarded port if provided
PORT_FORWARD=$(echo "$RESP" | jq -r '.port // empty')
if [ -n "$PORT_FORWARD" ]; then
  echo "$PORT_FORWARD" > "$STATE_DIR/forwarded_port"
  echo "Forwarded port: $PORT_FORWARD"
  
  # Configure torrent client to use forwarded port if supported
  if [ "$APP" = "transmission" ]; then
    sed -i "s/\"peer-port\": [0-9]*/\"peer-port\": $PORT_FORWARD/" /data/transmission/settings.json 2>/dev/null || true
  elif [ "$APP" = "qbittorrent" ]; then
    # qBittorrent port configuration would go here if needed
    echo "Note: Manual port configuration may be required for qBittorrent"
  fi
fi

mkdir -p /etc/wireguard

# Write config
{
  echo "[Interface]"
  echo "PrivateKey = $PRIVATE_KEY"
  echo "Address = $ADDR4${ADDR6:+, $ADDR6}"
  echo "DNS = 10.64.0.1"
  echo ""
  echo "[Peer]"
  echo "PublicKey = $PEER_PUBKEY"
  echo "AllowedIPs = 0.0.0.0/0, ::/0"
  echo "Endpoint = $ENDPOINT"
  echo "PersistentKeepalive = 25"
} > "$WG_CONF"

# Required for wg-quick routing
sysctl -w net.ipv4.conf.all.src_valid_mark=1 >/dev/null
sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null 2>&1 || true

# Bring up interface
wg-quick down wg0 2>/dev/null || true
wg-quick up wg0

# Wait for interface to be fully up
sleep 2

# Force DNS to Mullvad (backup method)
echo "nameserver 10.64.0.1" > /etc/resolv.conf

# Verify connection
if wg show wg0 >/dev/null 2>&1; then
  echo "WireGuard interface wg0 is up"
  wg show wg0 | grep -E "endpoint|latest handshake" || true
else
  echo "ERROR: WireGuard interface failed to come up"
  exit 1
fi