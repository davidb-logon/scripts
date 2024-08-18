#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

main() {
    init_vars "logon" "install_cloudmonkey_and_jq"
    parse_command_line_arguments "$@"
    start_logging
    machine=`uname -p`
    case $machine in
    x86_64)
        do_cmd "sudo wget -O /usr/bin/cmk https://github.com/apache/cloudstack-cloudmonkey/releases/download/6.4.0/cmk.linux.x86-64" "Got cloudmonkey x86-64 binary into /usr/bin"
        do_cmd "sudo chmod +x /usr/bin/cmk" "Made cmk executable"
        do_cmd "hash -d cmk" "Refreshed bash's cache"
        do_cmd "sudo apt-get install jq" "Installed jq, for json processing in bash"
    ;;
    s390x)
        cd /data
        rm -rf /data/cloudstack-cloudmonkey
        git clone https://github.com/apache/cloudstack-cloudmonkey.git
        cd /data/cloudstack-cloudmonkey
        make
        cp bin/cmk /usr/bin/cmk
        do_cmd "hash -d cmk" "Refreshed bash's cache" "INFO: /usr/bin/cmk is in the path"
        do_cmd "sudo apt-get install jq" "Installed jq, for json processing in bash"
    ;;
    esac

    #sudo ln -s /data/cloudstack-cloudmonkey/bin/cmk /usr/bin/cmk
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
