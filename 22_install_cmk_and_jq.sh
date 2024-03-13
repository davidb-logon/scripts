#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

main() {
    init_vars "logon" "install_cloudmonkey_and_jq"
    parse_command_line_arguments "$@"
    start_logging
    do_cmd "sudo wget -O /usr/bin/cmk https://github.com/apache/cloudstack-cloudmonkey/releases/download/6.3.0/cmk.linux.x86-64" "Got cloudmonkey x86-64 binary into /usr/bin"
    do_cmd "sudo chmod +x /usr/bin/cmk" "Made cmk executable"
    do_cmd "hash -d cmk" "Refreshed bash's cache"
    do_cmd "sudo apt-get install jq" "Installed jq, for json processing in bash"
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}


usage() {
cat << EOF
-------------------------------------------------------------------------------
This script 
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
