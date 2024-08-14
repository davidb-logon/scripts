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
    add_env_vars_to_cloudstack_agent
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}

prepare_os() {
    logMessage "--- Start to prepare OS"

    # Check if the current user ID is 0 (root user)
    if [ "$(id -u)" -ne 0 ]; then
        logMessage "--- You are not root. Will prepend 'sudo' to all commands."
        SUDO="sudo"
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
    logMessage "--- Connected to the internet."

    do_cmd "$SUDO yum -y install  bzip2  ipmitool qemu-guest-agent"
    do_cmd "$SUDO yum -y install java-11-openjdk"
    do_cmd "$SUDO yum -y install python36"
    do_cmd "$SUDO yum -y install chrony"

    logMessage "--- End of preparing OS"
}

install_cloudstack_kvm_agent() {
    logMessage "--- Start to install Cloudstack Agent"

    mkdir -p /home/davidb/cloudstack-rpms
    cd /home/davidb/cloudstack-rpms

    # These are the packages needed for the cloudstack agent
    packages=("cloudstack-common" "cloudstack-agent")

    for package in "${packages[@]}"
    do
        do_cmd "wget http://download.cloudstack.org/el/9/4.19/${package}-4.19.0.0-1.x86_64.rpm"

        if rpm -q "$package" >/dev/null; then
            logMessage "$package package is installed. Removing it..."
            do_cmd "sudo rpm -e $package"
        else
            logMessage "$package package is not currently installed."
        fi
        do_cmd "sudo rpm -ivh --ignorearch  --nodeps --nosignature ${package}-4.19.0.0-1.x86_64.rpm"
    done

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
EOL

        echo "Environment variables added to $file."
    fi
}


main "$@"
