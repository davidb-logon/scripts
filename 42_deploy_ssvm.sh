#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# See usage for what this script does.
# TODOs:

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

script_ended_ok=false
trap 'cleanup' EXIT

usage() {
cat << EOF
-------------------------------------------------------------------------------
Setup networking on KVM host on RHEL 8.6 on Z, following instructions at:
https://docs.cloudstack.apache.org/en/4.19.1.0/installguide/hypervisor/kvm.html#configuring-the-networking

-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

main() {
    init_vars "logon" "set_cloudbr0_on_rhel_z"
    start_logging
    check_if_root

    deploy_ssvm
    
    script_ended_ok=true
}


deploy_ssvm(){
   
# Create the service offering
SERVICE_OFFERING_ID=$(cmk create serviceoffering \
    name="$SERVICE_OFFERING_NAME" \
    displaytext="$SERVICE_OFFERING_DESCRIPTION" \
    cpunumber=$CPU_NUMBER \
    cpuspeed=$CPU_SPEED \
    memory=$MEMORY \
    storagetype="$STORAGE_TYPE" \
    issystem=true \
    systemvmtype="secondarystoragevm" \
    | grep -oP '(?<="id": ")[^"]*')

# Check if the service offering was created successfully
if [ -z "$SERVICE_OFFERING_ID" ]; then
    echo "Failed to create service offering."
    exit 1
else
    echo "Service offering created successfully with ID: $SERVICE_OFFERING_ID"
fi

# Get the zone ID (assuming a single zone)
#ZONE_ID=$(cmk list zones | grep -oP '(?<="id": ")[^"]*')
ZONE_ID="9437ebc2-360d-4487-a602-5a4262bcadc5"

# Deploy the SSVM using the newly created service offering
SSVM_ID=$(cmk create systemvm \
    zoneid=$ZONE_ID \
    serviceofferingid=$SERVICE_OFFERING_ID \
    systemvmtype="secondarystoragevm" \
    | grep -oP '(?<="id": ")[^"]*')

# Check if the SSVM was deployed successfully
if [ -z "$SSVM_ID" ]; then
    echo "Failed to deploy SSVM."
    exit 1
else
    echo "SSVM deployed successfully with ID: $SSVM_ID"
fi

echo "Script completed successfully."
}
init_vars() {
    init_utils_vars $1 $2
    # Set variables for the service offering
    SERVICE_OFFERING_NAME="SSVM Minimal Offering"
    SERVICE_OFFERING_DESCRIPTION="Minimal Service Offering for SSVM"
    CPU_NUMBER=1
    CPU_SPEED=1000  # 1 GHz
    MEMORY=512      # 512 MB RAM
    STORAGE_TYPE="shared"


}

remove_existing_connections() {
    logMessage "Removing existing network connections if they exist."

    do_cmd "nmcli connection delete eth0 || true"
    do_cmd "nmcli connection delete cloudbr0 || true"
    do_cmd "nmcli connection delete cloud0 || true"
    do_cmd "nmcli connection delete cloudbr1 || true"
    do_cmd "nmcli connection delete eth0.200 || true"
    do_cmd "nmcli device delete eth0 || true"
    do_cmd "nmcli device delete cloudbr0 || true"
    do_cmd "nmcli device delete cloud0 || true"
    do_cmd "nmcli device delete cloudbr1 || true"
    do_cmd "nmcli device delete eth0.200 || true"
    do_cmd "ip link delete eth0 || true"
    do_cmd "ip link delete cloudbr0 || true"
    do_cmd "ip link delete cloud0 || true"
    do_cmd "ip link delete cloudbr1 || true"
    do_cmd "ip link delete eth0.200 || true"
    do_cmd "rm -f /etc/sysconfig/network-scripts/ifcfg-cloudbr0*"
    do_cmd "rm -f /etc/sysconfig/network-scripts/route-cloudbr0*"

}

create_eth0() {
    do_cmd "nmcli connection add type ethernet con-name eth0 ifname eth0 autoconnect yes"
    do_cmd "ip link add eth0 type dummy"
}

create_cloudbr0() {
    do_cmd "nmcli connection add type bridge con-name cloudbr0 ifname cloudbr0"
    do_cmd "nmcli connection modify cloudbr0 ipv4.method manual ipv4.addresses 192.168.122.1/24 ipv4.gateway 192.168.122.1"
    do_cmd "nmcli connection modify cloudbr0 ipv6.method ignore"
    do_cmd "nmcli connection modify cloudbr0 bridge.stp yes"
    do_cmd "nmcli connection modify cloudbr0 ipv4.dns 8.8.8.8 ipv4.dns-search 'wave.log-on.com' ipv6.method disabled"
    nmcli connection modify cloudbr0 ipv4.routes "0.0.0.0/0 204.90.115.1"
}

# create_cloudbr1() {
#     do_cmd "nmcli connection add type bridge con-name cloudbr1 ifname cloudbr1"
#     do_cmd "nmcli connection modify cloudbr1 ipv4.method disabled"
#     do_cmd "nmcli connection modify cloudbr1 ipv6.method ignore"
#     do_cmd "nmcli connection modify cloudbr1 bridge.stp yes"
#     do_cmd "nmcli connection up cloudbr1"
# }

# create_vlan_eth0_200() {
#     do_cmd "nmcli connection add type vlan con-name eth0.200 dev eth0 id 200"
#     do_cmd "nmcli connection modify eth0.200 connection.slave-type bridge connection.master cloudbr1"
#     do_cmd "nmcli connection up eth0.200"
# }

attach_eth0_to_cloudbr0() {
    do_cmd "nmcli connection modify eth0 connection.slave-type bridge connection.master cloudbr0"
    do_cmd "nmcli connection up cloudbr0"
    do_cmd "nmcli connection up eth0"
}

main "$@"
