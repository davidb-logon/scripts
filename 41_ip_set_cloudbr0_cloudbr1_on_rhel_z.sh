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

    cleanup
    define_main_nic
    create_and_configure_bridge
    attach_eth0_to_bridge
    add_routes
    configure_network_manager
    verify_configuration

    logMessage  "Script completed successfully."

    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}
set -x

cleanup() {
    logMessage  "Cleaning up existing configurations..."

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

create_and_configure_bridge() {
    logMessage "Creating and configuring the bridge..."

    # Create the bridge if it doesn't exist
    if ! ip link show cloudbr0 > /dev/null 2>&1; then
        logMessage  "Creating bridge cloudbr0..."
        do_cmd "ip link add name cloudbr0 type bridge"
    else
        logMessage  "Bridge cloudbr0 already exists."
    fi

    # Check if IP address is already assigned
    if ip addr show dev cloudbr0 | grep -q "192.168.122.1/24"; then
        logMessage  "IP address 192.168.122.1/24 already assigned to cloudbr0."
    else
        logMessage  "Adding IP address 192.168.122.1/24 to cloudbr0..."
        do_cmd "ip addr add 192.168.122.1/24 dev cloudbr0" "success" "INFO:failed:IP address not added"
    fi

    logMessage  "Bringing up cloudbr0..."
    do_cmd "ip link set cloudbr0 up"
}

attach_eth0_to_bridge() {
    logMessage  "Attaching eth0 to the bridge..."

    # Bring down eth0 if it is up
    do_cmd "ip link set eth0 down || true"

    # Attach eth0 to the bridge
    logMessage  "Attaching eth0 to cloudbr0..."
    do_cmd "ip link set eth0 master cloudbr0"

    # Bring eth0 back up
    logMessage  "Bringing up eth0..."
    do_cmd "ip link set eth0 up"
}

add_routes() {
    logMessage  "Adding routes..."

    # Add the default route
    do_cmd "ip route add default via 204.90.115.1 dev enc1c00"
}

configure_network_manager() {
    logMessage  "Configuring NetworkManager..."

    # Disable NetworkManager management for cloudbr0
    do_cmd "nmcli device set cloudbr0 managed no || true"
}

verify_configuration() {
    logMessage  "Verifying configuration..."

    # Display the status of interfaces
    logMessage  "Interface status:"
    do_cmd "ip -br link show cloudbr0 eth0"

    # Display the routing table
    logMessage  "Routing table:"
    do_cmd "ip route show"
}
define_main_nic(){
    do_cmd "ifconfig enc1c00 204.90.115.226 netmask 255.255.255.0  up"
    do_cmd "ip route add default via 204.90.115.1 dev enc1c00 proto static metric 100"
}

main "$@"
