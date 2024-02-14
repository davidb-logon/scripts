#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# See usage for what this script does.

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

script_ended_ok=false
trap 'cleanup' EXIT

usage() {
cat << EOF
-------------------------------------------------------------------------------
Configure ufw (Ubuntu's uncomplicated firewall) for Cloudstack NFS

Usage: $0 <NETWORK> [<NETWORK>...]
Example: $0 192.168.1.0/24 10.0.0.0/16

Following instructions at:
http://docs.cloudstack.apache.org/en/4.19.0.0/installguide/management-server/index.html#prepare-nfs-shares
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

parse_command_line_arguments() {
    # Check if at least one network is provided
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi
}

init_vars() {
    init_utils_vars $1 $2
    SUDO="sudo"
}

enable_ufw() {
    # Enable UFW if not already enabled
    sudo ufw status | grep -q inactive && sudo ufw enable
}

set_ufw_rules() {
    # Iterate over each provided network
    for network in "$@"; do
        logMessage "--- Adding ufw rules for network: $network"
        # Loop through ports and protocols to add rules for each network
        for port in "${!ports_protocols[@]}"; do
            for proto in ${ports_protocols[$port]}; do
                logMessage "--- Adding UFW rule for port $port over $proto from $network"
                # Insert rules at the top of the ruleset to ensure they precede any existing rules
                do_cmd "sudo ufw insert 1 allow from $network to any port $port proto $proto" "Rule added" "Rule not added"
            done
        done
    done
}

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

function update_idmapd_conf() {
    
    # Path to the idmapd.conf file
    local file_path="/etc/idmapd.conf"
    logMessage "--- Updating $file_path"

    # Check if the file exists
    if [[ -f "$file_path" ]]; then
        # Use sed to uncomment the line if it's commented
        do_cmd "sudo sed -i 's/^# Domain = localdomain/Domain = localdomain/' $file_path" "$file_path has been updated."
    else
        logMessage "The file $file_path does not exist."
    fi
}

main() {
    init_vars "logon" "configure_firewall"
    parse_command_line_arguments "$@"
    start_logging
    enable_ufw
    set_ufw_rules "$@"
    # Ensure rules are up-todate
    sudo ufw --force disable
    sudo ufw --force enable
    update_idmapd_conf
    script_ended_ok=true
}

main "$@"
