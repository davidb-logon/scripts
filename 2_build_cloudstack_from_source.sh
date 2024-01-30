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
This script builds and installs cloudstack management server and a 
KVM agent on an X86_64 Ubuntu 22.04 machine.

Before running this script, you must have the following:

    1. An Ubuntu machine with enough memeory, disk space and CPU power
    2. The CPU should support the linux KVM module
    3. The CloudStack sources from github present on the machine.

How to run this script:
		
Notes:
    1.  
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

main() {
    init_vars "logon" 
    parse_command_line_arguments "$@"
    start_logging
    install_kvm.sh
    install_maven.sh
    install_python_mkisof_mysql.sh
    install_java.sh
    cd "/home/davidb/logon/cloudstack"
    
    mvn clean install -P developer,systemvm -DskipTests

    #print_final_messages_to_user
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
        return
    fi
    echo -e "$red"
    echo 
    echo "--- SCRIPT WAS UNSUCCESSFUL"
    echo "--- Logfile at: cat $LOGFILE"
    echo "--- End Script"
    echo -e "$reset"
}
    
main "$@"
