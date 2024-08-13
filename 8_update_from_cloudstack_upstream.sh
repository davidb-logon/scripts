#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# See usage for what this script does.
# TODOs:
set -x
# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

script_ended_ok=false
trap 'cleanup' EXIT

usage() {
cat << EOF
-------------------------------------------------------------------------------
wip
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

main() {
    # Replace logon and template with your own values
    init_vars "logon" "cloudstack"
    parse_command_line_arguments "$@"
    start_logging
    create_upstream_to_apache_cloudstack
    #print_final_messages_to_user
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
    CLOUDSTACK_DIR="/Users/dbarta/wave_cs/git/cloudstack"
    UPSTREAM_REPO="https://github.com/apache/cloudstack.git"
    UPSTREAM_TAG="4.19.1.1"
}

create_upstream_to_apache_cloudstack() {
    cd $CLOUDSTACK_DIR
    git remote remove upstream
    do_cmd "git remote add upstream $UPSTREAM_REPO"
    do_cmd "git fetch upstream"
    do_cmd "git checkout -b ${UPSTREAM_TAG}_original tags/${UPSTREAM_TAG}"
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
