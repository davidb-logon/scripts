ip link delete dev cloudbr0
ip link delete dev br0
ip address add 204.90.115.208/24 dev enc1c00
ip link set dev enc1c00 up
#ip route delete default

# Get the default route line
default_route=$(ip route | grep default)

# Loop through each line of the default route
while read -r line; do
    # Delete the default route
    sudo ip route del $line
done <<< "$default_route"

ip route add default via 204.90.115.1 dev enc1c00
sleep 5
ip -br a
echo nameserver 8.8.8.8 >> /etc/resolv.conf
ping -c 1 cnn.com
brctl show
