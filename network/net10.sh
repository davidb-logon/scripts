nmcli con delete enc1c00
nmcli con delete cloudbr0
nmcli con add ifname cloudbr0 type bridge con-name cloudbr0 autoconnect yes
nmcli connection add con-name  enc1c00 ifname enc1c00 type ethernet
nmcli con add type bridge-slave ifname enc1c00 master cloudbr0 autoconnect yes con-name br-enc1c00
nmcli connection modify cloudbr0 ipv4.addresses '204.90.115.208/24' ipv4.gateway '204.90.115.1' ipv4.dns '8.8.8.8' ipv4.dns-search 'wave.log-on.com' ipv4.method manual ipv6.method disabled
nmcli connection up cloudbr0
ip -br -c a
