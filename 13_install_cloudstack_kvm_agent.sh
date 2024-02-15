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
Install Cloudstack KVM Agent from local repo at 10.0.0.20

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
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}

prepare_os() {
    logMessage "--- Start to prepare OS"
    #!/bin/bash

    # Check if the current user ID is 0 (root user)
    if [ "$(id -u)" -ne 0 ]; then
        logMessage "--- You are not root. Will prepend 'sudo' to all commands."
        SUDO="sudo "
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
    do_cmd "$SUDO apt install cloudstack-agent"
    logMessage "--- End of installing Cloudstack Agent"
}

main "$@"
