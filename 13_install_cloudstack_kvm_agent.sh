#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# See usage for what this script does.
# TODOs:


# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"
source "$DIR/lib/nfsconfig.sh"

script_ended_ok=false
trap 'cleanup' EXIT

usage() {
cat << EOF
-------------------------------------------------------------------------------
Install Cloudstack KVM Agent from local repo 

Following instructions at:
http://docs.cloudstack.apache.org/en/4.19.0.0/installguide/hypervisor/kvm.html

-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

main() {
    # Replace logon and template with your own values
    init_vars "logon" "install_cloudstack_kvm_agent"
    start_logging
    prepare_os
    install_cloudstack_kvm_agent
    do_cmd "chmod -R 777 /var/log/cloudstack/*"
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}

# Function to update configuration file
update_libvirt_config_file() {
    local file=$1
    local setting=$2
    local value=$3
    if grep -q "^#*$setting" "$file"; then
        if grep -q "^$setting\s*=\s*$value" "$file"; then
            logMessage "--- No change needed for $setting in $file."
        else
            logMessage "--- Updating $setting in $file."
            sed -i "s/^#*$setting\s*=.*/$setting = $value/" "$file"
        fi
    else
        logMessage "--- Adding $setting to $file."
        logMessage "--- $setting = $value" >> "$file"
    fi
}

configure_libvirt() {
    # Check if the OS is Ubuntu
    logMessage "-- Starting to configure libvirt"

    if ! grep -qi ubuntu /etc/os-release; then
        logMessage "--- WARNING: Not running on Ubuntu - please configure manually."
        return 0
    fi

    # Stop libvirtd service
    logMessage "--- Stopping libvirtd service..."
    systemctl stop libvirtd

    # Ensure /etc/libvirt/libvirtd.conf has the specified settings
    logMessage "--- Configuring /etc/libvirt/libvirtd.conf..."
    update_libvirt_config_file "/etc/libvirt/libvirtd.conf" "listen_tls" "0"
    update_libvirt_config_file "/etc/libvirt/libvirtd.conf" "listen_tcp" "0"
    update_libvirt_config_file "/etc/libvirt/libvirtd.conf" "tls_port" "\"16514\""
    update_libvirt_config_file "/etc/libvirt/libvirtd.conf" "tcp_port" "\"16509\""
    update_libvirt_config_file "/etc/libvirt/libvirtd.conf" "auth_tcp" "\"none\""
    update_libvirt_config_file "/etc/libvirt/libvirtd.conf" "mdns_adv" "0"

    # Ensure /etc/default/libvirtd has the specified line
    logMessage "--- Configuring /etc/default/libvirtd..."
    if grep -q "^LIBVIRTD_ARGS=\"--listen\"" "/etc/default/libvirtd"; then
        logMessage "--- No change needed in /etc/default/libvirtd."
    else
        logMessage "--- Updating /etc/default/libvirtd."
        logMessage "--- LIBVIRTD_ARGS=\"--listen\"" > "/etc/default/libvirtd"
    fi

    logMessage "--- Configuring security policies..."
    if dpkg --list 'apparmor' &> /dev/null; then
        logMessage "--- AppArmor is installed. Configuring AppArmor profiles for Libvirt."

        # Disable AppArmor profiles for Libvirt
        ln -sf /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmor.d/disable/
        ln -sf /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper /etc/apparmor.d/disable/
        apparmor_parser -R /etc/apparmor.d/usr.sbin.libvirtd && logMessage "--- Disabled AppArmor profile for usr.sbin.libvirtd" || logMessage "--- Failed to disable AppArmor profile for usr.sbin.libvirtd"
        apparmor_parser -R /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper && logMessage "--- Disabled AppArmor profile for usr.lib.libvirt.virt-aa-helper" || logMessage "--- Failed to disable AppArmor profile for usr.lib.libvirt.virt-aa-helper"
    else
        logMessage "--- AppArmor is not installed. No action required for security policies."
    fi

    logMessage "--- Restarting libvirtd service..."
    systemctl restart libvirtd
    logMessage "-- Finished to configure libvirt"

}

prepare_os() {
    logMessage "--- Start to prepare OS"
    #!/bin/bash

    # Check if the current user ID is 0 (root user)
    if [ "$(id -u)" -ne 0 ]; then
        logMessage "--- You are not root. Exiting"
        exit 1
    else
        logMessage "--- Logged in as root."
        SUDO=""
    fi
    HOSTNAME=$(hostname --fqdn)
    confirm "--- hostname: $HOSTNAME, confirm " || exit 1
    

    if ! check_if_connected_to_internet; then
        logMessage "--- Not connected to internet"
        exit 1
    fi
    logMessage "Connected to the internet."

    logMessage "Installing ntp"
    do_cmd "$SUDO apt install chrony" "Installed chrony"
    do_cmd "install_java.sh"

    logMessage "--- End of preparing OS"
}

install_cloudstack_kvm_agent() {
    logMessage "--- Start to install Cloudstack Agent"
    do_cmd "$SUDO apt-get update"  # Update apt's index, to ensure getting the latest version.
    do_cmd "$SUDO apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager"
    configure_libvirt
    do_cmd "$SUDO apt install cloudstack-agent"
    logMessage "--- End of installing Cloudstack Agent"
}

main "$@"