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
    init_vars "logon" "install_cloudstack_kvm_agent_on_rhel"
    start_logging
    detect_linux_distribution # LINUX_DISTRIBUTION
    detect_architecture # MACHINE_ARCHITECTURE
    check_if_root
    prepare_os
    start_web_server_on_repo.sh
    uninstall_cloudstack_agent
    install_cloudstack_kvm_agent
    add_env_vars_to_cloudstack_agent
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}

prepare_os() {
    logMessage "--- Start to prepare OS"   

    if ! check_if_connected_to_internet; then
        error_exit "--- Not connected to internet"
    fi
    logMessage "--- Connected to the internet."

    do_cmd "yum -y install  bzip2  ipmitool qemu-guest-agent"
    do_cmd "yum -y install java-11-openjdk"
    do_cmd "yum -y install python36"
    do_cmd "yum -y install chrony"

    logMessage "--- End of preparing OS"
}

uninstall_cloudstack_agent() {
    logMessage "--- Start to uninstall Cloudstack Agent"
    do_cmd "sudo systemctl stop cloudstack-management" "Stopped cloudstack_management service" "INFO:could not stop service"
    do_cmd "sudo systemctl stop cloudstack-agent" "Stopped cloudstack_agent service" "INFO:could not stop service"
    do_cmd "sudo yum remove cloudstack-agent" "Removed cloudstack-agent" "INFO: could not remove cloudstack-agent"
    do_cmd "sudo yum autoremove"
    do_cmd "sudo yum clean all"
    logMessage "--- End of uninstalling Cloudstack Agent"
}

install_cloudstack_kvm_agent() {
    logMessage "--- Start to install Cloudstack Agent"
    do_cmd "yum -y install cloudstack-common cloudstack-agent"
    logMessage "--- End of installing Cloudstack Agent"
}

add_env_vars_to_cloudstack_agent() {
    local file="/etc/default/cloudstack-agent"
    
    # Check if PKG_CONFIG_PATH is present in the file
    if grep -qc 'PKG_CONFIG_PATH' "$file"; then
        echo "PKG_CONFIG_PATH is already set in $file."
    else
        echo "PKG_CONFIG_PATH is not set in $file. Adding environment variables..."
        
        # Add the specified lines to the file
        cat <<EOL >> "$file"
PATH=/usr/local/glib-2.66.8/bin:/usr/local/bin:/usr/local/go/bin:/usr/local/nodejs/bin:/usr/lib/jvm/java-11-openjdk-11.0.14.1.1-6.el8.s390x/bin:/usr/bin/maven/bin:/data/scripts:/data/scripts/util:/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/opt/groovy/groovy-4.0.9/bin
LD_LIBRARY_PATH=/usr/local/glib-2.66.8/lib64
PKG_CONFIG_PATH=/usr/local/glib-2.66.8/lib64/pkgconfig
JAVA_DEBUG="-agentlib:jdwp=transport=dt_socket,address=*:8001,server=y,suspend=n"
EOL

        echo "Environment variables added to $file."
    fi
}


main "$@"
