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
    copy_scripts_to_systemvm_guest.sh "-P 3922 -i /root/.ssh/systemvm.rsa"  sefi@192.168.124.171
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

main() {
    init_vars "logon" "set_cloudbr0_on_rhel_z"
    parse_command_line_arguments "$@"
    start_logging
    check_if_root

    copy_scripts
    
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
    # Set variables for the service offering


}
parse_command_line_arguments() {
    if [[ $# -lt 1 || $# -gt 2 ]]; then
        usage
        exit
    fi

    SCP_PARAMS="$1"
    #SCP_PARAMS="-P 3922 -i /root/.ssh/systemvm.rsa"
    USER_AT_HOST="$2"
    #USER_AT_HOST="sefi@192.168.124.3"

    #temp=1
}

copy_scripts() {
    # copy the files after running the create_shar_archive.sh script from the cloudstack source folder to the systemvm guest
    do_cmd "scp $SCP_PARAMS /data/cloudstack/tools/appliance/cloud_scripts_shar_archive.sh $USER_AT_HOST:."
    do_cmd "scp $SCP_PARAMS /data/scripts/systemvmtemplate/scripts/*.sh $USER_AT_HOST:scripts"
    do_cmd "scp $SCP_PARAMS /data/scripts/exec_scripts_for_svm.sh $USER_AT_HOST:."
}

main "$@"
