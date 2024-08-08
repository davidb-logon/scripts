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
Setup networking on KVM host on RHEL 8.6 on Z, following instructions at:
https://docs.cloudstack.apache.org/en/4.19.1.0/installguide/hypervisor/kvm.html#configuring-the-networking

-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

main() {
    init_vars "logon" "set_cloudbr0_on_rhel_z"
    start_logging
    check_if_root

    remove_existing_connections
    create_eth0
    create_cloudbr0
    attach_eth0_to_cloudbr0
    # create_cloudbr1
    # create_vlan_eth0_200
    

    nmcli connection show
    journalctl -u NetworkManager
    
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}

remove_existing_connections() {
    logMessage "Removing existing network connections if they exist."

    do_cmd "nmcli connection delete eth0 || true"
    do_cmd "nmcli connection delete cloudbr0 || true"
    do_cmd "nmcli connection delete cloud0 || true"
    do_cmd "nmcli connection delete cloudbr1 || true"
    do_cmd "nmcli connection delete eth0.200 || true"
    do_cmd "nmcli device delete eth0 || true"
    do_cmd "nmcli device delete cloudbr0 || true"
    do_cmd "nmcli device delete cloud0 || true"
    do_cmd "nmcli device delete cloudbr1 || true"
    do_cmd "nmcli device delete eth0.200 || true"
    do_cmd "ip link delete eth0 || true"
    do_cmd "ip link delete cloudbr0 || true"
    do_cmd "ip link delete cloud0 || true"
    do_cmd "ip link delete cloudbr1 || true"
    do_cmd "ip link delete eth0.200 || true"
}

create_eth0() {
    do_cmd "nmcli connection add type ethernet con-name eth0 ifname eth0 autoconnect yes"
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
