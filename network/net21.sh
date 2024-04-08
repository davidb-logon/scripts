#!/bin/bash
# 8. Configure a Network Bridge
# All the virtual machines on the host are by default connected to the same NAT-type virtual network, named 'default'.
seft -x
 sudo virsh net-list --all
#  Name      State    Autostart   Persistent
# --------------------------------------------
#  default   active   yes         yes
# Note: If you use Debian, the default network state will be inactive, and autostart will be disabled. To activate, run the command sudo virsh net-start default followed by sudo virsh net-autostart default.
# The virtual machines that use this 'default' network will be assigned an IP address in the 192.168.124.0/24 address space, with the host OS reachable at 192.168.124.1.

 sudo virsh net-dumpxml default | xmllint --xpath '//ip' -
# <ip address="192.168.124.1" netmask="255.255.255.0">
#     <dhcp>
#       <range start="192.168.124.2" end="192.168.124.254"/>
#     </dhcp>
# </ip>
# Virtual machines using this default network will only have outbound network access. Virtual machines will have full access to network services, but devices outside the host will be unable to communicate with virtual machines inside the host. For example, the virtual machine can browse the web but cannot host a web server that is accessible to the outside world.

# If you want virtual machines to be directly visible on the same physical network as the host and visible to external devices, you must use a network bridge.

# A network bridge is a link-layer device that connects two local area networks into one network. In this case, a software bridge is used within a Linux host to simulate a hardware bridge. As a result, all other physical machines on the same physical network of the host can detect and access virtual machines. The virtual machine, for example, can browse the web, and will also be able to host a web server that is accessible to the outside world.
# Important:

# Unfortunately, you cannot set up a network bridge when using Wi-Fi.

# Due to the IEEE 802.11 standard which specifies the use of 3-address frames in Wi-Fi for the efficient use of airtime, you cannot configure a bridge over Wi-Fi networks operating in Ad-Hoc or Infrastructure modes.
# Source: Configuring a network bridge
# First, find the name of the interface you want to add to the bridge. In my case, it is enp2s0.

 sudo nmcli device status
# DEVICE             TYPE      STATE                   CONNECTION         
# enp2s0             ethernet  connected               Wired connection 1 
# lo                 loopback  connected (externally)  lo                 
# virbr0             bridge    connected (externally)  virbr0
# Create a bridge interface. I'll name it bridge0, but you can call it whatever you want.

 sudo nmcli connection add type bridge con-name bridge0 ifname bridge0
# Assign the interface to the bridge. I'm going to name this connection 'Bridge connection 1', but you can call it whatever you want.

 sudo nmcli connection add type ethernet slave-type bridge \
    con-name 'Bridge connection 1' ifname enp2s0 master bridge0
# The following step is optional. If you want to configure a static IP address, use the following commands; otherwise, skip this step. Change the IP address and other details to match your configuration.

sudo nmcli connection modify bridge0 ipv4.addresses '204.90.115.239/24'
sudo nmcli connection modify bridge0 ipv4.gateway '204.90.115.1'
sudo nmcli connection modify bridge0 ipv4.dns '8.8.8.8,8.8.4.4'
sudo nmcli connection modify bridge0 ipv4.dns-search 'sysguides.com'
sudo nmcli connection modify bridge0 ipv4.method manual
# Activate the connection.

 sudo nmcli connection up bridge0
# Enable the connection.autoconnect-slaves parameter of the bridge connection.

sudo nmcli connection modify bridge0 connection.autoconnect-slaves 1
# Reactivate the bridge.

 sudo nmcli connection up bridge0
# Verify the connection. If you get your IP address from DHCP, it may take a few seconds to lease a new one. So please be patient.
sudo nmcli device status
# DEVICE             TYPE      STATE                   CONNECTION          
# bridge0            bridge    connected               bridge0             
# lo                 loopback  connected (externally)  lo                  
# virbr0             bridge    connected (externally)  virbr0              
# enp2s0             ethernet  connected               Bridge connection 1

 ip -brief addr show dev bridge0
cat << EOF > nwbridge.xml
<network>
  <name>nwbridge</name>
  <forward mode='bridge'/>
  <bridge name='bridge0'/>
</network>
EOF

# Define nwbridge as a persistent virtual network.

sudo virsh net-define nwbridge.xml
# Activate the nwbridge and set it to autostart on boot.

 sudo virsh net-start nwbridge
 sudo virsh net-autostart nwbridge
# Now you can safely delete the nwbridge.xml file. It’s not required anymore.

 rm nwbridge.xml
# Finally, verify that the virtual network bridge nwbridge is up and running.

 sudo virsh net-list --all
#  Name       State    Autostart   Persistent
# ---------------------------------------------
#  default    active   yes         yes
#  nwbridge   active   yes         yes
# A network bridge has been created. You can now start using the nwbridge network bridge in your virtual machines. The virtual machines will get their IP addresses from the same pool as your host machine.
# If you ever want to remove this network bridge and return it to its previous state, then run the following commands.

# $ sudo virsh net-destroy nwbridge
# $ sudo virsh net-undefine nwbridge

# $ sudo nmcli connection up 'Wired connection 1'
# $ sudo nmcli connection down bridge0
# $ sudo nmcli connection del bridge0
# $ sudo nmcli connection del 'Bridge connection 1'
