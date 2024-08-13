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
