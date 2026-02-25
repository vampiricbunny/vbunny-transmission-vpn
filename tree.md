vbunny.transmission-vpn/
│
├── docker-compose.yml
├── Dockerfile
├── .env
│
├── config/                      # This is your host-mounted persistent config
│   ├── transmission-home/
│   ├── qbittorrent/
│   └── wireguard/               # <-- Your Mullvad *.conf files go here
│       ├── us-sea-001.conf
│       ├── us-sea-002.conf
│       └── etc...
│
└── rootfs/
    ├── start.sh
    ├── userSetup.sh
    ├── wg-select.sh
    ├── updateSettings.py
    ├── transmission-default-settings.json
    └── qbittorrent.conf
