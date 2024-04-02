#!/bin/bash

# Function to delete existing connection if it exists
delete_connection_if_exists_on_rhel() {
    CON_NAME=$1
    EXISTS=$(nmcli con show "$CON_NAME" &> /dev/null; echo $?)
    if [ "$EXISTS" -eq 0 ]; then
        echo "Deleting existing connection: $CON_NAME"
        sudo nmcli con delete "$CON_NAME"
    fi
}

# Function to create bridge and slave connections
create_bridge_and_slave_connections() {
    BRIDGE_NAME=$1
    SLAVE_INTERFACES=("${@:2}")

    # Delete bridge connection if it exists
    delete_connection_if_exists_on_rhel "$BRIDGE_NAME"

    # Create bridge connection
    echo "Creating bridge connection: $BRIDGE_NAME"
    sudo nmcli connection add type bridge ifname "$BRIDGE_NAME" con-name "$BRIDGE_NAME" autoconnect yes

    # Attach slave interfaces to bridge
    for INTERFACE in "${SLAVE_INTERFACES[@]}"; do
        # Delete slave connection if it exists
        delete_connection_if_exists_on_rhel "$INTERFACE"

        # Create slave connection and attach to bridge
        echo "Creating slave connection: $INTERFACE"
        sudo nmcli connection add type bridge-slave ifname "$INTERFACE" master "$BRIDGE_NAME" con-name "$INTERFACE" autoconnect yes
    done
}
# Function to configure IP settings for bridge interface
configure_bridge_ip_settings() {
    BRIDGE_NAME=$1
    BRIDGE_IP=$2
    GATEWAY_IP=$3
    DNS_SERVERS=$4

    echo "Configuring IP settings for bridge: $BRIDGE_NAME"
    sudo nmcli connection modify "$BRIDGE_NAME" ipv4.addresses "$BRIDGE_IP" ipv4.gateway "$GATEWAY_IP" ipv4.dns "$DNS_SERVERS" ipv4.method manual

    # Bring up the bridge interface
    sudo nmcli connection up "$BRIDGE_NAME"
}


# Function to configure IP settings for slave interfaces
configure_slave_ip_settings() {
    SLAVE_INTERFACES=("${@:1}")
    echo "Configuring IP settings for slave interfaces: ${SLAVE_INTERFACES[@]}"
    for INTERFACE in "${SLAVE_INTERFACES[@]}"; do
        sudo nmcli connection modify "$INTERFACE" connection.autoconnect yes
    done
}

# Main function to set up network for CloudStack
setup_network_for_cloudstack() {
    BRIDGE_NAME="cloudbr0"
    SLAVE_INTERFACES=("enc1c00")  # Add your slave interface names here
    BRIDGE_IP="204.90.115.208/24"  # Change to your desired bridge IP address and subnet mask
    GATEWAY_IP="204.90.115.1"  # Change to your gateway IP address
    DNS_SERVERS="8.8.8.8,8.8.4.4"  # Change to your DNS server IP addresses

    create_bridge_and_slave_connections "$BRIDGE_NAME" "${SLAVE_INTERFACES[@]}"
    configure_bridge_ip_settings "$BRIDGE_NAME" "$BRIDGE_IP" "$GATEWAY_IP" "$DNS_SERVERS"
    configure_slave_ip_settings "${SLAVE_INTERFACES[@]}"
}

# Execute main function
setup_network_for_cloudstack

