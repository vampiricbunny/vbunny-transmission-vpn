#!/bin/bash
set -e

PUID=${PUID:-1000}
PGID=${PGID:-1000}

# Create group
if ! getent group "${PGID}" >/dev/null 2>&1; then
  addgroup -g "${PGID}" appgroup
fi

# Create user
if ! id -u appuser >/dev/null 2>&1; then
  adduser -D -u "${PUID}" -G appgroup appuser
fi
