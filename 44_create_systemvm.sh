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
Configure the netwwork with Network Manager
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

main() {
    init_vars "logon" "configure_network_wo_NM"
    start_logging
    check_if_root
    install_systemvm
    script_ended_ok=true
}

install_systemvm(){
logMessage "Installing systemvm"
virsh destroy debian10-1
virsh undefine debian10-1
do_cmd "mkdir -p /data/vm"
do_cmd "cd /data/vm"
if ! [ -f debian-10.8.0-s390x-xfce-CD-1.iso ]; then
  do_cmd "wget https://cdimage.debian.org/cdimage/archive/10.8.0/s390x/iso-cd/debian-10.8.0-s390x-xfce-CD-1.iso"
fi 
do_cmd "mkdir -p /data/primary/vm/images"
if ! [ -f /data/primary/vm/images/debiaen108-1.qcow2 ]; then
  do_cmd "qemu-img create -o preallocation=off -f qcow2 /data/primary/vm/images/debiaen108-1.qcow2 5242880000"
fi
#!/bin/bash

# Set variables
ISO_PATH="/home/sefi/debian-10.8.0-s390x-netinst.iso"
DISK_PATH="/data/primary/vm/images/debian108-1.qcow2"
DISK_SIZE=6  # Specify as an integer for size in GB
VM_NAME="debian10-1"
MEMORY="2048"
VCPUS="2"
OS_VARIANT="debian10"
NETWORK="default"

# Function to print error messages and exit
function error_exit {
    echo "[ERROR] $1"
    exit 1
}

# Check if ISO file exists
if [ ! -f "$ISO_PATH" ]; then
    error_exit "ISO file not found at $ISO_PATH"
fi

# Check if disk directory exists
DISK_DIR=$(dirname "$DISK_PATH")
if [ ! -d "$DISK_DIR" ]; then
    error_exit "Disk directory not found at $DISK_DIR"
fi

# Check if disk file exists or if we have enough space to create it
if [ -f "$DISK_PATH" ]; then
    echo "[INFO] Disk file already exists at $DISK_PATH"
else
    # Check for available disk space
    AVAILABLE_SPACE=$(df "$DISK_DIR" | awk 'NR==2 {print $4}')
    REQUIRED_SPACE=$((DISK_SIZE * 1024 * 1024))  # Convert GB to KB
    
    if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
        error_exit "Not enough disk space to create $DISK_SIZE GB file in $DISK_DIR"
    fi
    echo "[INFO] Sufficient disk space available to create the disk image."
fi

# Check if `virt-install` command is available
if ! command -v virt-install &> /dev/null; then
    error_exit "virt-install command not found. Please install it before proceeding."
fi

# Check if libvirt service is running
if ! systemctl is-active --quiet libvirtd; then
    error_exit "libvirt service is not running. Please start it before proceeding."
fi

# Check if the specified network is available
if ! virsh net-info "$NETWORK" &> /dev/null; then
    error_exit "Network '$NETWORK' not found in libvirt. Please create or select a different network."
fi

echo "[INFO] All checks passed. Proceeding with the VM installation."

# Run virt-install command
virt-install \
  --name "$VM_NAME" \
  --memory "$MEMORY" \
  --vcpus "$VCPUS" \
  --os-variant "$OS_VARIANT" \
  --network network="$NETWORK" \
  --graphics none \
  --console pty,target_type=serial \
  -v \
  --disk path="$DISK_PATH",size="$DISK_SIZE" \
  --check disk_size=off \
  --boot hd \
  --location="$ISO_PATH" \
  --extra-args 'console=ttyS0,115200n8 console=tty0 noapic nomodeset'

# Check if the VM was successfully created
if [ $? -eq 0 ]; then
    echo "[INFO] VM '$VM_NAME' created successfully."
else
    error_exit "VM creation failed."
fi


}
init_vars() {
    init_utils_vars $1 $2
}


main "$@"
