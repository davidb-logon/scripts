#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
mount_repo() {
    logMessage "--- Start mounting repo"
    case "$LINUX_DISTRIBUTION" in
        "UBUNTU")
            logMessage "--- No need to mount Ubuntu repository"
            ;;
        "RHEL")
            logMessage "--- Mounting RHEL repository"
            do_cmd "sudo mkdir -p /mnt/iso"  
            do_cmd "sudo mkdir -p /mnt/linuxu"
            do_cmd "sudo mount -t nfs 54.227.191.101:/iso /mnt/iso" "Mounted" "INFO: Already Mounted"
            do_cmd "sudo mount -t nfs 54.227.191.101:/linuxu /mnt/linuxu" "Mounted" "INFO: Already Mounted"
            do_cmd "sudo mount -o loop /mnt/iso/rhel/rhel-baseos-9.1-s390x-dvd.iso /mnt/rhel91/BaseOs" "Mounted" "INFO: Already Mounted"
            ;;
        *)
            logMessage "ERROR:--- Unsupported LINUX_DISTRIBUTION: $LINUX_DISTRIBUTION, exiting"
            exit 1
            ;;
    esac
    logMessage "--- End mounting repo"
}

main() {
    start_time=$(date +%s)
    usage
    init_utils_vars "logon" "setup_openvpn"
    start_logging
    #parse_command_line_arguments "$@" # Get the clients
    detect_linux_distribution # Sets a global: $LINUX_DISTRIBUTION
    exit_if_unsupported_distribution
    init_vars # Sets up linux specific variables according to distribution
    mount_repo # Mount the repository
    
    # Print the contents of the arrays
    echo "Array 1:"
    for item in "${array1[@]}"; do
    echo "$item"
    done
#PS4='${BASH_SOURCE}:$LINENO + '
#set -x

    echo "Array 2:"
    for item in "${array2[@]}"; do
    echo "$item"
    done

echo here: ${array1[0]} ${array2[0]}


# Length of the array
length=${#array1[@]}

# Iterate from 0 to the length of the array
for ((i = 0; i < length; i++)); do
    echo "Client $i: ${array1[i]} ${array2[i]}"
    
    echo "ifconfig-push ${array2[i]} $GATEWAY_IP" | sudo tee $SERVER_WORKING_DIR/ccd/"${array1[i]}"
    generate_certifiate_for_client "${array1[i]}"
done



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
    vpnserver=$VPNSERVER
    srcdir="/home/davidb/openvpn-ca"
    logMessage "--- Start generating certificate for client: $client"
    # PS4='${BASH_SOURCE}:$LINENO + '
    # set -x

    cd /home/davidb/openvpn-ca
    
    do_cmd "path_easyrsa=$(sudo find /usr/share/easy-rsa/ | grep easyrsa | grep -v cnf)"
    do_cmd "sudo rm -f ${srcdir}/pki/reqs/$client.req"
    do_cmd "sudo rm -f ${srcdir}/pki/private/$client.key"
    do_cmd "sudo rm -f ${srcdir}/pki/issued/$client.crt"
    do_cmd "sudo $path_easyrsa --batch build-client-full $client nopass"
    do_cmd "mkdir -p ~/ovpn-$client"
    do_cmd "sudo cp -f ${srcdir}/pki/private/$client.key ~/ovpn-$client"
    do_cmd "sudo cp -f ${srcdir}/pki/issued/$client.crt ~/ovpn-$client"
    do_cmd "sudo cp -f ${srcdir}/ta.key ~/ovpn-$client/."
    do_cmd "sudo cp -f ${srcdir}/pki/ca.crt ~/ovpn-$client/."
    do_cmd "CLIENT_CONF=$(sudo find /usr/share/doc/openvpn/ | grep /client.conf)"
    do_cmd "sudo cp -f ${CLIENT_CONF} ~/ovpn-$client/$client.ovpn"
    cd ~/ovpn-$client
    do_cmd "sudo chown $USER:$USER *"
    do_cmd "sed -i 's/cert client.crt/cert $client.crt/g' $client.ovpn"
    do_cmd "sed -i 's/key client.key/key $client.key/g' $client.ovpn"
    do_cmd "sed -i 's/remote my-server-1/remote $vpnserver/g' $client.ovpn"
    do_cmd "zip $client.ovpn.zip $client.ovpn $client.key $client.crt ca.crt ta.key"
}


init_vars() {
    CA_DIR="/home/davidb/openvpn-ca"
    case "$LINUX_DISTRIBUTION" in
        "UBUNTU")
            INSTALL_CMD="apt"
            SERVER_WORKING_DIR="/etc/openvpn/"
            SERVICE_NAME="openvpn@server.service"
            SUBNET_IP="192.168.123.0"
            GATEWAY_IP="192.168.123.1"
            VPNSERVER="84.95.45.250"                     
            array1=()
            array2=()

            # Read from a here-document
            while read -r element1 element2; do
            array1+=("$element1")
            array2+=("$element2")
            done << EOF
sefimini 192.168.123.4
sefiw    192.168.123.5
ubdudi   192.168.123.6
dudimac  192.168.123.3
sharon   192.168.123.7
davidb   192.168.123.8
EOF

            ;;
        "RHEL")
            INSTALL_CMD="yum"
            SERVER_WORKING_DIR="/etc/openvpn/server/"
            SERVICE_NAME="openvpn@server.service"
            SUBNET_IP="192.168.123.0"
            GATEWAY_IP="192.168.123.1"
            VPNSERVER="84.95.45.250"                     
            array1=()
            array2=()

            # Read from a here-document
            while read -r element1 element2; do
            array1+=("$element1")
            array2+=("$element2")
            done << EOF
