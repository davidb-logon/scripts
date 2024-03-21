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
If you do not provide ant parameters, defaults will be used:
    HOME_NETWORK="192.168.1.0/24"
    SEFI_NETWORK="80.178.85.20"
    MAINFRAME_NETWORK="204.90.115.208" 

Following instructions at:
http://docs.cloudstack.apache.org/en/4.19.0.0/installguide/management-server/index.html#prepare-nfs-shares
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
    HOME_NETWORK="192.168.1.0/24"
}

enable_ufw() {
    # Enable UFW if not already enabled
    sudo ufw status | grep -q inactive && sudo ufw enable
}

reset_ufw_rules() {
    do_cmd "sudo ufw reset"
}


# Ports and protocols configuration
declare -A ports_protocols=(
    [53]="tcp udp"     # DNS
    [111]="tcp udp"    # Portmapper
    [2049]="tcp"       # NFS
    [1194]="udp"       # VPN
    [32803]="tcp"      # NFS mountd (for NFSv3)
    [32769]="udp"      # NFS mountd (for NFSv3)
    [892]="tcp udp"    # NFSd and mountd (for NFSv4)
    [875]="tcp udp"    # rquotad
    [662]="tcp udp"    # statd
    [22]="tcp"         # ssh
    [3020]="tcp"       # ssh
    [5050]="tcp"       # Cloudstack
    [8080]="tcp"
    [8090]="tcp"
    [8000]="tcp"       # Java remote debug for CS management
    [8001]="tcp"       # Java remote debug for CS agent on ubuntu
    [8002]="tcp"       # Java remote debug for CS agent on mainframe
    [8250]="tcp"
    [1798]="tcp"
    [3306]="tcp"
    [5900:6100]="tcp"
    [16509]="tcp"
    [16514]="tcp"
    [49152:49216]="tcp"
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

set_ufw_rules() {
    for network in "$@"; do
        logMessage "--- Adding ufw rules for network: $network"
         # Loop through ports and protocols to add rules for each network
        for port in "${!ports_protocols[@]}"; do
            for proto in ${ports_protocols[$port]}; do
                logMessage "--- Adding UFW rule for port $port over $proto from $network"
                # Insert rules at the top of the ruleset to ensure they precede any existing rules
                #do_cmd "sudo ufw insert 1 allow from $network to any port $port proto $proto" "Rule added" "Rule not added"
                do_cmd "sudo ufw allow from $network to any port $port proto $proto" "Rule added" "Rule not added"
            done
        done
    done
}

enable_ip_forwarding() {
    logMessage "--- Enabling IP forwarding and seeting default forwarding policy"
    # Update /etc/ufw/sysctl.conf for net.ipv4.ip_forward
    if grep -qE "^#?net.ipv4.ip_forward=1" /etc/ufw/sysctl.conf; then
        if grep -qE "^#net.ipv4.ip_forward=1" /etc/ufw/sysctl.conf; then
            sudo sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/ufw/sysctl.conf
            logMessage "--- Uncommented 'net.ipv4.ip_forward=1' in /etc/ufw/sysctl.conf."
        else
            logMessage "--- 'net.ipv4.ip_forward=1' is already set in /etc/ufw/sysctl.conf."
        fi
    else
        echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/ufw/sysctl.conf > /dev/null
        logMessage "Added 'net.ipv4.ip_forward=1' to /etc/ufw/sysctl.conf."
    fi

    # Update /etc/default/ufw for DEFAULT_FORWARD_POLICY
    if grep -qE "^DEFAULT_FORWARD_POLICY=\"ACCEPT\"" /etc/default/ufw; then
        logMessage "--- 'DEFAULT_FORWARD_POLICY=\"ACCEPT\"' is already set in /etc/default/ufw."
    else
        if grep -qE "^DEFAULT_FORWARD_POLICY=" /etc/default/ufw; then
            sudo sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
            logMessage "Updated 'DEFAULT_FORWARD_POLICY' to 'ACCEPT' in /etc/default/ufw."
        else
            echo 'DEFAULT_FORWARD_POLICY="ACCEPT"' | sudo tee -a /etc/default/ufw > /dev/null
            logMessage "--- Added 'DEFAULT_FORWARD_POLICY=\"ACCEPT\"' to /etc/default/ufw."
        fi
    fi
}

main() {
    init_vars "logon" "configure_firewall"

    if [ $# -eq 0 ]; then
        SEFI_NETWORK="80.178.85.20"
        MAINFRAME_NETWORK="204.90.115.208"
        VPN_NETWORK="10.8.0.0/24"
        set -- "$SEFI_NETWORK" "$MAINFRAME_NETWORK" "$VPN_NETWORK"
    fi

    start_logging
    enable_ufw
    reset_ufw_rules
    do_cmd "sudo ufw allow from $HOME_NETWORK"
    set_ufw_rules "$@"
    enable_ip_forwarding
    # Ensure rules are up-todate
    sudo ufw --force disable
    sudo ufw --force enable
    update_idmapd_conf
    script_ended_ok=true
}

main "$@"
