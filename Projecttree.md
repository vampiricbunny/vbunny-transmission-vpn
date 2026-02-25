vbunny-mullvad-vpn/
├── Dockerfile
├── docker-compose.yml
├── .env
├── config/
│   ├── qbittorrent.conf              # your existing file
│   ├── transmission-settings.json    # your existing file
│   └── wireguard/                    # you extract Mullvad "Download all" here
│       ├── se-sto-wg-001.conf
│       ├── se-sto-wg-002.conf
│       ├── nl-ams-wg-001.conf
│       └── ... note this is also mappable incase docker container has no gui
├── data/                             # created by Docker bind mount
└── rootfs/
    ├── entrypoint.sh
    ├── wg-select.sh
    ├── firewall.sh
    ├── app-transmission.sh
    ├── app-qbittorrent.sh
    └── healthcheck.sh
