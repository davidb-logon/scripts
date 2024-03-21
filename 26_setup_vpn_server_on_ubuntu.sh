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

    # Update System
    do_cmd "sudo apt update && sudo apt upgrade -y"

    # Install OpenVPN and Easy-RSA
    do_cmd "sudo apt install openvpn easy-rsa -y"

    # Set up Easy-RSA directory
    do_cmd "make-cadir ~/openvpn-ca" "Created cadir" "INFO: Unable to create ca_dir"
    cd ~/openvpn-ca
    init_RSA_vars

    # Initialize and build CA
    do_cmd "./easyrsa init-pki"
    do_cmd "echo 'CA' | ./easyrsa build-ca nopass"

    # Copy the CA certificate to the OpenVPN directory
    do_cmd "sudo cp pki/ca.crt /etc/openvpn/"

    # Generate server certificate and key
    do_cmd "./easyrsa gen-req server nopass"
    do_cmd "sudo cp pki/private/server.key /etc/openvpn/"

./easyrsa sign-req server server <<EOF
yes
EOF

    # Copy the server certificate to the OpenVPN directory
    do_cmd "sudo cp pki/issued/server.crt /etc/openvpn/"

    # Generate Diffie-Hellman key and HMAC signature
    do_cmd "./easyrsa gen-dh"
    do_cmd "openvpn --genkey --secret ta.key"

    # Move them to the OpenVPN directory
    do_cmd "sudo cp ta.key /etc/openvpn/"
    do_cmd "sudo cp pki/dh.pem /etc/openvpn/dh2048.pem"
    do_cmd "sudo mkdir /etc/openvpn/ccd"


    # Configure OpenVPN Server
    do_cmd "sudo cp -p /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/server.conf"
    do_cmd "sudo sed -i 's/;tls-auth ta.key 0/tls-auth ta.key 0/' /etc/openvpn/server.conf"
    do_cmd "sudo sed -i 's/;cipher AES-256-CBC/cipher AES-256-CBC/' /etc/openvpn/server.conf"
    do_cmd "sudo sed -i 's/;user nobody/user nobody/' /etc/openvpn/server.conf"
    do_cmd "sudo sed -i 's/;group nogroup/group nogroup/' /etc/openvpn/server.conf"
    do_cmd "sudo sed -i 's/;client-to-client/client-to-client/' /etc/openvpn/server.conf"


    # To address the issues seen in "sudo journalctl -u openvpn@server", add the following to server.conf:
    # topology subnet
    # data-ciphers AES-256-GCM:AES-128-GCM:AES-256-CBC



    # Enable IP Forwarding
    do_cmd "sudo sed -i '/net.ipv4.ip_forward=1/s/^#//g' /etc/sysctl.conf"
    do_cmd "sudo sysctl -p"

    # Start and Enable OpenVPN
    do_cmd "sudo systemctl start openvpn@server"
    do_cmd "sudo systemctl enable openvpn@server"

    logMessage "OpenVPN setup is complete. Review the configuration and adjust firewall settings accordingly."

    
    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    logMessage "The script took $elapsed_time seconds to complete."
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2

}

init_RSA_vars() {
    # Configuring Easy-RSA vars
    # Update these vars according to your organization's details.
cat > vars <<EOF
set_var EASYRSA_REQ_COUNTRY    "IL"
set_var EASYRSA_REQ_PROVINCE   "Galillee"
set_var EASYRSA_REQ_CITY       "Kfar Vradim"
set_var EASYRSA_REQ_ORG        "odeca"
set_var EASYRSA_REQ_EMAIL      "david@odeca.net"
set_var EASYRSA_REQ_OU         "wave"
set_var EASYRSA_KEY_SIZE       2048
set_var EASYRSA_ALGO           rsa
set_var EASYRSA_CA_EXPIRE      7500
set_var EASYRSA_CERT_EXPIRE    365
set_var EASYRSA_NS_SUPPORT     "no"
set_var EASYRSA_NS_COMMENT     "OpenVPN Certificate"
set_var EASYRSA_EXT_DIR        "\${EASYRSA}/x509-types"
set_var EASYRSA_SSL_CONF       "\${EASYRSA}/openssl-easyrsa.cnf"
set_var EASYRSA_DIGEST         "sha256"
EOF    
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
