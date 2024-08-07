#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# See usage for what this script does.
# TODOs:
# 1. Add installation of groovy, needed for agent hooks


# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"
source "$DIR/lib/nfsconfig.sh"

script_ended_ok=false
trap 'cleanup' EXIT

usage() {
cat << EOF
-------------------------------------------------------------------------------
Install Cloudstack KVM Agent from a local RPM repo, built from source 

Following instructions at:
http://docs.cloudstack.apache.org/en/4.19.0.0/installguide/hypervisor/kvm.html

-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

main() {
    init_vars "logon" "install_cloudstack_kvm_agent_rhel_z"
    start_logging
    check_if_root
    prepare_os
    configure_libvirt
    install_cloudstack_kvm_agent
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}

prepare_os() {
    logMessage "--- Start to prepare OS"

    HOSTNAME=$(hostname --fqdn)
    confirm "--- hostname: $HOSTNAME, confirm " || exit 1
    
    check_if_connected_to_internet || { error_exit "--- Not connected to internet"; }
    install_java.sh
    do_cmd "yum update"
    do_cmd "yum install ipmitool qemu-guest-agent -y"
    do_cmd "yum install python38 -y"
    do_cmd "yum install chrony -y"
    do_cmd "yum install libvirt libvirt-daemon libvirt-daemon-driver-qemu libvirt-client virt-install virt-manager bridge-utils -y"
    logMessage "--- End of preparing OS"
}

config_visudo() {
    set -e

    # Temporary file for storing the updated sudoers file
    TEMP_SUDOERS=$(mktemp)

    # Backup the original sudoers file
    cp /etc/sudoers /etc/sudoers.bak

    # Use visudo to safely add the line to the sudoers file
    visudo -c -f /etc/sudoers.bak && {
        # Add the desired line to the temporary file
        sh -c "echo 'Defaults    env_keep += \"PATH\"' >> $TEMP_SUDOERS"
    
        # Concatenate the original sudoers file and the temporary file
        cat /etc/sudoers.bak $TEMP_SUDOERS > /etc/sudoers.new

        # Validate the new sudoers file
        visudo -c -f /etc/sudoers.new && {
            # If validation is successful, move the new file to /etc/sudoers
            mv /etc/sudoers.new /etc/sudoers
            echo "The line 'Defaults    env_keep += \"PATH\"' has been added to the sudoers file."
        } || {
            # If validation fails, restore the original sudoers file
            echo "Validation failed. Restoring the original sudoers file."
            mv /etc/sudoers.bak /etc/sudoers
        }
    } || {
        echo "The original sudoers file contains syntax errors. Aborting."
    }
    # Clean up the temporary file
    rm -f $TEMP_SUDOERS
}

configure_libvirt() {
    # Check if the OS is Ubuntu
    logMessage "-- Starting to configure libvirt"

    # Stop libvirtd service
    logMessage "--- Stopping libvirtd service..."
    systemctl stop libvirtd

    # Ensure /etc/libvirt/libvirtd.conf has the specified settings
    logMessage "--- Configuring /etc/libvirt/libvirtd.conf..."
    update_config_file "/etc/libvirt/libvirtd.conf" "listen_tls" "0"
    update_config_file "/etc/libvirt/libvirtd.conf" "listen_tcp" "1"
    update_config_file "/etc/libvirt/libvirtd.conf" "tls_port" "\"16514\""
    update_config_file "/etc/libvirt/libvirtd.conf" "tcp_port" "\"16509\""
    update_config_file "/etc/libvirt/libvirtd.conf" "auth_tcp" "\"none\""
    update_config_file "/etc/libvirt/libvirtd.conf" "mdns_adv" "0"

    adjust_SELinux_policies_for_libvirt

    logMessage "--- Restarting libvirtd service..."
    systemctl restart libvirtd
    logMessage "-- Finished to configure libvirt"

}

# This function is not used -- libvritd will not start if the --listen flag is mentioned anywhere
configure_libvirtd_listen() {
    logMessage "--- Start configuring libvird listen"
    # Create the systemd drop-in directory for libvirtd service overrides
    do_cmd "mkdir -p /etc/systemd/system/libvirtd.service.d"

    # Create or edit the override file to ensure libvirtd starts with the --listen parameter
    bash -c 'cat > /etc/systemd/system/libvirtd.service.d/10-listen.conf << EOF
[Service]
Environment="LIBVIRTD_ARGS=--listen"
ExecStart=/usr/sbin/libvirtd
EOF'

    # Enable and restart the libvirtd service
    systemctl enable libvirtd
    logMessage "libvirtd has been configured to start with the --listen parameter "
}

adjust_SELinux_policies_for_libvirt() {
    # Check if SELinux is installed and enabled
    if command -v sestatus &> /dev/null && sestatus | grep 'SELinux status' | grep -q 'enabled'; then
        logMessage "--- SELinux is installed and enabled. Configuring SELinux policies for Libvirt."

        # Adjust SELinux policies for Libvirt
        setsebool -P virt_use_sanlock on && logMessage "--- Enabled virt_use_sanlock SELinux boolean" || logMessage "--- Failed to enable virt_use_sanlock SELinux boolean"
        setsebool -P virt_use_nfs on && logMessage "--- Enabled virt_use_nfs SELinux boolean" || logMessage "--- Failed to enable virt_use_nfs SELinux boolean"
        setsebool -P virt_use_usb on && logMessage "--- Enabled virt_use_usb SELinux boolean" || logMessage "--- Failed to enable virt_use_usb SELinux boolean"
    else
        logMessage "--- SELinux is not installed or not enabled. No action required for security policies."
    fi
}

install_cloudstack_kvm_agent() {
    logMessage "--- Start to install Cloudstack Agent"
    
    start_web_server_on_repo.sh


    # These are the packages needed for the cloudstack agent
    #packages=("cloudstack-common" "cloudstack-agent")
    packages=( "cloudstack-agent")

    for package in "${packages[@]}"
    do
        #do_cmd "wget http://download.cloudstack.org/el/9/4.19/${package}-4.19.0.0-1.x86_64.rpm"
        do_cmd "yum install -y ${package}"

        # if rpm -q "$package" >/dev/null; then
        #     logMessage "$package package is installed. Removing it..."
        #     do_cmd "sudo rpm -e $package"
        # else
        #     logMessage "$package package is not currently installed."
        # fi
        #do_cmd "sudo rpm -ivh --ignorearch  --nodeps --nosignature ${package}-4.19.0.0-1.x86_64.rpm"
    done

    logMessage "--- End of installing Cloudstack Agent"
}

main "$@"
