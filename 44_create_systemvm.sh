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
if ! [ -f debian-10.8.0-s390x-netinst.iso ]; then
  do_cmd "wget https://cdimage.debian.org/cdimage/archive/10.8.0/s390x/iso-cd/debian-10.8.0-s390x-netinst.iso"
fi 
do_cmd "mkdir -p /data/primary/vm/images"
if ! [ -f /data/primary/vm/images/debiaen108-1.qcow2 ]; then
  do_cmd "qemu-img create -o preallocation=off -f qcow2 /data/primary/vm/images/debiaen108-1.qcow2 5242880000"
fi
#virt-install --name debian10-1 --memory 2048 --vcpus=2  --os-variant=debian10  --network network=default --graphics=none -v --disk path=/data/primary/vm/images/debiaen108-1.qcow2,size=6 --check disk_size=off --boot hd --location=/home/sefi/debian-10.8.0-s390x-netinst.iso
#virt-install --name debian10-1 --memory 2048 --vcpus=2  --os-variant=debian10  --network network=default --graphics=none -v --disk path=/data/primary/vm/images/debiaen108-1.qcow2,size=6 --check disk_size=off --boot hd --location=/home/sefi/debian-10.8.0-s390x-netinst.iso --extra-args ro 
virt-install --name debian10-1 --memory 2048 --vcpus=2 --os-variant=debian10 --network network=default --graphics none --console pty,target_type=serial -v --disk path=/data/primary/vm/images/debiaen108-1.qcow2,size=6 --check disk_size=off --boot hd --location=/home/sefi/debian-10.8.0-s390x-netinst.iso --extra-args 'console=ttyS0,115200n8 serial'



}
init_vars() {
    init_utils_vars $1 $2
}


main "$@"
