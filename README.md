# vbunnytransmission/vpn – Mullvad WireGuard Torrent Box

All‑in‑one torrent container:

- WireGuard via Mullvad API
- Kill‑switch (iptables)
- Transmission or qBittorrent (APP env)
- Optional key rotation (default: off)

## Environment Variables

- `MULLVAD_ACCOUNT` (required)
- `APP` – `transmission` or `qbittorrent`
- `MULLVAD_COUNTRY`
- `MULLVAD_CITY`
- `MULLVAD_PORT`
- `MULLVAD_MULTIHOP_ENTRY`
- `MULLVAD_MULTIHOP_EXIT`
- `WG_KEY_RENEW_DAYS` – `0` = never rotate (default)

## Build

```bash
docker build -t vbunnytransmission/vpn .

Run Example
bash

docker run -d \
  --name torrentbox \
  --cap-add=NET_ADMIN \
  --device=/dev/net/tun \
  -e MULLVAD_ACCOUNT=123456789012 \
  -e APP=transmission \
  -v $(pwd)/data:/data \
  -v $(pwd)/config:/config:ro \
  -p 9091:9091 \
  vbunnytransmission/vpn

Code