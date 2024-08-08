nmcli connection show
nmcli con delete cloudbr0
sudo nmcli connection add type bridge autoconnect yes con-name cloudbr0 ifname cloudbr0
sudo nmcli connection modify cloudbr0 ipv4.addresses 192.168.122.1/24 gw4 192.168.122.1 ipv4.method manual
sudo nmcli connection modify cloudbr0 ipv4.dns 8.8.8.8 ipv4.dns-search 'wave.log-on.com' ipv6.method disabled
sudo nmcli connection del eth0
sudo nmcli connection add type bridge-slave autoconnect yes con-name eth0 ifname eth0 master cloudbr0
sudo nmcli connection up cloudbr0
nmcli con show
nmcli device status
