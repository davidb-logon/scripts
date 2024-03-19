#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

main() {
    start_time=$(date +%s)
    usage
    init_vars "logon" "deploy_basic_Z_env"
    parse_command_line_arguments "$@"
    start_logging
    check_if_ubuntu_deploy_completed # Creates globals needed for the rest:
                                     # ZONE_ID
    delete_all_mainframe_objects
    create_physical_network "$ZONE_ID"
    add_traffic_type "$PHY_ID" "Guest" 
    add_traffic_type "$PHY_ID" "Management" 
    enable_physical_network "$PHY_ID"
    enable_virtual_router_element "$PHY_ID"
    create_network "$ZONE_ID" # Creates global $NETWORK_ID
    create_pod "$ZONE_ID" "ubuntu_pod" # Creates global $POD_ID
    create_vlan_ip_range "$POD_ID" "$NETWORK_ID"
    create_cluster "$ZONE_ID" "$POD_ID" "ubuntu_cluster"
    add_host "$UBUNTU_IP" "$UBUNTU_USER" "$UBUNTU_PASSWORD" "$ZONE_ID" "$POD_ID" "$CLUSTER_ID"
    
    add_primary_storage "$ZONE_ID" "$POD_ID" "$CLUSTER_ID" "ubuntu_primary" 
    add_secondary_storage "$ZONE_ID" "ubuntu_secondary"

    enable_zone "$ZONE_ID"
    
    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    logMessage "The script took $elapsed_time seconds to complete."




    # Insert script logic here
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}

parse_command_line_arguments() {
    # if [[ $# -lt 1 || $# -gt 2 ]]; then
    #     usage
    #     exit
    # fi
    temp=1
}

usage() {
cat << EOF
-------------------------------------------------------------------------------
This script deploys a meinframe kvm host into the zone created by
script 23.
It first deletes everything it previouslu created on the mainframe.
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

#-------------------------------------------------------#
#                Start script execution                 #
#-------------------------------------------------------#

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

script_ended_ok=false
trap 'cleanup' EXIT

main "$@"
