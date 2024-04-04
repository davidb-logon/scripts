#!/bin/bash
echo +---------------------------+
echo -e \|  starting net19.sh\ \ \ \ \ \ \ \ \ \|
echo +---------------------------+
set1(){
nmcli connection add type bridge autoconnect yes con-name cloudbr0 ifname veth0
nmcli connection modify cloudbr0 ipv4.addresses 192.168.10.110/24 gw4 192.168.10.1 ipv4.method manual
nmcli connection modify cloudbr0 ipv4.dns 192.168.10.1
nmcli connection modify cloudbr0 bridge.stp no
nmcli connection add type bridge-slave autoconnect yes con-name bridge-slave-eth0 ifname eth0 master cloudbr0
nmcli connection up cloudbr0
}
set2(){
nmcli connection add type bridge con-name cloudbr0 ifname cloudbr0
nmcli connection add type bridge-slave con-name bridge-slave-enc1c00 ifname enc1c00 master cloudbr0
nmcli connection modify cloudbr0 ipv4.addresses 192.168.10.1/24 ipv4.method manual
nmcli connection modify cloudbr0 ipv4.dns 8.8.8.8
nmcli connection up cloudbr0
}
PS4='$LINENO : '
set -x
# First delete old tries
nmcli c delete bridge-slave-eth0
nmcli c delete cloudbr0
nmcli c delete eth0
nmcli c delete my-nic
nmcli c

# Step 1: Create a new virtual network interface based on enc1c00
#nmcli connection add type dummy con-name eth0 ifname enc1c00:0
#nmcli con add con-name eth0 type dummy ifname veth0 ip4 192.168.20.111/24
#nmcli con add con-name eth0 ifname enc1c00:0 type ethernet ip4 192.168.10.110/24 gw4 192.168.10.1

# Step 2: Assign properties to the virtual network interface (optional)
#nmcli connection modify eth0 ipv4.method auto

# Step 3: Bring up the virtual network interface
#nmcli connection up eth0
set2
nmcli c
exit
#nmcli con del "eth0"
#nmcli con add con-name "eth0" ifname eth0 type ethernet ip4 192.168.10.110/24 gw4 192.168.10.1
#nmcli con mod "eth0" ipv4.dns 8.8.8.8
#nmcli con mod eth0 ipv4.method manual
#nmcli con up eth0
#nmcli con del "System eth0"

# Checked status:
# [root@test-el9-kvm almalinux]# nmcli dev status
# DEVICE  TYPE      STATE                   CONNECTION
# eth0    ethernet  connected               static-eth0
# lo      loopback  connected (externally)  lo
# 3. Add cloudbr0 KVM Linux bridge

nmcli connection show
nmcli connection add type bridge autoconnect yes con-name cloudbr0 ifname veth0
nmcli connection modify cloudbr0 ipv4.addresses 192.168.10.110/24 gw4 192.168.10.1 ipv4.method manual
nmcli connection modify cloudbr0 ipv4.dns 192.168.10.1
nmcli connection modify cloudbr0 bridge.stp no
nmcli connection add type bridge-slave autoconnect yes con-name bridge-slave-eth0 ifname eth0 master veth0
nmcli connection up cloudbr0
nmcli c
# Note: the following will disable and may break current ssh:
#nmcli connection down eth0
#nmcli connection del eth0
