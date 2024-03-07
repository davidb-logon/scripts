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

    do_cmd "sudo systemctl stop cloudstack-management" "Stopped cloudstack_management service" "INFO:could not stop service"
    do_cmd "sudo systemctl stop cloudstack-agent" "Stopped cloudstack_agent service"
    do_cmd "sudo yum remove cloudstack-management"
    do_cmd "sudo yum remove cloudstack-agent"
    do_cmd "sudo yum autoremove"
    do_cmd "sudo yum clean all"
    do_cmd "sudo rm -rf /etc/cloudstack"
    do_cmd "sudo rm -rf /usr/share/cloudstack-common"
    do_cmd "sudo rm -rf /usr/share/cloudstack-agent"
    do_cmd "sudo rm -rf /var/log/cloudstack"
    do_cmd "mysql -u cloud -pcloud -e 'DROP DATABASE cloud;'"
    do_cmd "mysql -u cloud -pcloud -e 'DROP DATABASE cloud_usage;'"
    sudo rpm -e cloudstack-common-4.18.0.0-1.x86_64
    #do_cmd "mysql -u cloud -pcloud -e 'DROP USER cloud@localhost';"

    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}
  
main "$@"
