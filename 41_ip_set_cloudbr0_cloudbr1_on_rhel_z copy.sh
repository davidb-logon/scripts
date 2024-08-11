#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -x

cleanup() {
    echo "Cleaning up existing configurations..."

    # Remove conflicting routes
    ip route del default via 192.168.122.1 dev cloudbr0 || true
    ip route del default via 204.90.115.1 dev cloudbr0 || true
    ip route del default via 204.90.115.1 dev enc1c00 || true
    ip route del 0.0.0.0/1 via 204.90.115.1 dev enc1c00 || true
    ip route del 128.0.0.0/1 via 204.90.115.1 dev enc1c00 || true
    ip route show
    
    # Remove IP addresses and routes
    ip addr flush dev eth0 || true
    ip addr flush dev cloudbr0 || true
    ip route flush dev cloudbr0 || true

    # Bring down and delete existing bridge
    ip link set cloudbr0 down || true
    ip link delete cloudbr0 || true
}

create_and_configure_bridge() {
    echo "Creating and configuring the bridge..."

    # Create the bridge if it doesn't exist
    if ! ip link show cloudbr0 > /dev/null 2>&1; then
        echo "Creating bridge cloudbr0..."
        ip link add name cloudbr0 type bridge
    else
        echo "Bridge cloudbr0 already exists."
    fi

    # Check if IP address is already assigned
    if ip addr show dev cloudbr0 | grep -q "192.168.122.1/24"; then
        echo "IP address 192.168.122.1/24 already assigned to cloudbr0."
    else
        echo "Adding IP address 192.168.122.1/24 to cloudbr0..."
        ip addr add 192.168.122.1/24 dev cloudbr0
    fi

    echo "Bringing up cloudbr0..."
    ip link set cloudbr0 up
}

attach_eth0_to_bridge() {
    echo "Attaching eth0 to the bridge..."

    # Bring down eth0 if it is up
    ip link set eth0 down || true

    # Attach eth0 to the bridge
    echo "Attaching eth0 to cloudbr0..."
    ip link set eth0 master cloudbr0

    # Bring eth0 back up
    echo "Bringing up eth0..."
    ip link set eth0 up
}

add_routes() {
    echo "Adding routes..."

    # Add the default route
    ip route add default via 204.90.115.1 dev enc1c00
}

configure_network_manager() {
    echo "Configuring NetworkManager..."

    # Disable NetworkManager management for cloudbr0
    nmcli device set cloudbr0 managed no || true
}

verify_configuration() {
    echo "Verifying configuration..."

    # Display the status of interfaces
    echo "Interface status:"
    ip -br link show cloudbr0 eth0

    # Display the routing table
    echo "Routing table:"
    ip route show
}

main() {
    cleanup
    create_and_configure_bridge
    attach_eth0_to_bridge
    add_routes
    configure_network_manager
    verify_configuration

    echo "Script completed successfully."
}

main "$@"


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
