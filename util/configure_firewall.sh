#!/bin/bash

# Check if at least one network is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <NETWORK> [<NETWORK>...]"
    echo "Example: $0 192.168.1.0/24 10.0.0.0/16"
    exit 1
fi

# Ports and protocols configuration
declare -A ports_protocols=(
    [111]="tcp udp"    # Portmapper
    [2049]="tcp"       # NFS
    [32803]="tcp"      # NFS mountd (for NFSv3)
    [32769]="udp"      # NFS mountd (for NFSv3)
    [892]="tcp udp"    # NFSd and mountd (for NFSv4)
    [875]="tcp udp"    # rquotad
    [662]="tcp udp"    # statd
)

# Enable UFW if not already enabled
sudo ufw status | grep -q inactive && sudo ufw enable

# Iterate over each provided network
for network in "$@"; do
    # Loop through ports and protocols to add rules for each network
    for port in "${!ports_protocols[@]}"; do
        for proto in ${ports_protocols[$port]}; do
            echo "Adding UFW rule for port $port over $proto from $network"
            # Insert rules at the top of the ruleset to ensure they precede any existing rules
            sudo ufw insert 1 allow from $network to any port $port proto $proto
        done
    done
done

echo "UFW configuration completed."
