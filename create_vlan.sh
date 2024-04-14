

NIC="enc1c00"
BRIDGE="cloudbr0"
VLAN="vlan10"
VPN_INTERFACE="tun0"

# Clean up
nmcli con del $BRIDGE
nmcli con del $VLAN


# sudo ip address delete 204.90.115.208 dev enc1c00
# sudo ip address add 204.90.115.208/24 dev cloudbr0
# sudo ip route add default via 204.90.115.1 dev cloudbr0
# sudo resolvectrl dns cloudbr0 8.8.8.8

nmcli c mod $VPN_INTERFACE -ipv4.addresses '10.7.0.1/24'
nmcli c down $VPN_INTERFACE

nmcli c add type bridge con-name "$BRIDGE" ifname "$BRIDGE"

nmcli c mod $BRIDGE ipv4.addresses '10.7.0.1/24'
nmcli c mod $BRIDGE ipv4.gateway '204.90.115.1'
nmcli c mod $BRIDGE ipv4.dns '8.8.8.8,8.8.4.4'
nmcli c mod $BRIDGE ipv4.dns-search 'sysguides.com'
nmcli c mod $BRIDGE ipv4.method manual
nmcli c mod $BRIDGE connection.autoconnect-slaves 1

nmcli con add type vlan con-name $VLAN dev $NIC id 10 ip4 192.168.10.2/24 gw4 204.90.115.1
nmcli con mod $VLAN master $BRIDGE
nmcli con up $VLAN
nmcli con up $BRIDGE
ip route
