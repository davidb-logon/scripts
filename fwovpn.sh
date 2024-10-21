#!/bin/bash
#first log the current environment of iptables for learning later
IPTLOG=/data/ipt.log
CD=$(date +%F-%H%M)
echo "============== $CD =============" >> $IPTLOG
iptables -L -t nat -v -n >> $IPTLOG
firewall-cmd --list-all >> $IPTLOG
ip -br a >> $IPTLOG
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
# iptables -A FORWARD -i tun0 -o cloudbr0 -j ACCEPT
# iptables -A FORWARD -i cloudbr0 -o tun0 -j ACCEPT

# Add NAT rule
# iptables -t nat -A POSTROUTING -s 192.168.122.0/24 -o tun0 -j MASQUERADE

# Ensure VPN client traffic can reach `virsh` network
# iptables -A FORWARD -i tun0 -s 192.168.123.0/24 -d 192.168.122.0/24 -j ACCEPT
# iptables -A FORWARD -i cloudbr0 -s 192.168.122.0/24 -d 192.168.123.0/24 -j ACCEPT

iptables -t nat -A POSTROUTING -o enc1c00 -j MASQUERADE
iptables -A FORWARD -i enc1c00 -o virbr0 -j ACCEPT
iptables -A FORWARD -i virbr0 -o enc1c00 -j ACCEPT


sudo firewall-cmd --permanent --zone=trusted --add-source=80.178.85.20 #sefi
sudo firewall-cmd --permanent --zone=trusted --add-source=84.95.45.250 #dudi
sudo firewall-cmd --permanent --zone=trusted --add-source=84.228.94.152 #sharon
#Open port 22 for these IP addresses in the trusted zone:
sudo firewall-cmd --permanent --zone=trusted --add-port=22/tcp
sudo firewall-cmd --permanent --zone=public --add-port=111/tcp
sudo firewall-cmd --permanent --zone=public --add-port=111/udp
sudo firewall-cmd --permanent --zone=public --add-port=2049/tcp
sudo firewall-cmd --permanent --zone=public --add-port=2049/udp
sudo firewall-cmd --permanent --zone=public --add-port=892/tcp
sudo firewall-cmd --permanent --zone=public --add-port=892/udp
sudo firewall-cmd --permanent --zone=public --add-port=5900-5920/tcp 


# sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.123.0/24" destination address="192.168.122.0/24" accept'
# sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.122.0/24" destination address="192.168.123.0/24" accept'

sudo firewall-cmd --reload
firewall-cmd --list-all
