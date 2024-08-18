#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

script_ended_ok=false
trap 'cleanup' EXIT

usage() {
cat << EOF
----------------------------------------------------------------------------------
This script builds and installs cloudstack management server and a 
KVM agent on either on an X86_64 Ubuntu 22.04 machine or a Red Hat machine on Z. 
Usage:
    2_build_cloudstack_from_source.sh [cloudstack dir]

if [cloudstack dir] not given, the script will a default /data/cloudstack
----------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

main() {
    echo 
    init_vars "logon" "build_cloudstack"
    start_logging
    parse_command_line_arguments "$@"
    install_kvm.sh
    install_maven.sh
    install_python_mkisof_mysql.sh
    install_java.sh
    start_web_server_on_repo.sh
    cd "$CLOUDSTACK_DIR"
    mvn clean install -P developer,systemvm -DskipTests | tee "$LOGFILE"
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}


parse_command_line_arguments() {
    if [[ $# -lt 1 || $# -gt 2 ]]; then
        usage
        CLOUDSTACK_DIR="/data/cloudstack"
    else
        CLOUDSTACK_DIR=$1
        if ! [ -d "$CLOUDSTACK_DIR" ]; then
            error_exit "Directory $CLOUDSTACK_DIR does not exist"
        fi
    fi
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
