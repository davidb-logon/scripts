set -x

# Delete existing connections if they exist
sudo nmcli connection delete eth0
sudo nmcli connection delete cloudbr0

# Create the bridge (cloudbr0)
sudo nmcli connection add type bridge autoconnect yes con-name cloudbr0 ifname cloudbr0

# Configure the bridge IP settings
sudo nmcli connection modify cloudbr0 ipv4.addresses 192.168.122.1/24
sudo nmcli connection modify cloudbr0 ipv4.gateway 192.168.122.1
sudo nmcli connection modify cloudbr0 ipv4.method manual
sudo nmcli connection modify cloudbr0 ipv6.method ignore
sudo nmcli connection modify cloudbr0 bridge.stp yes
sudo nmcli connection modify cloudbr0 bridge.forward-delay 5

# Create the bridge slave (eth0) and link it to the bridge
sudo nmcli connection add type bridge-slave autoconnect yes con-name eth0 ifname eth0 master cloudbr0

# Bring up the bridge and its slave
sudo nmcli connection up cloudbr0
sudo nmcli connection up eth0
# Explanation:
# Deleting Existing Connections:
# The first two commands ensure that any existing configurations for eth0 and cloudbr0 are removed to avoid conflicts.

# Creating the Bridge (cloudbr0):
# The nmcli connection add command creates a new bridge connection named cloudbr0.

# Configuring Bridge IP Settings:
# The nmcli connection modify commands configure the IP address, gateway, and other network parameters for cloudbr0.

# Creating and Linking the Bridge Slave (eth0):
# The next command creates the eth0 interface as a bridge slave and associates it with cloudbr0.

# Bringing Up the Connections:
# The final commands bring up the bridge and its slave interface.
ip -br a
exit











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
