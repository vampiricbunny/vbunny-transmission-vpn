# What to put where and what it does

## The workflow Mullvad expects

You do this once:

    Go to Mullvad → WireGuard → Generate key

    Pick a server

    Download wg0.conf  # or configs put them into the wireguard folder then you can pick just 1 or by country-city blank = random
    Put it in your project:
    
    config/wireguard/*.conf
go into mullvad make new wg key go to advance select "all" for all servers this will let you choose where to pick by city/country  

## Programs

this will choose what program to run. You may only pick one.

APP=transmission
APP=Transmission

APP=qbittorrent
APP=QBITTORRENT

## Web ui

whatever ip is put into local network example 192.168.1.0/24 anything on that network can connect to web ui anything else cannot. This will be important if vpn = on you wont be able to touch webui if its off does not matter.
