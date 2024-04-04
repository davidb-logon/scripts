#!/bin/bash
echo +---------------------------+
echo -e \|  starting netr.sh\ \ \ \ \ \ \ \ \ \ \|
echo +---------------------------+
PS4='$LINENO : '
set -x

cio_ignore -r 1c00
cio_ignore -r 1c01
cio_ignore -r 1c02
chzdev -e 1c00
# Changes for NetworkManager:
mv /etc/sysconfig/network-scripts/ifcfg-eth0 /root/ifcfg-eth0.original
mv /etc/NetworkManager/conf.d/10-globally-managed-devices.conf /root/10-globally-managed-devices.conf.original
touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf

systemctl start NetworkManager
systemctl enable NetworkManager
nmcli con show
nmcli con delete 0ee225e7-a2e3-4279-aed0-04d120dfc09b
nmcli con delete 2ea4d052-7bae-44cd-8dd0-3f2292c6032e
nmcli con add type ethernet con-name enc1c00 ifname enc1c00 ip4 204.90.115.208/24 gw4 204.90.115.1
nmcli con modify enc1c00 ipv4.dns 192.203.134.2
nmcli con modify enc1c00 ipv4.dns-search dal-ebis.ihost.com
nmcli con modify enc1c00 ipv4.dns-search wave.log-on.com
nmcli con up enc1c00
ip -br -c a
nmcli con show