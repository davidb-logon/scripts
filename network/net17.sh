set -x
nmcli con show
#I renamed "Wired Connection 1' to the name of my physical interface:

#$ sudo nmcli con mod 'Wired Connection 1' con-name eth0

#So let's start out by creating the bridge itself:
nmcli con add ifname br0 type bridge con-name cloudbr0

#Now add the physical interface as its slave:
nmcli con add type bridge-slave ifname enc1c00 master cloudbr0

# Disable STP:
nmcli con mod cloudbr0 bridge.stp no
 
# Now down the physical interface:
nmcli con down enc1c00
 
#For this machine I want a static address:
nmcli con mod cloudbr0 ipv4.addresses 204.90.115.208/24
nmcli con mod cloudbr0 ipv4.gateway 204.90.115.1
nmcli con mod cloudbr0 ipv4.dns '8.8.8.8,8.8.4.4'

#Don't forget to set your search domain:
nmcli con mod cloudbr0 ipv4.dns-search 'log-on.com'
 
#Finally tell Network Manager this will be a manual connection:
nmcli con mod cloudbr0 ipv4.method manual

nmcli con upi enc1c00
#Finally, bring up the new bridge interface:
nmcli con up cloudbr0
nmcli con show
