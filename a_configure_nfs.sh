#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# See usage for what this script does.

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"
source "$DIR/lib/nfsconfig.sh"

script_ended_ok=false
trap 'cleanup' EXIT

usage() {
cat << EOF
-------------------------------------------------------------------------------
Install Cloudstack server from local repo at 10.0.0.20

Following instructions at:
http://docs.cloudstack.apache.org/en/4.19.0.0/installguide/management-server/index.html


-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

prepare_nfs_shares() {
    # See: http://docs.cloudstack.apache.org/en/4.19.0.0/installguide/management-server/index.html#using-the-management-server-as-the-nfs-server

    logMessage "--- Start to prepare NFS shares"
    do_cmd "$SUDO apt install nfs-kernel-server"
    do_cmd "$SUDO mkdir -p /export/primary"
    do_cmd "$SUDO mkdir -p /export/secondary"
    set_nfs_exports_options
    configure_nfs_ports_on_ubuntu
    logMessage "--- End of preparing NFS shares"
}

main() {
    # Replace logon and template with your own values
    init_vars "logon" "configure_nfs"
    start_logging
    prepare_nfs_shares
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
    SUDO="sudo"
}

cleanup() {
    if $script_ended_ok; then 
        echo -e "$green"
        echo 
        echo "--- SCRIPT WAS SUCCESSFUL"
    else
        echo -e "$red"
        echo 
        echo "--- SCRIPT WAS UNSUCCESSFUL"
    fi
    echo "--- Logfile at: cat $LOGFILE"
    echo "--- End Script"
    echo -e "$reset"
}
    
main "$@"
