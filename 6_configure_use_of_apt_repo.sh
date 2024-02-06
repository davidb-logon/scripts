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
-------------------------------------------------------------------------------
This script follows the instructions at: 
http://docs.cloudstack.apache.org/en/4.18.1.0/installguide/building_from_source.html#building-deb-packages
and configures apt to install the cloudstack packages
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
    
}

main() {
    init_vars "logon" "cloudstack_add_repo_to_apt"
    start_logging

    REPO_LINE="deb [trusted=yes] http://10.0.0.20:8090/ ./" # Because temporarilt the repo is not signed
    FILE_PATH="/etc/apt/sources.list.d/cloudstack.list"

    # Check if the line exists in the file
    if ! grep -qxF "$REPO_LINE" "$FILE_PATH"; then
        # If the line does not exist, append it to the file
        echo "$REPO_LINE" | sudo tee -a "$FILE_PATH" > /dev/null
        logMessage "The repo 'http://10.0.0.20:8090/ ./' added to $FILE_PATH"
    else
        logMessage "The repo 'http://10.0.0.20:8090/ ./' already exists in $FILE_PATH"
    fi
    do_cmd "sudo apt-get update"
    script_ended_ok=true
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
