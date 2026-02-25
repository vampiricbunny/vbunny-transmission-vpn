#!/bin/bash
set -e

TRANSMISSION_HOME=${TRANSMISSION_HOME:-/config/transmission-home}
mkdir -p "$TRANSMISSION_HOME"

SETTINGS="$TRANSMISSION_HOME/settings.json"

# If no settings.json, seed from /config/transmission-settings.json if present
if [ ! -f "$SETTINGS" ]; then
  if [ -f /config/transmission-settings.json ]; then
    echo "[app-transmission] Using /config/transmission-settings.json as base"
    cp /config/transmission-settings.json "$SETTINGS"
  else
    echo "[app-transmission] No transmission-settings.json found, creating default"
    cat > "$SETTINGS" <<EOF
{
  "download-dir": "/data/completed",
  "incomplete-dir": "/data/incomplete",
  "incomplete-dir-enabled": true,
  "watch-dir": "/data/watch",
  "watch-dir-enabled": true,
  "rpc-enabled": true,
  "rpc-bind-address": "0.0.0.0",
  "rpc-port": 9091,
  "rpc-authentication-required": false,
  "rpc-whitelist-enabled": false,
  "peer-port-random-on-start": true,
  "umask": 2
}
EOF
  fi
fi

tmp="$SETTINGS.tmp"

# RPC auth
if [ -n "$TRANSMISSION_RPC_USERNAME" ]; then
  jq --arg u "$TRANSMISSION_RPC_USERNAME" \
     '.["rpc-username"]=$u | .["rpc-authentication-required"]=true' \
     "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
else
  jq '.["rpc-username"]="" | .["rpc-authentication-required"]=false' \
     "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
fi

if [ -n "$TRANSMISSION_RPC_PASSWORD" ]; then
  jq --arg p "$TRANSMISSION_RPC_PASSWORD" \
     '.["rpc-password"]=$p' \
     "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
else
  jq '.["rpc-password"]=""' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
fi

# Directories
jq --arg d "$TRANSMISSION_DOWNLOAD_DIR" \
   --arg i "$TRANSMISSION_INCOMPLETE_DIR" \
   --arg w "$TRANSMISSION_WATCH_DIR" \
   '.["download-dir"]=$d | .["incomplete-dir"]=$i | .["watch-dir"]=$w' \
   "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"

# Ownership
if [ -n "$PUID" ] && [ -n "$PGID" ]; then
  chown -R "$PUID:$PGID" "$TRANSMISSION_HOME" /data || true
  su_exec="su -s /bin/bash appuser -c"
else
  su_exec=""
fi

echo "[app-transmission] Starting Transmission"
echo "[app-transmission] RPC user: ${TRANSMISSION_RPC_USERNAME:-<none>}"

CMD="transmission-daemon --foreground --config-dir \"$TRANSMISSION_HOME\" --port ${TRANSMISSION_RPC_PORT:-9091}"

if [ -n "$su_exec" ]; then
  eval $su_exec "\"$CMD\""
else
  eval "$CMD"
fi
