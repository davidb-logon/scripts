#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

main() {
    start_time=$(date +%s)
    usage
    init_vars "logon" "deploy_basic_cs_env"
    start_logging
    retry_cmk  # wait for cmk to be ready
    delete_everything
    sleep 2
    create_zone "dlinux_zone" # Creates global $ZONE_ID
    create_physical_network "$ZONE_ID"
    add_traffic_type "$PHY_ID" "Guest" 
    add_traffic_type "$PHY_ID" "Management" 
    enable_physical_network "$PHY_ID"
    enable_virtual_router_element "$PHY_ID"
    create_network "$ZONE_ID" # Creates global $NETWORK_ID
    create_pod "$ZONE_ID" "dlinux_pod" # Creates global $POD_ID
    create_vlan_ip_range "$POD_ID" "$NETWORK_ID"
    create_cluster "$ZONE_ID" "$POD_ID" "dlinux_cluster"
    update_hyprvisor_host_ip "$DLINUX_IP"
    add_ssh_key_to_cloudstack
    add_host "$DLINUX_IP" "$DLINUX_USER" "$DLINUX_PASSWORD" "$ZONE_ID" "$POD_ID" "$CLUSTER_ID"
    
    add_primary_storage "$ZONE_ID" "$POD_ID" "$CLUSTER_ID" "dlinux_primary" 
    add_secondary_storage "$ZONE_ID" "dlinux_secondary"

    enable_zone "$ZONE_ID"
    check_security_rule  # Check if the rule exists. If not, create it - this is a workaround for cloudstack dropping connectivity
    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    logMessage "The script took $elapsed_time seconds to complete."
    script_ended_ok=true
}

retry_cmk() {
    local retries=20
    local count=0

    while [ $count -lt $retries ]; do
        # Run the command
        cmk list zones
        
        # Check the exit status of the command
        if [ $? -eq 0 ]; then
            logMessage "Command succeeded"
            return 0
        fi
        
        # If it failed, wait for 1 second and retry
        logMessage "Command failed, retrying in 1 second..."
        sleep 1
        count=$((count + 1))
    done

    logMessage "Command failed after $retries attempts"
    return 1
}

add_ssh_key_to_cloudstack() {
    do_cmd "cmk delete sshkeypair name=host_key" "successfully deleted keypair host_key" "INFO: keypair does not exist"
    do_cmd 'cmk create sshkeypair name=host_key publickey=\"'$(cat /root/.ssh/id_rsa.pub)'\"' "Successfully added key pair" "failed to add keypair"
}

init_vars() {
    init_utils_vars $1 $2
    IP_PREFIX="192.168.122"
    
    IP_EXTERNAL_DNS="8.8.8.8"
    IP_HOME_DNS="192.168.122.1"
    IP_HOME_GATEWAY="192.168.122.1"
    NETMASK="255.255.255.0"
    HYPERVISOR="KVM"
    POD_START_IP="${IP_PREFIX}.160"
    POD_END_IP="${IP_PREFIX}.169"
    VLAN_START_IP="${IP_PREFIX}.170"
    VLAN_END_IP="${IP_PREFIX}.179"

    DLINUX_IP="192.168.122.1"
    DLINUX_USER=root
    DLINUX_PASSWORD=WaveZ123
    DLINUX_PRIMARY_STORAGE="nfs://192.168.122.1/data/mainframe_primary"
    DLINUX_SECONDARY_STORAGE="nfs://192.168.122.1/data/mainframe_secondary"

    MAINFRAME_IP="192.168.122.1"
    MAINFRAME_USER=root
    MAINFRAME_PASSWORD=WaveZ123
    MAINFRAME_PRIMARY_STORAGE="nfs://192.168.122.1/data/mainframe_primary"
    MAINFRAME_SECONDARY_STORAGE="nfs://192.168.122.1/data/mainframe_secondary"

}

delete_everything() {
    delete_primary_storage
    delete_secondary_storage
    delete_hosts
    delete_clusters
    delete_pods
    delete_systemvms
    delete_networks
    delete_all_physicalnetworks
    delete_all_zones
}

