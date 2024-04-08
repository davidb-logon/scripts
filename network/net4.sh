set -x
#nmcli con delete enc1c00
nmcli con down enc1c00
nmcli con delete cloudbr0
nmcli con delete eth0
nmcli con add ifname cloudbr0 type bridge con-name cloudbr0 autoconnect yes
nmcli connection modify cloudbr0 ipv4.addresses '204.90.115.208/24' ipv4.gateway '204.90.115.1' ipv4.dns '8.8.8.8' ipv4.dns-search 'wave.log-on.com' ipv4.method manual ipv6.method disabled
nmcli connection add con-name eth0 ifname eth0 type ethernet 
nmcli con add type bridge-slave ifname eth0 master cloudbr0
nmcli connection show
#nmcli con down enc1c00
nmcli con up cloudbr0
nmcli con up eth0
nmcli con up enc1c00
nmcli con show
nmcli device status
