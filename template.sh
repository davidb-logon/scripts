#!/bin/bash

#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

script_ended_ok=false
trap 'cleanup' EXIT

main() {
    start_time=$(date +%s)
    usage
    init_vars "logon" "cloudstack"
    parse_command_line_arguments "$@"
    start_logging

    # Insert script logic here
    
    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    logMessage "The script took $elapsed_time seconds to complete."
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

usage() {
cat << EOF
-------------------------------------------------------------------------------
This script 
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

main "$@"
