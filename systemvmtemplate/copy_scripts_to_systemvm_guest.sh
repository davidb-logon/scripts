#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# See usage for what this script does.
# TODOs:

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/../lib/common.sh"

script_ended_ok=false
trap 'cleanup' EXIT

usage() {
cat << EOF
-------------------------------------------------------------------------------
run like that:
example:
    copy_scripts_to_systemvm_guest.sh "-P 3922 -i /root/.ssh/systemvm.rsa"  sefi@192.168.124.98
    copy_scripts_to_systemvm_guest.sh " "  sefi@192.168.124.98
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

main() {
    init_vars "logon" "set_cloudbr0_on_rhel_z"
    parse_command_line_arguments "$@"
    start_logging
    check_if_root
    prepare_fresh_systemvm
    run_the_shar
    copy_scripts

    script_ended_ok=true
}

run_the_shar(){
    logMessage "--- Start shar"
    cd /data/cloudstack/tools/appliance
    ./shar_cloud_scripts.sh 2>&1 | tee shar.log
    logMessage "--- End shar"
}

init_vars() {
    init_utils_vars $1 $2
    # Set variables for the service offering


}
parse_command_line_arguments() {
    # if [[ $# -lt 1 || $# -gt 2 ]]; then
    #     usage
    #     exit
    # fi

    SCP_PARAMS="$1"
    #SCP_PARAMS="-P 3922 -i /root/.ssh/systemvm.rsa"
    USER_AT_HOST="$2"
    #USER_AT_HOST="sefi@192.168.124.3"

    #temp=1
}
function wait_for_vm_ip() {
    local vm_name="$1"
    ip_info=""

    echo "Waiting for VM $vm_name to get a non-loopback IP (ignoring 127.0.0.1)..."

    # Loop until the VM gets a non-loopback IP address
    while true; do
        # Get IP addresses associated with the VM and filter out 127.0.0.1
        ip_info=$(virsh domifaddr "$vm_name" --source agent 2>/dev/null | grep ipv4 | grep -v '127.0.0.1' | awk '{print $4}' | cut -d'/' -f1)

        # If a non-loopback IP is found, print it and break the loop
        if [ -n "$ip_info" ]; then
            echo "VM: $vm_name, IP: $ip_info"
            break
        fi

        # Sleep for 1 second before checking again
        sleep 1
    done
}

prepare_fresh_systemvm() {
    logMessage "First copy deb11-1 to systemvm guest deb11-systemvm "
    do_cmd "virsh destroy deb11-1" "" "INFO: Vm deb11-1 is stopped"
    do_cmd "virsh destroy deb11-systemvm" "" "INFO: Vm deb11-systemvm is stopped"
    do_cmd "virsh undefine deb11-systemvm --remove-all-storage"  "" "INFO: Vm deb11-systemvm is erased"
    do_cmd "virt-clone --original deb11-1  --name deb11-systemvm --auto-clone"
    do_cmd "virsh net-start default" "" "INFO: Network already active"
    do_cmd "virsh start deb11-systemvm"
    # Wait until systemvm is up
    wait_for_vm_ip "deb11-systemvm"
    logMessage "First copy deb11-1 to systemvm guest deb11-systemvm DONE"
    logMessage "VM: $vm_name, IP: $ip_info"
    SCP_PARAMS=" -o StrictHostKeyChecking=no "
    #SCP_PARAMS="-P 3922 -i /root/.ssh/systemvm.rsa"
    USER_AT_HOST="sefi@$ip_info"

}

copy_scripts() {
    SCP_PARAMS=" -o StrictHostKeyChecking=no "
    logMessage "copying scripts to systemvm [$SCP_PARAMS][$USER_AT_HOST]"
    SSH_PARAMS="${SCP_PARAMS/-P/-p}"
    #do_cmd "ssh-copy-id $USER_AT_HOST"
    do_cmd "ssh $SSH_PARAMS $USER_AT_HOST mkdir -p scripts"
    do_cmd "ssh $SSH_PARAMS $USER_AT_HOST mkdir -p lib"
    do_cmd "scp $SCP_PARAMS /data/scripts/lib/common.sh $USER_AT_HOST:lib/."
    # copy the files after running the create_shar_archive.sh script from the cloudstack source folder to the systemvm guest
    do_cmd "scp $SCP_PARAMS /data/cloudstack/tools/appliance/cloud_scripts_shar_archive.sh $USER_AT_HOST:."
    do_cmd "scp $SCP_PARAMS /data/cloudstack/tools/appliance/systemvmtemplate/scripts/*.sh $USER_AT_HOST:scripts"
    # do_cmd "scp $SCP_PARAMS /data/scripts/systemvmtemplate/things_todo_on_systemvm_right_after_install.sh $USER_AT_HOST:."
    do_cmd "scp $SCP_PARAMS /data/scripts/systemvmtemplate/exec_scripts_for_svm.sh $USER_AT_HOST:."
    do_cmd "ssh $SSH_PARAMS $USER_AT_HOST chmod +x scripts/* cloud_scripts_shar_archive.sh exec_scripts_for_svm.sh scripts/install_systemvm_packages_s390x.sh"
    # do_cmd "ssh $SSH_PARAMS $USER_AT_HOST nohup sudo bash -c './exec_scripts_for_svm.sh'"
    #hostnamectl --static set-hostname deb390-4
}

main "$@"
