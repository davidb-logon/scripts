set -x
# Create bridge
brctl addbr cloudbr0

# Add interface to bridge
brctl addif cloudbr0 enc1c00

# (Optional) Set interface UP (assuming it's already configured)
ip link set enc1c00 up

# (Optional) View bridge info
brctl show br0
ip -br a
exit

sudo modprobe tun tap
sudo ip link add cloudbr0 type bridge
sudo ip tuntap add dev tap0 mode tap
sudo ip link set dev enc1c00 master cloudbr0
sudo ip link set dev tap0 master cloudbr0
sudo ip link set dev cloudbr0 up
 
sudo ip address delete 204.90.115.208 dev enc1c00
sudo ip address add 204.90.115.208/24 dev cloudbr0
sudo ip route add default via 204.90.115.1 dev cloudbr0
sudo resolvectrl dns cloudbr0 8.8.8.8
ip -br a
