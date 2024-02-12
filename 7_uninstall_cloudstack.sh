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
This script uninstalls cloudstack management server and agent from Ubuntu / KVM
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

main() {
    # Replace logon and template with your own values
    init_vars "logon" "uninstall_cloudstack"
    start_logging

    do_cmd "sudo systemctl stop cloudstack-management" "Stopped cloudstack_management service"
    do_cmd "sudo systemctl stop cloudstack-agent" "Stopped cloudstack_agent service"
    do_cmd "sudo apt-get remove --purge cloudstack-management"
    do_cmd "sudo apt-get remove --purge cloudstack-agent"
    do_cmd "sudo apt-get autoremove"
    do_cmd "sudo apt-get autoclean"
    do_cmd "sudo rm -rf /etc/cloudstack"
    do_cmd "sudo rm -rf /usr/share/cloudstack-common"
    do_cmd "sudo rm -rf /usr/share/cloudstack-agent"
    do_cmd "sudo rm -rf /var/log/cloudstack"
    do_cmd "mysql -u cloud -pcloud -e 'DROP DATABASE cloud;'"
    do_cmd "mysql -u cloud -pcloud -e 'DROP DATABASE cloud_usage;'"
    #do_cmd "mysql -u cloud -pcloud -e 'DROP USER cloud@localhost';"

    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}


parse_command_line_arguments() {
    # if [[ $# -lt 1 || $# -gt 2 ]]; then
    #     usage
    #     exit
    # fi
    temp=1
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