sefimini 192.168.123.4
sefiw    192.168.123.5
ubdudi   192.168.123.6
dudimac  192.168.123.3
sharon   192.168.123.7
davidb   192.168.123.8
EOF

            ;;        
        *)
            logMessage "Unknown or unsupported LINUX_DISTRIBUTION: $LINUX_DISTRIBUTION, exiting"
            exit 1
            ;;
    esac
}    

install_openvpn_and_easy_rsa() {
    logMessage "--- Start installing openvpn and easy-rsa"
    do_cmd "sudo $INSTALL_CMD update -y && sudo $INSTALL_CMD upgrade -y"
    do_cmd "sudo $INSTALL_CMD install openvpn easy-rsa -y"
    logMessage "--- End installing openvpn and easy-rsa"
}

setup_easyrsa_dir() {
    logMessage "--- Start setting up Easy RSA directory"
    case "$LINUX_DISTRIBUTION" in
        "UBUNTU")
            do_cmd "sudo make-cadir $CA_DIR" "Created $CA_DIR" "INFO:Unable to create $CA_DIR"
            ;;
        "RHEL")
            do_cmd "sudo mkdir -p $CA_DIR"
            #TODO: need to change to ln -s
            do_cmd "sudo cp -r /usr/share/easy-rsa/3.1.6/* $CA_DIR/"
            ;;        
        *)
            logMessage "Unknown or unsupported LINUX_DISTRIBUTION: $LINUX_DISTRIBUTION, exiting"
            exit 1
            ;;
    esac
    cd "$CA_DIR"
    
    init_RSA_vars
    logMessage "--- End setting up Easy RSA directory"
}

setup_CA_certificate() {
    logMessage "--- Start setting up the CA certificate at: $(pwd)"
    setup_easyrsa_dir
    logMessage "--- Current dir is: $(pwd)"
    # Initialize and build CA
    do_cmd "echo -e 'yes\nyes\n' | sudo ./easyrsa init-pki --vars=vars"
    do_cmd "echo 'CA' | sudo ./easyrsa build-ca nopass"

    # Copy the CA certificate to the OpenVPN directory
    do_cmd "sudo cp pki/ca.crt $SERVER_WORKING_DIR"
    logMessage "--- End setting up the CA certificate, at: $SERVER_WORKING_DIR/ca.crt"
}

init_RSA_vars() {
    # Configuring Easy-RSA vars
    # Update these vars according to your organization's details.
cat <<EOF | sudo tee pki/vars
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
    do_cmd "echo yes\nyes | sudo ./easyrsa gen-req server nopass"
    do_cmd "sudo cp pki/private/server.key $SERVER_WORKING_DIR"

sudo ./easyrsa sign-req server server <<EOF
yes
EOF

    # Copy the server certificate to the OpenVPN directory
    do_cmd "sudo cp pki/issued/server.crt $SERVER_WORKING_DIR/"
    logMessage "--- End generating server certificate and key, at: $SERVER_WORKING_DIR/server.crt"
}

generate_Diffie_Hellman_key_and_HMAC_signature() {
    logMessage "--- Start generating Diffie Hellman key and HMAC signature"
    
    # Generate Diffie-Hellman key and HMAC signature
    do_cmd "sudo ./easyrsa gen-dh"
    do_cmd "sudo openvpn --genkey --secret ta.key"

    # Move them to the OpenVPN directory
    do_cmd "sudo cp ta.key $SERVER_WORKING_DIR/"
    do_cmd "sudo cp pki/dh.pem $SERVER_WORKING_DIR/dh2048.pem"
    logMessage "--- End generating Diffie Hellman key and HMAC signature, at: $SERVER_WORKING_DIR/ta.key and dh2048.pem"
}


parse_command_line_arguments() {
    CLIENTS=("$@") # Get them as an array
    NUM_CLIENTS=${#CLIENTS[@]}

    if [[ NUM_CLIENTS -eq 0 ]]; then
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
