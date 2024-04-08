nmcli connection modify enc1c00 -ipv4.method disabled
nmcli dev show enc1c00 | grep 'BRIDGE'
nmcli connection modify cloudbr0 +bridge.stp yes +connection.interface-name enc1c00
nmcli connection up enc1c00
nmcli connection up cloudbr0

