#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# Source script libraries as needed.

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
    cd $srcdir
    $EASYRSA_CMD build-client-full zvm nopass
    cd
    mkdir -p ovpn-zvm
    cd ovpn-zvm
    cp $srcdir/ta.key .
    cp $srcdir/pki/ca.crt .
    cp $srcdir/pki/private/zvm.key .
    cp $srcdir/pki/issued/zvm.crt .
     case "$LINUX_DISTRIBUTION" in
            "UBUNTU")
                cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf zvm.ovpn
                ;;
            "RHEL")
                cp /usr/share/doc/openvpn/sample/sample-config-files/client.conf zvm.ovpn
                ;;
            *)
                error_exit "Unknown or Unsupported LINUX_DISTRIBUTION: $LINUX_DISTRIBUTION, exiting"
                ;;
        esac 
    logMessage ">>>Now generating for clients $CLIENTS"       
    for i in  ${CLIENTS[*]} ;do
            echo "Now generating for client $i"
            generate_certifiate_for_client "$i"
    done

    
    # sed -i 's/cert client.crt/cert zvm.crt/g' zvm.ovpn
    # sed -i 's/key client.key/key zvm.key/g' zvm.ovpn
    # sed -i 's/remote my-server-1/remote 84.95.45.250/g' zvm.ovpn
    # zip zvm.ovpn.zip zvm.ovpn ta.key ca.crt zvm.key zvm.crt 
    

    #on the s390 machine
    
    #  sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
    #  yum search openvpn
    #  dnf install openvpn
    #  mkdir /root/openvpn
     
    #  cd /root/openvpn
    #  unzip ../zvm.ovpn.zip 
    #  sudo openvpn  --config zvm.ovpn 

    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    logMessage "The script took $elapsed_time seconds to complete."
    script_ended_ok=true
}

generate_certifiate_for_client() {
    # This function in this snippet is a shell script function that generates a certificate for a client
    # in an OpenVPN setup. It sets up the necessary directories, copies the required files, and updates 
    # the OpenVPN configuration file with client-specific details before creating a zip file containing the 
    # client's configuration.
    client="$1"

    logMessage "--- Start generating certificate for client: $client"
    do_cmd "mkdir -p $srcdir"
    cd "$srcdir"
    do_cmd "path_easyrsa=$(find /usr/share/easy-rsa/ | grep easyrsa | grep -v cnf)"
    do_cmd "$path_easyrsa gen-req $client nopass"
    do_cmd "mkdir -p ~/ovpn-$client"
    do_cmd "cp ${srcdir}/pki/private/$client.key ~/ovpn-$client"
    do_cmd "cp ${srcdir}/pki/issued/$client.crt ~/ovpn-$client"
    do_cmd "cp ${srcdir}/ta.key ~/ovpn-$client/."
    do_cmd "cp ${srcdir}/pki/ca.crt ~/ovpn-$client/."
    do_cmd "cp $CLIENT_CONF ~/ovpn-$client/$client.ovpn"
    cd ~/ovpn-$client
    do_cmd "chown $USER:$USER *"
    do_cmd "sed -i 's/cert client.crt/cert $client.crt/g' $client.ovpn"
    do_cmd "sed -i 's/key client.key/key $client.key/g' $client.ovpn"
    do_cmd "sed -i 's/remote my-server-1/remote $vpnserver/g' $client.ovpn"
    do_cmd "zip $client.ovpn.zip $client.ovpn $client.key $client.crt ca.crt ta.key"
    logMessage "$client.ovpn.zip"
}


init_vars() {
    init_utils_vars $1 $2
    detect_linux_distribution
    start_time=$(date +%s)
    vpnserver="204.90.115.226"
    srcdir="/root/openvpn-ca"
    case "$LINUX_DISTRIBUTION" in
            "UBUNTU")
                EASYRSA_CMD="./easyrsa"
                SERVER_CONF="/usr/share/doc/openvpn/examples/sample-config-files/server.conf"
                CLIENT_CONF="/usr/share/doc/openvpn/examples/sample-config-files/client.conf"
                ;;
            "RHEL")
                EASYRSA_CMD="easyrsa"
                SERVER_CONF="/usr/share/doc/openvpn/sample/sample-config-files/server.conf"
                CLIENT_CONF="/usr/share/doc/openvpn/sample/sample-config-files/client.conf"
                ;;
            *)
                error_exit "Unknown or Unsupported LINUX_DISTRIBUTION: $LINUX_DISTRIBUTION, exiting"
                ;;
        esac    
}

parse_command_line_arguments() {
    CLIENTS=("$@") # Get them as an array
    logMessage "The following clients will be configured: ${CLIENTS[*]}"
    NUM_CLIENTS=${#CLIENTS[*]}

    if [ "$NUM_CLIENTS" -eq 0 ]; then
        message="No clients names provided on command line, none will be assigned fixed ips."
        logMessage $message
        usage
        confirm "${message} Continue?" || exit 1
    else
        logMessage "The following clients will be configured: ${CLIENTS[*]}"
    fi
}


usage() {
cat << EOF
-------------------------------------------------------------------------------
This script generate a client certificate for an OpenVPN server on Ubuntu and RHEL
Each client name has the format of ssss:nn.nn.nn.nn where the sss is the name
usage: 27_setup_openvpn_client.sh [client_name1 client_name2 client_name1]
example:27_setup_openvpn_client.sh zvm sefi davidb
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

#-------------------------------------------------------#
#                Start script execution                 #
#-------------------------------------------------------#



main "$@"
