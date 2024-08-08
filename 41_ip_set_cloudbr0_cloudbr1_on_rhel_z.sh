#!/bin/bash
set +x
sudo ip link set eth0 down || true
sudo ip link set cloudbr0 down || true
sudo ip link delete cloudbr0 || true

# Clean up routes if needed
sudo ip route flush dev cloudbr0 || true
sudo ip route flush dev eth0 || true
# Ensure interfaces are down before making changes
sudo ip link set eth0 down || true
sudo ip link set cloudbr0 down || true

# Delete existing bridge if it exists
sudo ip link delete cloudbr0 || true

# Create the bridge
sudo ip link add name cloudbr0 type bridge

# Configure the IP address and bring up the bridge
sudo ip addr add 192.168.122.1/24 dev cloudbr0
sudo ip link set cloudbr0 up

# Attach eth0 to the bridge
sudo ip link set eth0 master cloudbr0
sudo ip link set eth0 up

# Add routes (make sure the routes are correct and the device is up)
sudo ip route add default via 204.90.115.1 dev enc1c00 || true
sudo ip route add 0.0.0.0/1 via 192.168.122.1 dev cloudbr0 || true
sudo ip route add 128.0.0.0/1 via 192.168.122.1 dev cloudbr0 || true

# Disable NetworkManager management for cloudbr0 to avoid conflicts
sudo nmcli device set cloudbr0 managed no

# Check status of the interfaces
ip -br link show cloudbr0 eth0


exit
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
    
    ip -br link show
    ip -br addr show
    
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}

remove_existing_connections() {
    logMessage "Removing existing network connections if they exist."

    do_cmd "ip link set eth0 down || true"
    do_cmd "ip link set cloudbr0 down || true"
    do_cmd "ip link delete eth0 || true"
    do_cmd "ip link delete cloudbr0 || true"
    do_cmd "ip link delete cloud0 || true"
    do_cmd "ip link delete cloudbr1 || true"
    do_cmd "ip link delete eth0.200 || true"
    do_cmd "rm -f /etc/sysconfig/network-scripts/ifcfg-cloudbr0*"
    do_cmd "rm -f /etc/sysconfig/network-scripts/route-cloudbr0*"
}

create_eth0() {
    logMessage "Creating eth0 interface."
    do_cmd "ip link add name eth0 type dummy"
    do_cmd "ip link set dev eth0 up"
}

create_cloudbr0() {
    logMessage "Creating cloudbr0 bridge."
    do_cmd "ip link add name cloudbr0 type bridge"
    do_cmd "ip addr add 192.168.122.1/24 dev cloudbr0"
    do_cmd "ip link set dev cloudbr0 up"
    do_cmd "ip route add default via 204.90.115.1 dev cloudbr0"
}

attach_eth0_to_cloudbr0() {
    logMessage "Attaching eth0 to cloudbr0."
    do_cmd "ip link set dev eth0 master cloudbr0"
    do_cmd "ip link set dev eth0 up"
}

main "$@"
