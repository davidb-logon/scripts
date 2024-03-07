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
Install Cloudstack KVM Agent from local repo 

Following instructions at:
http://docs.cloudstack.apache.org/en/4.19.0.0/installguide/hypervisor/kvm.html

-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

main() {
    # Replace logon and template with your own values
    init_vars "logon" "install_cloudstack_kvm_on_rhel"
    start_logging
    
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}

install_kvm_and_libvirt() {
    logMessage "--- Start to install KVM and libvirt"

    # Check if the current user ID is 0 (root user)
    if [ "$(id -u)" -ne 0 ]; then
        logMessage "--- You are not root. Will prepend 'sudo' to all commands."
        SUDO="sudo"
    else
        logMessage "--- Logged in as root."
        SUDO=""
    fi

    #do_cmd "$SUDO yum -y install  bzip2  ipmitool qemu-guest-agent"
    

    logMessage "--- End of installing KVM and libvirt"
}

main "$@"
