#ifcfg-enc1c00
znetconf -a 1c00
znetconf -c  #show the configured devices
#cp -f /home/sefi/network-scripts.good/ifcfg-enc1c00 /etc/sysconfig/network-scripts/ifcfg-enc1c00
#ifup enc1c00
ifdown cloudbr0
ifdown eth0
cp -f /home/sefi/network-scripts.good/ifcfg-cloudbr0 /etc/sysconfig/network-scripts/ifcfg-cloudbr0
cp -f /home/sefi/network-scripts.good/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0
ifup cloudbr0
ifup eth0

