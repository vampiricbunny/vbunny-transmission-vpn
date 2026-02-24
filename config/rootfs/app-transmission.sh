#!/bin/bash
set -e

# Use TRANSMISSION_HOME from environment or default
TRANSMISSION_HOME=${TRANSMISSION_HOME:-/config/transmission-home}
mkdir -p "$TRANSMISSION_HOME"

# Copy default config if it doesn't exist
if [ ! -f "$TRANSMISSION_HOME/settings.json" ] && [ -f /config-custom/transmission-settings.json ]; then
  cp /config-custom/transmission-settings.json "$TRANSMISSION_HOME/settings.json"
elif [ ! -f "$TRANSMISSION_HOME/settings.json" ] && [ -f /config/transmission-settings.json ]; then
  cp /config/transmission-settings.json "$TRANSMISSION_HOME/settings.json"
fi

# Apply environment variables to settings.json
if [ -f "$TRANSMISSION_HOME/settings.json" ]; then
  # Update RPC settings from environment
  sed -i "s/\"rpc-port\": [0-9]*/\"rpc-port\": ${TRANSMISSION_RPC_PORT:-9091}/" "$TRANSMISSION_HOME/settings.json"
  sed -i "s/\"rpc-username\": \".*\"/\"rpc-username\": \"${TRANSMISSION_RPC_USERNAME:-admin}\"/" "$TRANSMISSION_HOME/settings.json"
  sed -i "s/\"rpc-password\": \".*\"/\"rpc-password\": \"${TRANSMISSION_RPC_PASSWORD:-password}\"/" "$TRANSMISSION_HOME/settings.json"
  sed -i "s/\"rpc-authentication-required\": .*/\"rpc-authentication-required\": true/" "$TRANSMISSION_HOME/settings.json"
  
  # Update download directories
  sed -i "s|\"download-dir\": \".*\"|\"download-dir\": \"${TRANSMISSION_DOWNLOAD_DIR:-/data/completed}\"|" "$TRANSMISSION_HOME/settings.json"
  sed -i "s|\"incomplete-dir\": \".*\"|\"incomplete-dir\": \"${TRANSMISSION_INCOMPLETE_DIR:-/data/incomplete}\"|" "$TRANSMISSION_HOME/settings.json"
  
  # Update umask
  sed -i "s/\"umask\": [0-9]*/\"umask\": ${TRANSMISSION_UMASK:-2}/" "$TRANSMISSION_HOME/settings.json"
fi

# Apply forwarded port if available
if [ -f /data/wg/forwarded_port ]; then
  PORT=$(cat /data/wg/forwarded_port)
  if [ -n "$PORT" ]; then
    # Update or add peer-port in settings.json
    sed -i "s/\"peer-port\": [0-9]*/\"peer-port\": $PORT/" "$TRANSMISSION_HOME/settings.json" 2>/dev/null || \
    sed -i "s/}/, \"peer-port\": $PORT}/" "$TRANSMISSION_HOME/settings.json" 2>/dev/null || true
    echo "Transmission configured to use forwarded port: $PORT"
  fi
fi

# Set proper permissions
if [ -n "$PUID" ] && [ -n "$PGID" ]; then
  chown -R "$PUID:$PGID" "$TRANSMISSION_HOME"
  chown -R "$PUID:$PGID" /data
fi

echo "Starting Transmission with config from: $TRANSMISSION_HOME"
exec transmission-daemon \
  --foreground \
  --config-dir "$TRANSMISSION_HOME" \
  --port "${TRANSMISSION_RPC_PORT:-9091}"