delete_all_objects () {
    objects=$1
    object="${objects%?}"
    #ids=$(cmk list $objects | grep "^id =" | awk '{print $3}')
    ids=$(cmk list $objects | jq -r ".${object}[].id")

    if [[ "$ids" =~ ^[[:space:]]*$ ]]; then
        logMessage "--- No $objects found to delete."
        return
    fi

    confirm "--- Delete existing $objects: ${ids} ?" || exit 1

    
    counter=0
    [[ $object == "host" ]] && forced="forced=true" || forced=""
    
    # Loop through each zone ID and delete the zone
    for id in $ids; do
        if [[ $object == "storagepool" ]]; then
            place_storage_pool_in_maintenance $id
        fi
        if [[ $object == "systemvm" ]]; then
            do_cmd "cmk expunge systemvm id=${id}" "systemvm ${id} deleted." "Failed to delete systemvm ${id}"
        else 
            do_cmd "cmk delete $object id=${id} $forced" "$object ${id} deleted." "Failed to delete $object ${id}"
        fi
    done

}

place_storage_pool_in_maintenance(){
    local id=$1
    do_cmd 'result=$(cmk list storagepools id='$id' | grep -c "Maintenance")' "" "INFO: not in maintenance"
    if [[ $result = "1" ]]; then
        logMessage "Storagepool $id already in maintenance mode"
    else
        do_cmd 'cmk enable storagemaintenance id=${id}' "Storagepool placed in maintenance mode" "failed to place storagepool in maintenance mode"
    fi
}

delete_all_zones() {
    delete_all_objects "zones"

}

