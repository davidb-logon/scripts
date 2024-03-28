#this is the default net setup by ibm
cio_ignore -r 1c00
cio_ignore -r 1c01
cio_ignore -r 1c02
chzdev -e 1c00
systemctl stop NetworkManager
mv -f /etc/NetworkManager/conf.d/10-globally-managed-devices.conf /root/10-globally-managed-devices.conf.original
touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf
systemctl start NetworkManager
systemctl enable NetworkManager
nmcli con show
nmcli con del enc1c00
nmcli con add type ethernet con-name enc1c00 ifname enc1c00 ip4 204.90.115.208/24 gw4 204.90.115.1
nmcli con modify enc1c00 ipv4.dns 8.8.8.8
nmcli con modify enc1c00 ipv4.dns-search dal-ebis.ihost.com
nmcli con modify enc1c00 ipv4.dns-search wave.log-on.com
systemctl restart NetworkManager
nmcli con show

