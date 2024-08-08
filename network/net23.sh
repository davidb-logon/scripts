sudo ip link add eth0 type dummy
sudo ip addr add 192.168.122.1/24 dev eth0
sudo ip link set dev eth0 up
ip addr show eth0

exit

sudo ip add add 192.168.122.1/24 dev cloudbr0 brd 192.168.122.255 
#ip route add default via 204.90.115.1 dev cloudbr0
sudo ip link set eth0 up
ip -br a
#sudo nmcli connection del eth0
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
