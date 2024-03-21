#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

main() {
    start_time=$(date +%s)
    usage
    init_vars "logon" "cloudstack"
    parse_command_line_arguments "$@"
    start_logging

    # Insert script logic here
    cd /home/davidb/openvpn-ca
    ./easyrsa build-client-full zvm nopass
    cd
    mkdir ovpn-zvm
    cd ovpn-zvm
    cp /home/davidb/openvpn-ca/ta.key .
    cp /home/davidb/openvpn-ca/pki/ca.crt .
    cp /home/davidb/openvpn-ca/pki/private/zvm.key .
    cp /home/davidb/openvpn-ca/pki/issued/zvm.crt .
    cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf zvm.ovpn
    sed -i 's/cert client.crt/cert zvm.crt/g' zvm.ovpn
    sed -i 's/key client.key/key zvm.key/g' zvm.ovpn
    sed -i 's/remote my-server-1/remote 84.95.45.250/g' zvm.ovpn
    zip zvm.ovpn.zip zvm.ovpn ta.key ca.crt zvm.key zvm.crt 
    

    #on the s390 machine

     sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
     yum search openvpn
     dnf install openvpn
     mkdir /root/openvpn
     
     cd /root/openvpn
     unzip ../zvm.ovpn.zip 
     sudo openvpn  --config zvm.ovpn 

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

#-------------------------------------------------------#
#                Start script execution                 #
#-------------------------------------------------------#

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

script_ended_ok=false
trap 'cleanup' EXIT

main "$@"
