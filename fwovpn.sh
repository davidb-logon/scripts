#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
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
iptables -A FORWARD -i tun0 -o cloudbr0 -j ACCEPT
iptables -A FORWARD -i cloudbr0 -o tun0 -j ACCEPT

# Add NAT rule
iptables -t nat -A POSTROUTING -s 192.168.122.0/24 -o tun0 -j MASQUERADE

# Ensure VPN client traffic can reach `virsh` network
iptables -A FORWARD -i tun0 -s 192.168.123.0/24 -d 192.168.122.0/24 -j ACCEPT
iptables -A FORWARD -i cloudbr0 -s 192.168.122.0/24 -d 192.168.123.0/24 -j ACCEPT

sudo firewall-cmd --permanent --zone=trusted --add-source=80.178.85.20 #sefi
sudo firewall-cmd --permanent --zone=trusted --add-source=84.95.45.250 #dudi
#Open port 22 for these IP addresses in the trusted zone:
sudo firewall-cmd --permanent --zone=trusted --add-port=22/tcp
sudo firewall-cmd --permanent --zone=public --add-port=111/tcp
sudo firewall-cmd --permanent --zone=public --add-port=111/udp
sudo firewall-cmd --permanent --zone=public --add-port=2049/tcp
sudo firewall-cmd --permanent --zone=public --add-port=2049/udp
sudo firewall-cmd --permanent --zone=public --add-port=892/tcp
sudo firewall-cmd --permanent --zone=public --add-port=892/udp
sudo firewall-cmd --permanent --zone=public --add-port=5900-5920/tcp 


sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.123.0/24" destination address="192.168.122.0/24" accept'
sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.122.0/24" destination address="192.168.123.0/24" accept'

sudo firewall-cmd --reload
firewall-cmd --list-all
