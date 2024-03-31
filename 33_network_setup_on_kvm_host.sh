#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

main() {
    start_time=$(date +%s)
    usage
    init_vars "logon" "network_setup"
    parse_command_line_arguments "$@"
    start_logging
    detect_linux_distribution
    setup_network

    # /etc/sysconfig/network-scripts/ifcfg-cloudbr0
    # DEVICE=cloudbr0
    # TYPE=Bridge
    # ONBOOT=yes
    # BOOTPROTO=static
    # IPV6INIT=no
    # IPV6_AUTOCONF=no
    # DELAY=5
    # IPADDR=172.16.10.2 #(or e.g. 192.168.1.2)
    # GATEWAY=172.16.10.1 #(or e.g. 192.168.1.1 - this would be your physical/home router)
    # NETMASK=255.255.255.0
    # DNS1=8.8.8.8
    # DNS2=8.8.4.4
    # STP=yes
    # USERCTL=no
    # NM_CONTROLLED=no

    # /etc/sysconfig/network-scripts/ifcfg-eth0
    # TYPE=Ethernet
    # BOOTPROTO=none
    # DEFROUTE=yes
    # NAME=eth0
    # DEVICE=eth0
    # ONBOOT=yes
    # BRIDGE=cloudbr0

    # systemctl disable NetworkManager; systemctl stop NetworkManager
    # systemctl enable network
    # reboot

    # /etc/hosts
    # 127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
    # ::1 localhost localhost.localdomain localhost6 localhost6.localdomain6
    # 172.16.10.2 srvr1.cloud.priv
    # systemctl restart network

    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    logMessage "The script took $elapsed_time seconds to complete."
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}

setup_network() {
  case "$LINUX_DISTRIBUTION" in
    "UBUNTU")
        logMessage "--- Ubuntu not supported yet..."
        exit 1
        ;;
    "RHEL")
        do_cmd "sudo yum -y upgrade"
        do_cmd "sudo yum install bridge-utils net-tools -y"
        setup_network_on_rhel
        # Add RHEL specific commands here
        ;;
    "Unknown")
      logMessage "--- Unknown Linux distribution, exiting"
      exit 1
      ;;    
    *)
      logMessage "Unsupported LINUX_DISTRIBUTION: $LINUX_DISTRIBUTION, exiting"
      exit 1
      ;;
  esac
}

# Function to delete existing connection if it exists
delete_connection_if_exists_on_rhel() {
    CON_NAME=$1
    EXISTS=$(nmcli con show "$CON_NAME" &> /dev/null; echo $?)
    if [ "$EXISTS" -eq 0 ]; then
        logMessage "Deleting existing connection: $CON_NAME"
        do_cmd "sudo nmcli con del $CON_NAME"
    fi
}

setup_network_on_rhel() {
    logMessage "--- Starting to define network configurations"
    # Define network configurations
    BRIDGE_NAME="cloudbr0"
    EXTERNAL_IP="204.90.115.208/24"  # Adjust the subnet mask as necessary
    GATEWAY_IP="204.90.115.1"  # Replace with your actual gateway IP
    DNS1="8.8.8.8"
    DNS2="8.8.4.4"
    INTERFACE_NAME="enc1c00"

    # Delete bridge and interface connections if they exist
    delete_connection_if_exists_on_rhel "$BRIDGE_NAME"
    delete_connection_if_exists_on_rhel "$INTERFACE_NAME"

    # Create the bridge interface

    do_cmd "sudo nmcli con add type bridge ifname $BRIDGE_NAME con-name $BRIDGE_NAME autoconnect yes"
                 


    # Assign the external IP to the bridge
    do_cmd "sudo nmcli con mod $BRIDGE_NAME ipv4.addresses $EXTERNAL_IP ipv4.gateway $GATEWAY_IP ipv4.method manual ipv6.method ignore bridge.stp yes"
    do_cmd "sudo nmcli con mod $BRIDGE_NAME ipv4.dns $DNS1,$DNS2"

    # Attach the interface to the bridge without an IP
    # do_cmd "sudo nmcli con add type bridge-slave ifname $INTERFACE_NAME con-name $INTERFACE_NAME master $BRIDGE_NAME autoconnect yes ipv4.method disabled ipv6.method ignore"
    # Attach the interface to the bridge without specifying ipv4 or ipv6 method
    do_cmd "sudo nmcli con add type ethernet con-name $INTERFACE_NAME"
    do_cmd "sudo nmcli con add type bridge-slave ifname $INTERFACE_NAME con-name $INTERFACE_NAME master $BRIDGE_NAME autoconnect yes"

    # Reload and reapply configurations
    do_cmd "sudo nmcli con reload" "Reload Network" "Unable to reload network"
    do_cmd "sudo nmcli con down $BRIDGE_NAME" "down $BRIDGE_NAME" 
    do_cmd "sudo nmcli con up $BRIDGE_NAME" "up $BRIDGE_NAME"
    do_cmd "sudo nmcli con down $INTERFACE_NAME" "down $INTERFACE_NAME"
    do_cmd "sudo nmcli con up $INTERFACE_NAME" "up $INTERFACE_NAME"

    do_cmd "sudo systemctl restart NetworkManager"

    logMessage "Network configuration has been updated. The bridge $BRIDGE_NAME now holds the external IP."
    logMessage "--- End definition of network configurations"
    logMessage "--- Doing: ip -br a"
    logMessage "$(ip -br a)"
    logMessage "------------------ Doing: nmcli con show cloudbr0"
    logMessage "$(nmcli con show cloudbr0)"
    logMessage "------------------ Doing: nmcli con show enc1c00"
    logMessage "$(nmcli con show enc1c00)"
    logMessage "------------------ Doing: ip route"
    logMessage "$(ip route)"
    logMessage "------------------ Doing: bridge link show"
    logMessage "$(bridge link show)"

    sleep 30
    ping -c 1 8.8.8.8
    if [[ $? = 1 ]]; then
        sudo /data/primary/net1.sh
    fi

    # default via 204.90.115.1 dev enc1c00 proto static metric 100 
    # default via 204.90.115.1 dev cloudbr0 proto static metric 425 linkdown
}


parse_command_line_arguments() {
    # if [[ $# -lt 1 || $# -gt 2 ]]; then
    #     usage
    #     exit
    # fi
    temp=1
}

usage() {
cat << EOF
-------------------------------------------------------------------------------
This script sets up cloudstack network bridge on red hat
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

#-------------------------------------------------------#
#                Start script execution                 #
#-------------------------------------------------------#

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

script_ended_ok=false
trap 'cleanup' EXIT

main "$@"