delete_all_physicalnetworks() {
    delete_all_objects "physicalnetworks"
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
delete_systemvms () {
    delete_all_objects "systemvms"
}

delete_networks () {
    delete_all_objects "networks"
}

delete_secondary_storage() {
    delete_all_objects "imagestores"
}

delete_primary_storage() {
    delete_all_objects "storagepools"
}

# Returns the created zone id in the global variable ZONE_ID
create_zone() {
    local zone_name="$1"
    #cmd="cmk create zone dns1=$IP_EXTERNAL_DNS internaldns1=$IP_HOME_DNS name=ubuntu_zone1 networktype=Basic"
    do_cmd 'result=$(cmk create zone dns1=8.8.8.8 internaldns1=192.168.122.1 name='$zone_name' networktype=Basic)' "Zone created." "Zone creation failed."
    #ZONE_ID=$(echo $result | sed 's/zone = //g' | jq -r '.id')
    ZONE_ID=$(echo "$result" | jq -r '.zone.id')
    logMessage "Zone: $ZONE_ID created."
}

create_physical_network() {
  local zone_id=$1
  # Check if the zone has already a physical network, if yes, assign PHY_ID to the physical network id.
  # Else create the network for this zone.
  
  do_cmd 'result=$(cmk create physicalnetwork name=phy-network zoneid='$zone_id')' "Network created." "Network creation failed."
  PHY_ID=$(echo $result | jq -r '.physicalnetwork.id')
  logMessage "--- Physical Network: $PHY_ID created."
}

check_security_rule() {
    # Get the JSON data from the command (assuming it's stored in a variable or directly in the function)
    json_output=$(cmk list securitygroups)

    # Use jq to parse the JSON and check for the rule
    rule_exists=$(echo "$json_output" | jq '.securitygroup[].ingressrule[] | select(.protocol == "all" and .cidr == "0.0.0.0/0")')

    if [ -n "$rule_exists" ]; then
        logMessage "Rule for protocol=all and cidr=0.0.0.0/0 exists."
    else
       logMessage "Rule for protocol=all and cidr=0.0.0.0/0 does not exist."

        # If the rule doesn't exist, create it
        create_securitygroup_ingressrule
    fi
}

create_securitygroup_ingressrule() {
  local securitygroupid=$(cmk list securitygroups | jq -r '.securitygroup[0].id')
  local domainid=$(cmk list domains | jq -r '.domain[0].id');
  do_cmd 'result=$(cmk authorizeSecurityGroupIngress securitygroupid='$securitygroupid' domainid='$domainid' protocol=all cidrlist=0.0.0.0/0)' "Rule created." "Rule creation failed."
}

add_traffic_type() {
    local phy_id="$1"
    local traffic_type="$2"
    do_cmd 'result=$(cmk add traffictype traffictype='$traffic_type' physicalnetworkid='$phy_id' kvmnetworklabel=cloudbr0 )'   "Traffic type $traffic_type added."  "Failed to add Traffic type $traffic_type"  
    TRAFFIC_TYPE_ID=$(echo $result | jq -r '.traffictype.id')
    logMessage "--- Traffic type $traffic_type: $TRAFFIC_TYPE_ID added"
}

enable_physical_network() {
    local phy_id="$1"
    do_cmd 'result=$(cmk update physicalnetwork state=Enabled id='$phy_id')' "Physical network $phy_id enabled." "Physical network $phy_id not enabled."
}

enable_virtual_router_element() {
    local phy_id="$1"
    
    #local nsp_id=$(cmk list networkserviceproviders name=VirtualRouter physicalnetworkid=$phy_id | grep "^id =" | awk '{print $3}')
    local nsp_id=$(cmk list networkserviceproviders name=VirtualRouter physicalnetworkid=$phy_id |  jq -r ".networkserviceprovider[].id")
    logMessage "--- Found Network Service Provider for physical network: $nsp_id"
    
    #local vre_id=$(cmk list virtualrouterelements nspid=$nsp_id | grep "^id =" | awk '{print $3}')
    local vre_id=$(cmk list virtualrouterelements nspid=$nsp_id | jq -r ".virtualrouterelement[].id")
    logMessage "--- Found Virtual Router Element for Virtual Router: $vre_id"
    
    #local nsp_sg_id=$(cmk list networkserviceproviders name=SecurityGroupProvider physicalnetworkid=$phy_id | grep "^id =" | awk '{print $3}')
    local nsp_sg_id=$(cmk list networkserviceproviders name=SecurityGroupProvider physicalnetworkid=$phy_id | jq -r ".networkserviceprovider[].id")
    logMessage "--- Found Security Group Provider for physical network: $nsp_sg_id"
    
    do_cmd 'result=$(cmk configure virtualrouterelement enabled=true id='$vre_id')' "Virtual Router Element $vre_id enabled." "Virtual Router Element $vre_id not enabled."        
    do_cmd 'result=$(cmk update networkserviceprovider state=Enabled id='$nsp_id')' "Virtual Router service $nsp_id enabled." "Virtual Router service $nsp_id not enabled."
    do_cmd 'result=$(cmk update networkserviceprovider state=Enabled id='$nsp_sg_id')' "Security Group Provider service $nsp_sg_id enabled." "Security Group Provider service $nsp_sg_id not enabled."
    logMessage "--- Enabled virtual router element, Virtual Router service, and Security Group Provider service."        
}

create_network() {
    local zone_id="$1"
    #local netoff_id=$(cmk list networkofferings name=DefaultSharedNetworkOfferingWithSGService | grep "^id =" | awk '{print $3}')
    local netoff_id=$(cmk list networkofferings name=DefaultSharedNetworkOfferingWithSGService | jq -r ".networkoffering[].id")
    logMessage "--- Found Network Offering for Shared with Security Groups: $netoff_id"
    do_cmd 'result=$(cmk create network zoneid='$zone_id' name=guestNetworkForBasicZone displaytext=guestNetworkForBasicZone networkofferingid='$netoff_id')' \
        "Network created." "Network creation failed."
    NETWORK_ID=$(echo $result | jq -r '.network.id')
    logMessage "--- Network: $NETWORK_ID created."
}

create_pod() {
    local zone_id="$1"
    local pod_name="$2"
    do_cmd 'result=$(cmk create pod name='$pod_name' zoneid='$zone_id' gateway='$IP_HOME_GATEWAY' netmask='$NETMASK' startip='$POD_START_IP' endip='$POD_END_IP')' \
        "Pod $pod_name created." "Pod $pod_name creation failed."
    POD_ID=$(echo $result | jq -r '.pod.id')
    logMessage "--- Pod: $POD_ID created."
}

create_vlan_ip_range() {
    local pod_id="$1"
    local network_id="$2"
    do_cmd 'result=$(cmk create vlaniprange podid='$pod_id' networkid='$network_id' gateway='$IP_HOME_GATEWAY' netmask='$NETMASK' startip='$VLAN_START_IP' endip='$VLAN_END_IP' forvirtualnetwork=false)' 
    VLAN_RANGE_ID=$(echo $result | jq -r '.vlan.id')
    logMessage "--- VLAN Range for instances: $VLAN_RANGE_ID created."    

} 
    
create_cluster () {
    local zone_id="$1"
    local pod_id="$2"
    local cluster_name="$3"
    do_cmd 'result=$(cmk add cluster zoneid='$zone_id' hypervisor='$HYPERVISOR' clustertype=CloudManaged podid='$pod_id' clustername='$cluster_name')' 
    #CLUSTER_ID=$(echo $result | grep -oP ' id = \K[^ ]+') # Special treatment of the result output here. It is not json, nor is it lines of text...
    CLUSTER_ID=$(echo $result | jq -r ".cluster[].id")
    logMessage "--- Cluster: $CLUSTER_ID created."     
}

add_host() {
    local host_ip="$1"
    local host_user="$2"
    local host_password="$3"
    local zone_id="$4"
    local pod_id="$5"
    local cluster_id="$6"
    #hostname=192.168.1.100 username=cloudstackuser sshkeypair="my-ssh-keypair"

    #do_cmd 'result=$(cmk add host zoneid='$zone_id' podid='$pod_id' clusterid='$cluster_id' hypervisor='$HYPERVISOR' username='$host_user' sshkeypair=host_key url=http://'$host_ip')' 
    do_cmd 'result=$(cmk add host zoneid='$zone_id' podid='$pod_id' clusterid='$cluster_id' hypervisor='$HYPERVISOR' username='$host_user' password='$host_password'  url=http://'$host_ip')' 
    #HOST_ID=$(echo $result | grep -oP ' id = \K[^ ]+') # Special treatment of the result output here. It is not json, nor is it lines of text...
    HOST_ID=$(echo $result | jq -r ".host[].id") # Special treatment of the result output here. It is not json, nor is it lines of text...
    logMessage "--- Host: $HOST_ID created."
}

# add_primary_storage "$ZONE_ID" "$POD_ID" "$CLUSTER_ID" "ubuntu_primary" 
add_primary_storage() {
    local zone_id="$1"
    local pod_id="$2"
    local cluster_id="$3"
    local primary_storage_name="$4"
    do_cmd 'result=$(cmk create storagepool zoneid='$zone_id' podid='$pod_id' clusterid='$cluster_id' name='$primary_storage_name' url='$DLINUX_PRIMARY_STORAGE')'
    #PRIMARY_STORAGE_ID=$(echo $result | grep -oP ' id = \K[^ ]+') # Special treatment of the result output here. It is not json, nor is it lines of text...
    PRIMARY_STORAGE_ID=$(echo $result | jq -r ".storagepool.id") # Special treatment of the result output here. It is not json, nor is it lines of text...
    logMessage "--- Primary Storage: $PRIMARY_STORAGE_ID created."
}

# add_secondary_storage "$ZONE_ID" "ubuntu_secondary"
add_secondary_storage () {
    local zone_id="$1"
    local secondary_storage_name="$2"
    do_cmd 'result=$(cmk add secondarystorage zoneid='$zone_id' url='$DLINUX_SECONDARY_STORAGE')'
    #SECONDARY_STORAGE_ID=$(echo $result | grep -oP ' id = \K[^ ]+') # Special treatment of the result output here. It is not json, nor is it lines of text...
    SECONDARY_STORAGE_ID=$(echo $result | jq -r ".secondarystorage.id") # Special treatment of the result output here. It is not json, nor is it lines of text...
    logMessage "--- Secondary Storage: $SECONDARY_STORAGE_ID created."
}

enable_zone() {
    local zone_id="$1"
    do_cmd 'result=$(cmk update zone allocationstate=Enabled id='$zone_id')'
    logMessage "--- Zone allocation state enabled for zone: $zone_id"    
}

update_hyprvisor_host_ip() {
    local host_ip="$1"
    do_cmd 'result=$(cmk update configuration name=host value=$host_ip)'
    logMessage "--- update hyprvisor host ip: $host_ip"    
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