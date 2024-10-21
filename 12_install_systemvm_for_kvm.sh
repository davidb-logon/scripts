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
    if [ "$USE_X86_TEMPLATE" = true ]; then
        verify_all_stopped
        register_template
    else
        extract_template_from_vm
        prepare_repo
        verify_all_stopped
        register_template
    fi

    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
    SCRIPT_PATH="/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt"
    DOMAIN="deb11-systemvm"
    USE_X86_TEMPLATE=true # If doing x86, we download the zipped temlate from cloudstack repo
    REPO_PATH="http://localhost:8090/"

}

extract_template_from_vm() {
    logMessage "Start extract and zip template from vm $DOMAIN"
    do_cmd "virsh destroy $DOMAIN" "" "INFO: Vm with Domain is stopped"
    sleep 3
    FILE_PATH=$(virsh dumpxml $DOMAIN | grep 'source file' |  grep -oP "file='\K[^']+")
    logMessage "FILE PATH: $FILE_PATH"
    # logMessage "The next step will take about 2-3 minutes..."
    # do_cmd "bzip2 -k --force $FILE_PATH"
    # logMessage "End extract and zip template from vm $DOMAIN"
}

prepare_repo() {
    logMessage "Start prepare repo"
    # do_cmd "mv ${FILE_PATH}.bz2 /data/repo/"
    do_cmd "cp ${FILE_PATH} /data/repo/"
    start_web_server_on_repo.sh
     logMessage "End prepare repo"
}
get_version() {
    LAST_VERSION=$( mysql -D cloud -e "select url from cloud.vm_template where type = 'SYSTEM' and hypervisor_type = 'KVM'" | awk -Fversion= '{print $2}' | tail -n 1)
    VERSION=$((LAST_VERSION+1))
     logMessage "Last version: $LAST_VERSION, new version: $VERSION"
}
register_template() {
    if [ "$USE_X86_TEMPLATE" = true ]; then
        logMessage "Start register x86 template using:"
        URL="http://download.cloudstack.org/systemvm/4.19/systemvmtemplate-4.19.1-kvm.qcow2.bz2"
        logMessage "URL: $URL"
        do_cmd "$SCRIPT_PATH -m /data/mainframe_secondary -u $URL -h kvm -F"
    else
        logMessage "Start register s390x template using:"
        SVM_PATH=${REPO_PATH}$(basename $FILE_PATH)
        logMessage "SVM PATH: $SVM_PATH"
        get_version
        # do_cmd "$SCRIPT_PATH -m /data/mainframe_secondary -u ${SVM_PATH}.bz2 -h kvm -F"
        do_cmd "$SCRIPT_PATH -m /data/mainframe_secondary -u ${SVM_PATH}?date=$(date +"%Y%m%d%H%M%S")\&version=$VERSION -h kvm -F"
    fi

    do_cmd "restart"
    logMessage "End register template"
}

verify_all_stopped(){
    #vm_name=$(mysql -D cloud -se "SELECT name FROM vm_instance WHERE state='Starting';")
    vm_name=$(mysql -D cloud -se "SELECT name FROM vm_instance WHERE type='SecondaryStorageVm' or type ='ConsoleProxy';")

    # Loop through each VM name and update its state to 'Stopped'
    for vm in $vm_name; do
        # Print the update statement and execute it
        echo "Updating VM: $vm"
        mysql -D cloud -e "UPDATE vm_instance SET state = 'Stopped' WHERE name = '$vm';"
        virsh destroy $vm
    done

}
main $@