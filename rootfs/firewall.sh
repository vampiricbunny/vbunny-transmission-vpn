#!/bin/bash
set -e

echo "[firewall] Applying kill-switch firewall rules"

# Flush
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

# Default drop
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Established/related
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# LAN access
if [ -n "$LOCAL_NETWORK" ]; then
  echo "[firewall] Allowing LAN: $LOCAL_NETWORK"
  iptables -A INPUT -s "$LOCAL_NETWORK" -j ACCEPT
  iptables -A OUTPUT -d "$LOCAL_NETWORK" -j ACCEPT
fi

# DNS via VPN
iptables -A OUTPUT -o wg0 -p udp --dport 53 -j ACCEPT

# All traffic via VPN
iptables -A OUTPUT -o wg0 -j ACCEPT
iptables -A INPUT -i wg0 -j ACCEPT

echo "[firewall] Kill-switch active: only wg0 + LAN allowed"
