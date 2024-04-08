nmcli connection delete Example-Connection
nmcli connection add con-name Example-Connection ifname eth0 type ethernet
nmcli connection modify Example-Connection ipv4.addresses 204.90.115.208/24
nmcli connection modify Example-Connection ipv4.method manual
nmcli connection modify Example-Connection ipv4.gateway 204.90.115.254
nmcli connection modify Example-Connection ipv4.dns 8.8.8.8
nmcli connection modify Example-Connection ipv4.dns-search example.com
nmcli connection up Example-Connection
nmcli device status
nmcli connection reload

ip route delete default via 204.90.115.254 dev eth0 proto static metric 100 
ip route add default via 204.90.115.1 dev eth0 proto static metric 100      

