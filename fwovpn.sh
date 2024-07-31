#!/bin/bash
# Flush existing rules
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X
sudo iptables -t nat -X
sudo iptables -t mangle -X

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Add forwarding rules
sudo iptables -A FORWARD -i tun0 -o virbr0 -j ACCEPT
sudo iptables -A FORWARD -i virbr0 -o tun0 -j ACCEPT

# Add NAT rule
sudo iptables -t nat -A POSTROUTING -s 192.168.122.0/24 -o tun0 -j MASQUERADE

# Ensure VPN client traffic can reach `virsh` network
sudo iptables -A FORWARD -i tun0 -s 192.168.123.0/24 -d 192.168.122.0/24 -j ACCEPT
sudo iptables -A FORWARD -i virbr0 -s 192.168.122.0/24 -d 192.168.123.0/24 -j ACCEPT
