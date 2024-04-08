#!/bin/bash
set -euo pipefail

# Name of the bridge
BRIDGE_NAME="cloudbr0"
# Name of the interface to be added as a slave to the bridge
SLAVE_INTERFACE="enc1c00"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Function to delete a connection if it exists
delete_connection() {
    local connection="$1"
    nmcli con delete "$connection" || true
}

# Delete the slave interface connection
delete_connection "$SLAVE_INTERFACE"

# Check if the bridge already exists and delete it if necessary
delete_connection "$BRIDGE_NAME"

# Create the bridge
nmcli con add type bridge ifname "$BRIDGE_NAME" con-name "$BRIDGE_NAME"

# Configure the bridge
nmcli connection modify "$BRIDGE_NAME" \
    ipv4.addresses '204.90.115.208/24' \
    ipv4.gateway '204.90.115.1' \
    ipv4.dns '8.8.8.8' \
    ipv4.dns-search 'wave.log-on.com' \
    ipv4.method manual \
    ipv6.method disabled

nmcli con modify "$BRIDGE_NAME" bridge.stp no
echo "Bridge $BRIDGE_NAME created."

# Add the slave interface to the bridge
nmcli con add type bridge-slave ifname "$SLAVE_INTERFACE" master "$BRIDGE_NAME" con-name "slave-$SLAVE_INTERFACE"
echo "Interface $SLAVE_INTERFACE added as a slave to $BRIDGE_NAME."

# Activate connections
nmcli con up "$SLAVE_INTERFACE"
nmcli con up "$BRIDGE_NAME"

echo "Configuration applied."

