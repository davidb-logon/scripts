#!/bin/bash
# Add cloudbr0 and eth0
/data/scripts/43_configure_network_without_nm.sh 
ifconfig enc1c00 204.90.115.226 netmask 255.255.255.0  up
ip route add default via 204.90.115.1 dev enc1c00 proto static metric 100    
echo -e 'nameserver 8.8.8.8\nnameserver 8.8.4.4' >> /etc/resolv.conf  
ip a
ip route


