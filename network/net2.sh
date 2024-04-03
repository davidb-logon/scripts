#ifconfig eth0 204.90.115.208 netmask 255.255.255.0  up
#ip route add default via 204.90.115.1 dev eth0 proto static metric 100      
#ip a
#ip route
#ip link add name br0 type bridge
#ip link set dev br0 up
#ip link set dev eth1 master br0
#ip addr add 192.168.122.1/24 dev br0
#ip a
nmcli con delete cloudbr0
nmcli con delete eth0
nmcli con add ifname cloudbr0 type bridge con-name cloudbr0
nmcli connection modify cloudbr0 ipv4.addresses '204.90.115.208/24' ipv4.gateway '204.90.115.1' ipv4.dns '8.8.8.8' ipv4.dns-search 'wave.log-on.com' ipv4.method manual ipv6.method disabled
nmcli connection add con-name eth0 ifname eth0 type ethernet 
nmcli con add type bridge-slave ifname eth0 master cloudbr0
nmcli connection show
#nmcli con down enc1c00
nmcli con up cloudbr0
nmcli con up eth0
#nmcli con up enc1c00
nmcli con show
nmcli device status

