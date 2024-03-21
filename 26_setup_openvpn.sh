#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

main() {
    start_time=$(date +%s)
    usage
    init_vars "logon" "setup_openvpn"
    start_logging

    parse_command_line_arguments "$@" # Get the clients,
    install_openvpn_and_easy_rsa
    setup_CA_certificate
    generate_server_certificate_and_key
    generate_Diffie_Hellman_key_and_HMAC_signature


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

install_openvpn_and_easy_rsa() {
    logMessage "--- Start installing openvpn and easy-rsa"
    do_cmd "sudo apt update && sudo apt upgrade -y"
    do_cmd "sudo apt install openvpn easy-rsa -y"
    logMessage "--- End installing openvpn and easy-rsa"
}

setup_CA_certificate() {
    logMessage "--- Start setting up the CA certificate"
    # Set up Easy-RSA directory
    do_cmd "make-cadir ~/openvpn-ca" "Created cadir" "INFO: Unable to create ca_dir"
    cd ~/openvpn-ca
    init_RSA_vars

    # Initialize and build CA
    do_cmd "./easyrsa init-pki"
    do_cmd "echo 'CA' | ./easyrsa build-ca nopass"

    # Copy the CA certificate to the OpenVPN directory
    do_cmd "sudo cp pki/ca.crt /etc/openvpn/"
    logMessage "--- End setting up the CA certificate, at: /etc/openvpn/ca.crt"
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

generate_server_certificate_and_key() {
    logMessage "--- Start generating server certificate and key"
    # Generate server certificate and key
    do_cmd "./easyrsa gen-req server nopass"
    do_cmd "sudo cp pki/private/server.key /etc/openvpn/"

./easyrsa sign-req server server <<EOF
yes
EOF

    # Copy the server certificate to the OpenVPN directory
    do_cmd "sudo cp pki/issued/server.crt /etc/openvpn/"
    logMessage "--- End generating server certificate and key, at: /etc/openvpn/server.crt"
}


generate_Diffie_Hellman_key_and_HMAC_signature() {
    logMessage "--- Start generating Diffie Hellman key and HMAC signature"
    
    # Generate Diffie-Hellman key and HMAC signature
    do_cmd "./easyrsa gen-dh"
    do_cmd "openvpn --genkey --secret ta.key"

    # Move them to the OpenVPN directory
    do_cmd "sudo cp ta.key /etc/openvpn/"
    do_cmd "sudo cp pki/dh.pem /etc/openvpn/dh2048.pem"
    logMessage "--- End generating Diffie Hellman key and HMAC signature, at: /etc/openvpn/ta.key and dh2048.pem"
}


parse_command_line_arguments() {
    CLIENTS=("$@") # Get them as an array
    NUM_CLIENTS=${#clients[@]}

    if [ NUM_CLIENTS -eq 0 ]; then
        message="No clients names provided on command line, none will be assigned fixed ips."
        logMessage $message
        confirm "${message} Continue?" || exit 1
    else
        logMessage "The following clients will be configured: ${clients[*]}"
    fi
}

usage() {
cat << EOF
----------------------------------------------------------------------------------
This script sets up an openvpn server on ubuntu, and if given a list
of client names it will prepare the necessary files for each client
to setup the client side.
Each client name has the format of ssss:nn.nn.nn.nn where the sss is the name
and nn... is the desired ip address to be assigned.
----------------------------------------------------------------------------------
EOF
script_ended_ok=true
}
function setup_ovpn_client_as_service(){
#    
#/etc/systemd/system/openvpn@client.service (replace client with your specific client name if needed). Use a text editor like nano to edit the file.
#
#Add the following content to the file, replacing placeholders with your actual details:
#
clientName="zvm"
cat << EOF > /etc/systemd/system/openvpn@client.service
[Unit]
Description=OpenVPN Client Service - $clientName
After=network.target

[Service]
Type=simple
Restart=on-failure
ExecStart=/usr/sbin/openvpn --config /root/openvpn/$clientName.ovpn
User=nobody  # Adjust user privileges if needed
Group=nogroup # Adjust group privileges if needed

[Install]
WantedBy=multi-user.target
EOF

do_cmd "sudo systemctl daemon-reload"
do_cmd "sudo systemctl enable openvpn@client.service"

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
