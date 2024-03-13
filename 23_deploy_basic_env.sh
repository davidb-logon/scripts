#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

main() {
    usage
    init_vars "logon" "deploy_basic_cs_env"
    start_logging
    delete_everything
    create_zone
    create_physical_network "$ZONE_ID"
    add_traffic_type "$PHY_ID" "Guest" 
    add_traffic_type "$PHY_ID" "Management" 
    enable_physical_network "$PHY_ID"
    enable_virtual_router_element "$PHY_ID"
    
    script_ended_ok=true
    exit

 
    enable_network_security_group_provider "$PHY_ID"
    create_network "$ZONE_ID"
    create_pod "$ZONE_ID"
    create_vlan_ip_range "$POD_ID"
    create_cluster "$ZONE_ID"
    add_host "$ZONE_ID" "$POD_ID" "$CLUSTER_ID"
    add_secondary_storage
    add_primary_storage
    enable_zone "$ZONE_ID"
    
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

delete_everything() {
    delete_hosts
    delete_clusters
    delete_pods
    delete_networks
    delete_all_physicalnetworks
    delete_all_zones
}

delete_all_objects () {
    objects=$1
    object="${objects%?}"
    ids=$(cmk list $objects | grep "^id =" | awk '{print $3}')
    if [[ "$ids" =~ ^[[:space:]]*$ ]]; then
        logMessage "--- No $objects found to delete."
        return
    fi
    confirm "--- Delete existing $objects: ${ids} ?" || exit 1

    # Loop through each zone ID and delete the zone
    counter=0
    for id in $ids; do
        do_cmd "cmk delete $object id=${id}" "$object ${id} deleted." "Failed to delete $object ${id}"
    done

}

delete_all_zones() {
    delete_all_objects "zones"
    # zone_ids=$(cmk list zones | grep "id =" | awk '{print $3}')
    # if [[ "$zone_ids" =~ ^[[:space:]]*$ ]]; then
    #     logMessage "--- No zones found to delete."
    #     return
    # fi
    # confirm "--- Delete existing zones: ${zone_ids} ?" || exit 1

    # # Loop through each zone ID and delete the zone
    # counter=0
    # for id in $zone_ids; do
    #     do_cmd "cmk delete zone id=${id}" "Zone ${id} deleted." "Failed to delete zone ${id}"
    # done
}

delete_all_physicalnetworks() {
    delete_all_objects "physicalnetworks"
    # phy_ids=$(cmk list physicalnetworks | grep "^id =" | awk '{print $3}')
    # if [[ "$phy_ids" =~ ^[[:space:]]*$ ]]; then
    #     logMessage "--- No physicalnetworks found to delete."
    #     return
    # fi
    # confirm "--- Delete existing physicalnetworks: ${phy_ids} ?" || exit 1

    # # Loop through each physicalnetwork ID and delete the physicalnetwork
    # counter=0
    # for id in $phy_ids; do
    #     do_cmd "cmk delete physicalnetwork id=${id}" "physicalnetwork ${id} deleted." "Failed to delete physicalnetwork ${id}"
    # done
}

delete_hosts () {
    delete_all_objects "hosts"

}

delete_clusters () {
    delete_all_objects "clusters"
}

delete_pods () {
    delete_all_objects "pods"
}

delete_networks () {
    delete_all_objects "networks"
}


# Returns the created zone id in the global variable ZONE_ID
create_zone() {
    #cmd="cmk create zone dns1=$IP_EXTERNAL_DNS internaldns1=$IP_HOME_DNS name=ubuntu_zone1 networktype=Basic"
    do_cmd 'result=$(cmk create zone dns1=8.8.8.8 internaldns1=192.168.1.1 name=ubuntu_zone1 networktype=Basic)' "Zone created." "Zone creation failed."
    ZONE_ID=$(echo $result | sed 's/zone = //g' | jq -r '.id')
    logMessage "Zone: $ZONE_ID created."
}

create_physical_network() {
  local zone_id=$1
  do_cmd 'result=$(cmk create physicalnetwork name=phy-network zoneid='$zone_id')' "Network created." "Network creation failed."
  PHY_ID=$(echo $result | sed 's/physicalnetwork = //g' | jq -r '.id')
  logMessage "--- Physical Network: $PHY_ID created."
}

add_traffic_type() {
    local phy_id="$1"
    local traffic_type="$2"
    do_cmd 'result=$(cmk add traffictype traffictype='$traffic_type' physicalnetworkid='$phy_id')'   "Traffic type $traffic_type added."  "Failed to add Traffic type $traffic_type"  
    TRAFFIC_TYPE_ID=$(echo $result | sed 's/traffictype = //g' | jq -r '.id')
    logMessage "--- Traffic type $traffic_type: $TRAFFIC_TYPE_ID added"
}

enable_physical_network() {
    local phy_id="$1"
    do_cmd 'result=$(cmk update physicalnetwork state=Enabled id='$phy_id')' "Physical network $phy_id enabled." "Physical network $phy_id not enabled."
}

enable_virtual_router_element() {
    local phy_id="$1"
    local nsp_id=$(cmk list networkserviceproviders name=VirtualRouter physicalnetworkid=$phy_id | grep "^id =" | awk '{print $3}')
    logMessage "--- Found NetworkServiceProvider for VirtualRouter: $nsp_id"
    local vre_id=$(cmk list virtualrouterelements nspid=$nsp_id | grep "^id =" | awk '{print $3}')
    logMessage "--- Found virtual router elements for VirtualRouter: $vre_id"
    do_cmd 'result=$(cmk configure virtualrouterelement enabled=true id='$vre_id')' "Virtual Router Element $vre_id enabled." "Virtual Router Element $vre_id not enabled."        
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
