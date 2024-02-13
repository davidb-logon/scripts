#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# functions to configure NFS on ubuntu

# Function to create an override directory and file if they don't exist
create_override_dir_and_file() {
    local service_name=$1
    local override_dir="/etc/systemd/system/${service_name}.service.d"
    local override_file="${override_dir}/override.conf"

    if [ ! -d "$override_dir" ]; then
        sudo mkdir -p "$override_dir"
    fi

    if [ ! -f "$override_file" ]; then
        sudo touch "$override_file"
    fi
    echo "$override_file"
}

# Function to set port for a service in its override file
set_service_port() {
    local service_name=$1
    local port_option=$2
    local port=$3

    local override_file=$(create_override_dir_and_file "$service_name")
    # Check if the port option already exists, and replace it if it does
    
    if sudo grep -qE "^ExecStart=.*${port_option}" "$override_file"; then
        sudo sed -i "/ExecStart=.*${port_option}/c\ExecStart=/usr/sbin/${service_name} ${port_option} ${port}" "$override_file"
    else
        # Append new ExecStart line with port configuration
        sudo echo -e "[Service]\nExecStart=\nExecStart=/usr/sbin/${service_name} ${port_option} ${port}" | sudo tee -a "$override_file" > /dev/null 
    fi
    logMessage "--- Written to: $override_file: "
    cat "$override_file"
}

# Special handling for lockd, which may require setting kernel module options
set_lockd_file() {
    LOCKD_TCPPORT="$1"
    LOCKD_UDPPORT="$2"
    LOCKD_FILE="/etc/modprobe.d/lockd.conf"
    LOCKD_LINE="options lockd nlm_tcpport=$LOCKD_TCPPORT nlm_udpport=$LOCKD_UDPPORT"

    if ! grep -qE "^${LOCKD_LINE}" $LOCKD_FILE; then
        # Append the option line
        echo $LOCKD_LINE | sudo tee -a $LOCKD_FILE > /dev/null 
    fi
    logMessage "--- Written to: $LOCKD_FILE:"
    cat "$LOCKD_FILE"
}

# From http://docs.cloudstack.apache.org/en/4.19.0.0/installguide/management-server/index.html#using-the-management-server-as-the-nfs-server
# LOCKD_TCPPORT=32803
# LOCKD_UDPPORT=32769
# MOUNTD_PORT=892
# RQUOTAD_PORT=875
# STATD_PORT=662
# STATD_OUTGOING_PORT=2020

configure_nfs_ports_on_ubuntu() {
    check_if_ubuntu
    # Configure ports for NFS-related services
    set_service_port "rpc.mountd" "--port" "892"
    set_service_port "rpc.rquotad" "--port" "875"
    set_service_port "rpc.statd" "--port" "662 --outgoing-port 2020"
    set_lockd_file 32803 32769

    # Reload systemd, restart services
    do_cmd "sudo systemctl daemon-reload"
    do_cmd "sudo systemctl restart nfs-kernel-server"
    do_cmd "sudo systemctl restart rpc-statd"
    logMessage "NFS-related services have been configured on Ubuntu."
}

set_nfs_exports_options() {
    # Define the line to add to /etc/exports
    exports_line="/export  *(rw,async,no_root_squash,no_subtree_check)"
    if ! sudo grep -qF -- "$exports_line" /etc/exports; then
        # Line does not exist, append it to /etc/exports
        echo "$exports_line" | sudo tee -a /etc/exports > /dev/null
        logMessage "--- The line '$exports_line' was added to /etc/exports"
    else
        logMessage "--- The line:'$exports_line' already exists in /etc/exports, no changes made."
    fi
    do_cmd "sudo exportfs -a" "exportfs -a was executed to apply changes"
}