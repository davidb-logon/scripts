#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

script_ended_ok=false
trap 'cleanup' EXIT

usage() {
cat << EOF
-------------------------------------------------------------------------------
Prepare and register a system vm template for cloudstack
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

main() {
    #set -x
    init_vars "logon" "install_systemvm"
    start_logging
    check_if_root
    extract_template_from_vm
    prepare_repo
    verify_all_stopped
    register_template
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
    SCRIPT_PATH="/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt"
    DOMAIN="deb390-12-4"
    REPO_PATH="http://localhost:8090/" 
}

extract_template_from_vm() {
    logMessage "Start extract and zip template from vm $DOMAIN"
    do_cmd "virsh destroy $DOMAIN" "" "INFO: Vm with Domain is stopped"
    sleep 3
    FILE_PATH=$(virsh dumpxml $DOMAIN | grep 'source file' |  grep -oP "file='\K[^']+")
    logMessage "FILE PATH: $FILE_PATH"
    logMessage "The next step will take about 2-3 minutes..."
    do_cmd "bzip2 -k --force $FILE_PATH"
    logMessage "End extract and zip template from vm $DOMAIN"
}

prepare_repo() {
    logMessage "Start prepare repo"
    do_cmd "mv ${FILE_PATH}.bz2 /data/repo/"
    start_web_server_on_repo.sh
     logMessage "End prepare repo"
}
register_template() {
    logMessage "Start register template using"
    SVM_PATH=${REPO_PATH}$(basename $FILE_PATH)
    logMessage "SVM PATH: $SVM_PATH"
    do_cmd "$SCRIPT_PATH -m /data/mainframe_secondary -u ${SVM_PATH}.bz2 -h kvm -F"
    do_cmd "systemctl restart cloudstack-management"
    logMessage "End register template"
}

verify_all_stopped(){
    vm_name=$(mysql -D cloud -se "SELECT name FROM vm_instance WHERE state='Starting';")

    # Loop through each VM name and update its state to 'Stopped'
    for vm in $vm_name; do
        # Print the update statement and execute it
        echo "Updating VM: $vm"
        mysql -D cloud -e "UPDATE vm_instance SET state = 'Stopped' WHERE name = '$vm';"
        virsh destroy $vm
    done 

}
main $@