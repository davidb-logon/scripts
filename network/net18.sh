#!/bin/bash
echo +---------------------------+
echo -e \|  starting net18.sh\ \ \ \ \ \ \ \ \ \|
echo +---------------------------+
ip -br a
if [[ $(ip -br a | grep -cv  '^lo\|^enc1c00') != 0 ]]; then
  myif=$(ip -br a | grep -v  '^lo\|^enc1c00' |  cut -d ' ' -f1);cmd="ip link delete dev ";while read -r line; do $cmd "$line"; done <<< "$myif"
fi 
PS4='$LINENO : '
set -x
# Delete existing bridge and interface configurations
ip addr del 204.90.115.208/24 dev enc1c00
cio_ignore -r 1c00
cio_ignore -r 1c01
cio_ignore -r 1c02
chzdev -e 1c00
# Create a bridge named cloudbr0
ip link add name cloudbr0 type bridge

# Add enc1c00 interface to the bridge
ip link set dev enc1c00 master cloudbr0

# Set the same IP address on cloudbr0 as on enc1c00
ip address add 204.90.115.208/24 dev cloudbr0
ip -br a
echo ====================================
# Activate the interfaces
ip link set dev enc1c00 up
ip link show cloudbr0

ip link set dev cloudbr0 up
ip route
ip -br a
ping -c 1 204.90.115.208
g Delete existing default route
ip route delete default

# Add default route via the gateway for cloudbr0
ip route add default via 204.90.115.1 dev cloudbr0
ip -br a
ping -c 1 204.90.115.208
ip link set dev enc1c00 down
ip link set dev enc1c00 up
ip link set dev cloudbr0 down
ip link set dev cloudbr0 up

# Sleep for a few seconds to ensure the interface configurations are applied
sleep 5

echo ======= Display the configured interfaces
ip -br a
ip route

# Add DNS server to resolv.conf
echo nameserver 8.8.8.8 >> /etc/resolv.conf

# Ping a domain to test connectivity
ping -c 1 cnn.com

# Display bridge information
brctl show

