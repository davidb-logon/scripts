#!/bin/bash

#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

script_ended_ok=false
trap 'cleanup' EXIT

main() {
    start_time=$(date +%s)
    usage
    init_vars "logon" "emulate_x86_iso_on_z"
    start_logging
    check_if_root
    create_disk_image
    starting_qemu_to_install_the_os
    
    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    logMessage "The script took $elapsed_time seconds to complete."
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
    ISO_FILE="./ubuntu-24.04-desktop-amd64.iso"
    DISK_IMAGE="/var/lib/libvirt/images/ubuntu24.qcow2"
    VM_NAME="ubuntu24"
    MEMORY="2048"
    VCPUS="2"
    VNC_PORT="-1"
}

create_disk_image() {
    logMessage "Start creating disk image."
    do_cmd "qemu-img create -f qcow2 $DISK_IMAGE 7G"
    logMessage "End creating disk image."
}

starting_qemu_to_install_the_os(){
    # Install the OS using QEMU
    logMessage "Starting QEMU to install the OS..."
    
    do_cmd "qemu-system-x86_64 \
        -m $MEMORY \
        -cdrom $ISO_FILE \
        -drive file=$DISK_IMAGE,format=qcow2,if=virtio \
        -boot d \
        -enable-kvm \
        -cpu host \
        -net nic -net user \
        -vnc :0 &"
    logMessage "End QEMU to install the OS..."
}

parse_command_line_arguments() {
    # if [[ $# -lt 1 || $# -gt 2 ]]; then
    #     usage
    #     exit
    # fi
    temp=1
}


usage() {
cat << EOF
-------------------------------------------------------------------------------
This script 
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

main "$@"
