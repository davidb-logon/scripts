# https://www.youtube.com/watch?v=6435eNKpyYw&t=70s
# first erase all network interfaces
#nmcli -c no c 
nmcli connection delete enc1c00
nmcli connection delete cloudbr0
systemctl stop NetworkManager
ip link set enc1c00 down
ip address del 204.90.115.208/24 dev enc1c00

# ok, now we are ready to start

ip link add name cloudbr0 type bridge
ip link set enc1c00 master cloudbr0
ip add add 204.90.115.208/24 dev cloudbr0 brd 204.90.115.255 
ip route add default via 204.90.115.1 dev cloudbr0
ip link set enc1c00 up
ip link set cloudbe0 up
