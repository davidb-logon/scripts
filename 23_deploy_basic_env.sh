#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

main() {
    usage
    init_vars "logon" "deploy_basic_cs_env"
    start_logging
    delete_all_physicalnetworks
    delete_all_zones
    create_zone
    echo "Zone: $ZONE_ID created."
    create_physical_network "$ZONE_ID"
    echo "Physical Network: $PHY_ID created."
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
    IP_PREFIX="192.168.1"
    IP_UBUNTU="192.168.1.248"
    IP_EXTERNAL_DNS="8.8.8.8"
    IP_HOME_DNS="192.168.1.1"
    IP_HOME_GATEWAY="192.168.1.1"
    NETMASK="255.255.255.0"
    HYPERVISOR="KVM"
    POD_START_IP="${IP_PREFIX}.160"
    POD_END_IP="${IP_PREFIX}.169"
    VLAN_START_IP="${IP_PREFIX}.170"
    VLAN_END_IP="${IP_PREFIX}.179"
}

delete_all_zones() {
    zone_ids=$(cmk list zones | grep "id =" | awk '{print $3}')
    if [[ "$zone_ids" =~ ^[[:space:]]*$ ]]; then
        logMessage "--- No zones found to delete."
        return
    fi
    confirm "--- Delete existing zones: ${zone_ids} ?" || exit 1

    # Loop through each zone ID and delete the zone
    counter=0
    for id in $zone_ids; do
        do_cmd "cmk delete zone id=${id}" "Zone ${id} deleted." "Failed to delete zone ${id}"
    done
}

delete_all_physicalnetworks() {
    phy_ids=$(cmk list physicalnetworks | grep "^id =" | awk '{print $3}')
    if [[ "$phy_ids" =~ ^[[:space:]]*$ ]]; then
        logMessage "--- No physicalnetworks found to delete."
        return
    fi
    confirm "--- Delete existing physicalnetworks: ${phy_ids} ?" || exit 1

    # Loop through each physicalnetwork ID and delete the physicalnetwork
    counter=0
    for id in $phy_ids; do
        do_cmd "cmk delete physicalnetwork id=${id}" "physicalnetwork ${id} deleted." "Failed to delete physicalnetwork ${id}"
    done
}

# Returns the created zone id in the global variable ZONE_ID
create_zone() {
    #cmd="cmk create zone dns1=$IP_EXTERNAL_DNS internaldns1=$IP_HOME_DNS name=ubuntu_zone1 networktype=Basic"
    do_cmd 'result=$(cmk create zone dns1=8.8.8.8 internaldns1=192.168.1.1 name=ubuntu_zone1 networktype=Basic)' "Zone created." "Zone creation failed."
    ZONE_ID=$(echo $result | sed 's/zone = //g' | jq -r '.id')
}

create_physical_network() {
  local zone_id=$1
  do_cmd 'result=$(cmk create physicalnetwork name=phy-network zoneid='$zone_id')' "Network created." "Network creation failed."
  PHY_ID=$(echo $result | sed 's/physicalnetwork = //g' | jq -r '.id')
}

usage() {
cat << EOF
-------------------------------------------------------------------------------
This script creates a basic environment in cloudstack using cloudmonkey (cmk)
It will remove existing definitions of zones, pods, clusters, 
networks, and hosts.
-------------------------------------------------------------------------------
EOF
#script_ended_ok=true
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
