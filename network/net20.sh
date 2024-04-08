#!/bin/bash
echo +---------------------------+
echo -e \|  starting net20.sh\ \ \ \ \ \ \ \ \ \|
echo +---------------------------+
PS4='$LINENO : '
set -x



nmcli c delete bridge-slave-eth0
nmcli c delete bridge-slave-enc1c00
nmcli c delete cloudbr0
nmcli c delete eth0
nmcli c delete my-nic

ip link set dev enc1c00 down
ip -br a
#read -p "Press [Enter] key to continue..."
#nmcli c

nmcli con del enc1c00
nmcli con add con-name enc1c00 ifname enc1c00 type ethernet ip4 204.90.115.208/24 gw4 204.90.115.1
nmcli con mod enc1c00 ipv4.dns 8.8.8.8
nmcli con mod enc1c00 ipv4.method manual 
nmcli con up enc1c00
ip -br -c a
nmcli c
#read -p "Press [Enter] key to continue..."

#nmcli connection show


nmcli connection add type bridge autoconnect yes con-name cloudbr0 ifname cloudbr0
nmcli connection modify cloudbr0 ipv4.addresses 204.90.115.208/24 gw4 204.90.115.1 ipv4.method manual
nmcli connection modify cloudbr0 ipv4.dns 8.8.8.8
nmcli connection modify cloudbr0 bridge.stp no

nmcli connection add type bridge-slave autoconnect yes con-name bridge-slave-enc1c00 ifname bridge-slave-enc1c00 master cloudbr0
nmcli connection up cloudbr0

#Note: the following will disable and may break current ssh:

#nmcli connection down enc1c00
#nmcli connection del enc1c00