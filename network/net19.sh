#!/bin/bash

nmcli con del "eth0"
nmcli con add con-name "eth0" ifname eth0 type ethernet ip4 192.168.10.110/24 gw4 192.168.10.1
nmcli con mod "eth0" ipv4.dns 8.8.8.8
nmcli con mod eth0 ipv4.method manual
nmcli con up eth0
nmcli con del "System eth0"

# Checked status:
# [root@test-el9-kvm almalinux]# nmcli dev status
# DEVICE  TYPE      STATE                   CONNECTION
# eth0    ethernet  connected               static-eth0
# lo      loopback  connected (externally)  lo
# 3. Add cloudbr0 KVM Linux bridge

nmcli connection show
nmcli connection add type bridge autoconnect yes con-name cloudbr0 ifname cloudbr0
nmcli connection modify cloudbr0 ipv4.addresses 192.168.10.110/24 gw4 192.168.10.1 ipv4.method manual
nmcli connection modify cloudbr0 ipv4.dns 192.168.10.1
nmcli connection modify cloudbr0 bridge.stp no
nmcli connection add type bridge-slave autoconnect yes con-name bridge-slave-eth0 ifname eth0 master cloudbr0
nmcli connection up cloudbr0
# Note: the following will disable and may break current ssh:
nmcli connection down eth0
nmcli connection del eth0