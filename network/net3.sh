mv -f /etc/NetworkManager/conf.d/10-globally-managed-devices.conf /root/10-globally-managed-devices.conf.original
touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf
systemctl start NetworkManager
systemctl enable NetworkManager

nmcli con show | awk '{if ($1!="NAME") print "nmcli con delete  '"$2"'"}' | sh
nmcli con delete enc1c00
gmcli con add type ethernet con-name enc1c00 ifname enc1c00 ip4 204.90.115.208/24 gw4 204.90.115.1
nmcli con modify enc1c00 ipv4.dns 192.203.134.2
nmcli con modify enc1c00 ipv4.dns-search dal-ebis.ihost.com
nmcli con modify enc1c00 ipv4.dns-search wave.log-on.com
nmcli con up enc1c00
#nmcli con add ifname cloudbr0 type bridge con-name cloudbr0
#nmcli connection modify cloudbr0 ipv4.addresses '204.90.115.208/24' ipv4.gateway '204.90.115.1' ipv4.dns '8.8.8.8' ipv4.dns-search 'wave.log-on.com' ipv4.method manual ipv6.method disabled
#nmcli connection add con-name eth0 ifname eth0 type ethernet
#nmcli con add type bridge-slave ifname eth0 master cloudbr0
#nmcli connection show
#nmcli con down enc1c00
#nmcli con up cloudbr0
#nmcli con up eth0
#nmcli con up enc1c00
nmcli con show
nmcli device status

nmcli con show
ip a
ls /sys/devices/virtual/net/ 
