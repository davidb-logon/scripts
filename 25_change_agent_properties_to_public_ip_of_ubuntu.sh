#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

main() {
    usage
    init_vars "logon" "change_aget_properties"
    #parse_command_line_arguments "$@"
    start_logging
    edit_agent_properties
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}

edit_agent_properties() {
    

    # Define the file path
    FILE="/etc/cloudstack/agent/agent.properties"

    # Check if the file exists
    if [ ! -f "$FILE" ]; then
        logMessage "The file $FILE does not exist." >&2
        exit 1
    fi

    # Update the line starting with 'host='
    sudo chattr -i "$FILE"

    sudo sed -i 's/^host=.*/host=84.95.45.250/' "$FILE"

    sudo chattr +i "$FILE"


    logMessage "The file has been updated and immutable attribute set."

}


usage() {
cat << EOF
-------------------------------------------------------------------------------
This script changes the agent.properties file to the public ip of ubuntu
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

#-------------------------------------------------------#
#                Start script execution                 #
#-------------------------------------------------------#

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

script_ended_ok=false
trap 'cleanup' EXIT

main "$@"
