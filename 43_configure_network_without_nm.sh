#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# See usage for what this script does.
# TODOs:

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

script_ended_ok=false
trap 'cleanup' EXIT

usage() {
cat << EOF
-------------------------------------------------------------------------------
Configure the netwwork with Network Manager
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

main() {
    init_vars "logon" "configure_network_wo_NM"
    start_logging
    check_if_root
    disable_network_manager
    cleanup
    remove_existing_connections
    create_eth0
    
    script_ended_ok=true
}

disable_network_manager(){
    do_cmd "systemctl stop NetworkManager"
    do_cmd "systemctl disable NetworkManager"
}

cleanup() {
    echo "Cleaning up existing configurations..."

    # Remove conflicting routes
    do_cmd "ip route del default via 192.168.122.1 dev cloudbr0 || true"
    do_cmd "ip route del default via 204.90.115.1 dev cloudbr0 || true"
    do_cmd "ip route del default via 204.90.115.1 dev enc1c00 || true"
    do_cmd "ip route del 0.0.0.0/1 via 204.90.115.1 dev enc1c00 || true"
    do_cmd "ip route del 128.0.0.0/1 via 204.90.115.1 dev enc1c00 || true"
    do_cmd "ip route show"
    
    # Remove IP addresses and routes
    do_cmd "ip addr flush dev eth0 || true"
    do_cmd "ip addr flush dev cloudbr0 || true"
    do_cmd "ip route flush dev cloudbr0 || true"

    # Bring down and delete existing bridge
    do_cmd "ip link set cloudbr0 down || true"
    do_cmd "ip link delete cloudbr0 || true"
}

remove_existing_connections() {
    logMessage "Removing existing network connections if they exist."

    do_cmd "ip link delete eth0 || true"
    do_cmd "ip link delete cloudbr0 || true"
    do_cmd "ip link delete cloud0 || true"
    do_cmd "ip link delete cloudbr1 || true"
    do_cmd "ip link delete eth0.200 || true"
    do_cmd "rm -f /etc/sysconfig/network-scripts/ifcfg-cloudbr0*"
    do_cmd "rm -f /etc/sysconfig/network-scripts/route-cloudbr0*"

}

create_eth0() {
    do_cmd "ip link add eth0 type dummy"
}

create_cloudbr0() {
    do_cmd "nmcli connection add type bridge con-name cloudbr0 ifname cloudbr0"
    do_cmd "nmcli connection modify cloudbr0 ipv4.method manual ipv4.addresses 192.168.122.1/24 ipv4.gateway 192.168.122.1"
    do_cmd "nmcli connection modify cloudbr0 ipv6.method ignore"
    do_cmd "nmcli connection modify cloudbr0 bridge.stp yes"
    do_cmd "nmcli connection modify cloudbr0 ipv4.dns 8.8.8.8 ipv4.dns-search 'wave.log-on.com' ipv6.method disabled"
    nmcli connection modify cloudbr0 ipv4.routes "0.0.0.0/0 204.90.115.1"
}

# create_cloudbr1() {
#     do_cmd "nmcli connection add type bridge con-name cloudbr1 ifname cloudbr1"
#     do_cmd "nmcli connection modify cloudbr1 ipv4.method disabled"
#     do_cmd "nmcli connection modify cloudbr1 ipv6.method ignore"
#     do_cmd "nmcli connection modify cloudbr1 bridge.stp yes"
#     do_cmd "nmcli connection up cloudbr1"
# }

# create_vlan_eth0_200() {
#     do_cmd "nmcli connection add type vlan con-name eth0.200 dev eth0 id 200"
#     do_cmd "nmcli connection modify eth0.200 connection.slave-type bridge connection.master cloudbr1"
#     do_cmd "nmcli connection up eth0.200"
# }

attach_eth0_to_cloudbr0() {
    do_cmd "nmcli connection modify eth0 connection.slave-type bridge connection.master cloudbr0"
    do_cmd "nmcli connection up cloudbr0"
    do_cmd "nmcli connection up eth0"
}

main "$@"
