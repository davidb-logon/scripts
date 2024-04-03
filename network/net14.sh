sudo ip addr add 204.90.115.208/24 dev enc1c00
sudo ip link set dev enc1c00 down
sudo ip link set dev enc1c00 name eth0



#sudo ip link add type ethernet dev  eth0 204.90.115.208 netmask 255.255.255.0  up
sudo ip route add default via 204.90.115.1 dev eth0 proto static metric 100      
sudo ip route
sudo ip link add name cloudbr0 type bridge
sudo ip link set dev cloudbr0 up
sudo ip link set dev eth1 master cloudebr0
sudo ip addr add 192.168.122.1/24 dev cloudbr0
sudo ip -br a

