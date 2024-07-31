#!/bin/bash

# Flush existing rules
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X
iptables -t nat -X
iptables -t mangle -X

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Add forwarding rules
iptables -A FORWARD -i tun0 -o virbr0 -j ACCEPT
iptables -A FORWARD -i virbr0 -o tun0 -j ACCEPT

# Add NAT rule
iptables -t nat -A POSTROUTING -s 192.168.122.0/24 -o tun0 -j MASQUERADE

# Ensure VPN client traffic can reach `virsh` network
iptables -A FORWARD -i tun0 -s 192.168.123.0/24 -d 192.168.122.0/24 -j ACCEPT
iptables -A FORWARD -i virbr0 -s 192.168.122.0/24 -d 192.168.123.0/24 -j ACCEPT
