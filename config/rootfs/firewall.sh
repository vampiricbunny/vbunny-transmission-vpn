#!/bin/bash
set -e

# Default Mullvad WireGuard port
MULLVAD_PORT=${MULLVAD_PORT:-51820}

# Flush everything
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

# Default deny
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow LAN access (optional - comment out if you want stricter isolation)
iptables -A INPUT -s 192.168.0.0/16 -j ACCEPT
iptables -A OUTPUT -d 192.168.0.0/16 -j ACCEPT
iptables -A INPUT -s 10.0.0.0/8 -j ACCEPT
iptables -A OUTPUT -d 10.0.0.0/8 -j ACCEPT
iptables -A INPUT -s 172.16.0.0/12 -j ACCEPT
iptables -A OUTPUT -d 172.16.0.0/12 -j ACCEPT

# Allow DHCP (if needed)
iptables -A OUTPUT -p udp --dport 67:68 -j ACCEPT
iptables -A INPUT -p udp --sport 67:68 -j ACCEPT

# Allow Mullvad API before VPN is up (IPv4 and IPv6)
iptables -A OUTPUT -p tcp -d api.mullvad.net --dport 443 -j ACCEPT
ip6tables -A OUTPUT -p tcp -d api.mullvad.net --dport 443 -j ACCEPT 2>/dev/null || true

# Allow WireGuard handshake to Mullvad
iptables -A OUTPUT -p udp --dport $MULLVAD_PORT -j ACCEPT
ip6tables -A OUTPUT -p udp --dport $MULLVAD_PORT -j ACCEPT 2>/dev/null || true

# Allow DNS temporarily (will be restricted to wg0 after connection)
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow DNS over wg0
iptables -A OUTPUT -o wg0 -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -o wg0 -p tcp --dport 53 -j ACCEPT

# Allow traffic inside VPN tunnel
iptables -A INPUT -i wg0 -j ACCEPT
iptables -A OUTPUT -o wg0 -j ACCEPT

# Allow WebUI ports from LAN
iptables -A INPUT -p tcp --dport 9091 -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT

# NAT for outbound traffic (ensures proper routing)
iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE

# Optional: Prevent IPv6 leaks if not using IPv6
ip6tables -P INPUT DROP 2>/dev/null || true
ip6tables -P OUTPUT DROP 2>/dev/null || true
ip6tables -P FORWARD DROP 2>/dev/null || true

# Allow IPv6 on wg0 if we have IPv6 address
if ip addr show wg0 | grep -q "inet6"; then
  ip6tables -A INPUT -i wg0 -j ACCEPT 2>/dev/null || true
  ip6tables -A OUTPUT -o wg0 -j ACCEPT 2>/dev/null || true
  ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true
  ip6tables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true
fi

echo "Firewall rules applied successfully"