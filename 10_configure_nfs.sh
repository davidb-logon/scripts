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

main() {
    detect_linux_distribution # Sets global variable $LINUX_DISTRIBUTION
    init_vars "logon" "configure_nfs"
    start_logging
    check_if_root
    prepare_os
    prepare_nfs_shares
    mount_nfs
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
    case "$LINUX_DISTRIBUTION" in
    "UBUNTU")
        CMD="apt"
        NFS_SERVER="nfs-kernel-server"
        PRIMARY="ubuntu_primary"
        SECONDARY="ubuntu_secondary"
      ;;
    "RHEL")
        CMD="yum"
        NFS_SERVER="nfs-utils"
        PRIMARY="mainframe_primary"
        SECONDARY="mainframe_secondary"
      ;;
    *)
      logMessage "Unknown or Unsupported LINUX_DISTRIBUTION: $LINUX_DISTRIBUTION, exiting"
      exit 1
      ;;
    esac    

}
 
usage() {
cat << EOF
-------------------------------------------------------------------------------
Install Cloudstack server from local repo 

Following instructions at:
http://docs.cloudstack.apache.org/en/4.19.0.0/installguide/management-server/index.html


-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

prepare_os() {
    do_cmd "$CMD install $NFS_SERVER"
    do_cmd "systemctl enable $NFS_SERVER"
    do_cmd "systemctl restart $NFS_SERVER"
    if [[ $LINUX_DISTRIBUTION = "RHEL" ]]; then
        do_cmd "mount_iso_for_mainframe.sh"
    fi
}


prepare_nfs_shares() {
    # See: http://docs.cloudstack.apache.org/en/4.19.0.0/installguide/management-server/index.html#using-the-management-server-as-the-nfs-server

    logMessage "--- Start to prepare NFS shares"
    do_cmd "mkdir -p /data/$PRIMARY"
    do_cmd "mkdir -p /data/$SECONDARY"
    do_cmd "chmod 777 /data/$PRIMARY"
    do_cmd "chmod 777 /data/$SECONDARY"
    
    set_nfs_exports_options "/data/$PRIMARY" "/data/$SECONDARY"
    if [[ $LINUX_DISTRIBUTION = "UBUNTU" ]]; then
        configure_nfs_ports_on_ubuntu
    fi
    logMessage "--- End of preparing NFS shares"
}


mount_nfs() {
    logMessage "--- Starting to mount nfs"
    do_cmd "mkdir -p /mnt/$PRIMARY"
    do_cmd "mkdir -p /mnt/$SECONDARY"
    do_cmd "chmod 777 /mnt/$PRIMARY"
    do_cmd "chmod 777 /mnt/$SECONDARY"
    do_cmd "mount -t nfs localhost:/data/$PRIMARY /mnt/$PRIMARY" "/mnt/$PRIMARY was mounted."
    do_cmd "mount -t nfs localhost:/data/$SECONDARY /mnt/$SECONDARY" "/mnt/$SECONDARY was mounted."
    logMessage "--- End mount nfs"
}

   
main "$@"
