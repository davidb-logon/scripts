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
    
    init_vars "logon" "setup_openvpn"
    start_logging

    parse_command_line_arguments "$@" # Get the clients,
    check_if_root
    
    create_ovpn_server

    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    logMessage "The script took $elapsed_time seconds to complete."
    script_ended_ok=true
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
                ;;
            "RHEL")
                EASYRSA_CMD="easyrsa"
                ;;
            *)
                error_exit "Unknown or Unsupported LINUX_DISTRIBUTION: $LINUX_DISTRIBUTION, exiting"
                ;;
        esac    
}

create_ovpn_server(){
    logMessage "Starting to create Open VPN server"
    install_openvpn_and_easy_rsa
    setup_CA_certificate
    generate_server_certificate_and_key
    generate_Diffie_Hellman_key_and_HMAC_signature
 

    do_cmd "mkdir /etc/openvpn/ccd"

    # Configure OpenVPN Server
    do_cmd "cp -p /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/server.conf"
    do_cmd "sed -i 's/;tls-auth ta.key 0/tls-auth ta.key 0/' /etc/openvpn/server.conf"
    do_cmd "sed -i 's/;cipher AES-256-CBC/cipher AES-256-CBC/' /etc/openvpn/server.conf"
    do_cmd "sed -i 's/;user nobody/user nobody/' /etc/openvpn/server.conf"
    do_cmd "sed -i 's/;group nogroup/group nogroup/' /etc/openvpn/server.conf"
    do_cmd "sed -i 's/;client-to-client/client-to-client/' /etc/openvpn/server.conf"


    # To address the issues seen in "journalctl -u openvpn@server", add the following to server.conf:
    # topology subnet
    # data-ciphers AES-256-GCM:AES-128-GCM:AES-256-CBC

    # Enable IP Forwarding
    do_cmd "sed -i '/net.ipv4.ip_forward=1/s/^#//g' /etc/sysctl.conf"
    do_cmd "sysctl -p"

    # Start and Enable OpenVPN
    do_cmd "systemctl enable openvpn@server"
    do_cmd "systemctl start openvpn@server"
    

    logMessage "OpenVPN setup is complete. Review the configuration and adjust firewall settings accordingly."
}



install_openvpn_and_easy_rsa() {
    logMessage "--- Start installing openvpn and easy-rsa"
    case "$LINUX_DISTRIBUTION" in
    "UBUNTU")
        do_cmd "apt update && apt upgrade -y"
        do_cmd "apt install openvpn easy-rsa -y"
        ;;
    "RHEL")
        do_cmd "yum update && yum upgrade -y"
        do_cmd "yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm"
        do_cmd "yum install openvpn easy-rsa -y"
        # This needs to be changed if rpm installs easyrsa somewhere else
        if ! [ -f /usr/local/sbin/easyrsa ]; then
            do_cmd "ln -s /usr/share/easy-rsa/3.0.8/easyrsa /usr/local/sbin/easyrsa"
        fi
       ;;
    *)
      error_exit "Unknown or Unsupported LINUX_DISTRIBUTION: $LINUX_DISTRIBUTION, exiting"
      ;;
    esac
  
    logMessage "--- End installing openvpn and easy-rsa"
}


# Function to set up a Certificate Authority (CA)
setup_ca() {
  local CA_DIR=$1
  local COMMON_NAME=$2
  local COUNTRY=$3
  local STATE=$4
  local ORGANIZATION=$5

  # Exit immediately if a command exits with a non-zero status.
  set -e

  # Install OpenSSL if not already installed
  sudo yum install -y openssl

  # Create the CA directory structure
  sudo mkdir -p ${CA_DIR}/{certs,crl,newcerts,private}
  sudo chmod 700 ${CA_DIR}/private
  sudo touch ${CA_DIR}/index.txt
  echo 1000 | sudo tee ${CA_DIR}/serial

  # Create the OpenSSL configuration file
  sudo tee ${CA_DIR}/openssl.cnf > /dev/null << EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = ${CA_DIR}
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
RANDFILE          = \$dir/private/.rand

private_key       = \$dir/private/ca.key.pem
certificate       = \$dir/certs/ca.cert.pem

crlnumber         = \$dir/crlnumber
crl               = \$dir/crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_strict

[ policy_strict ]
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits        = 2048
default_md          = sha256
default_keyfile     = privkey.pem
distinguished_name  = req_distinguished_name
string_mask         = utf8only

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = CA:TRUE
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${COMMON_NAME}

[ crl_ext ]
authorityKeyIdentifier=keyid:always
EOF

  # Generate the CA private key
  sudo openssl genpkey -algorithm RSA -out ${CA_DIR}/private/ca.key.pem
  sudo chmod 400 ${CA_DIR}/private/ca.key.pem

  # Generate the CA certificate
  sudo openssl req -config ${CA_DIR}/openssl.cnf -key ${CA_DIR}/private/ca.key.pem -new -x509 -days 7300 -sha256 -extensions v3_ca -out ${CA_DIR}/certs/ca.cert.pem -subj "/C=${COUNTRY}/ST=${STATE}/O=${ORGANIZATION}/CN=${COMMON_NAME}"
  sudo chmod 444 ${CA_DIR}/certs/ca.cert.pem

  # Verify the CA certificate
  sudo openssl x509 -noout -text -in ${CA_DIR}/certs/ca.cert.pem

  echo "CA setup complete. CA certificate and key have been generated and stored in ${CA_DIR}."
}

setup_CA_certificate() {
    logMessage "--- Start setting up the CA certificate"
    # Set up Easy-RSA directory

    case "$LINUX_DISTRIBUTION" in
        "UBUNTU")
            do_cmd "make-cadir ~/openvpn-ca" "Created cadir" "INFO: Unable to create ca_dir"
            ;;
        "RHEL")
            logMessage "For RHEL, use chatGPT created function"
            setup_ca "/root/openvpn-ca" "log-on.com" "US" "California" "Log-On Organization"
            ;;
        *)
            error_exit "Unknown or Unsupported LINUX_DISTRIBUTION: $LINUX_DISTRIBUTION, exiting"
            ;;
    esac

    cd /root/openvpn-ca
    init_RSA_vars
    # Initialize and build CA
    do_cmd "${EASYRSA_CMD} init-pki"
    do_cmd "echo 'CA' | ${EASYRSA_CMD} build-ca nopass"

    do_cmd "cp pki/ca.crt /etc/openvpn/"
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
    do_cmd "${EASYRSA_CMD} gen-req server nopass"
    do_cmd "cp pki/private/server.key /etc/openvpn/"

${EASYRSA_CMD} sign-req server server <<EOF
yes
EOF

    # Copy the server certificate to the OpenVPN directory
    do_cmd "cp pki/issued/server.crt /etc/openvpn/"
    logMessage "--- End generating server certificate and key, at: /etc/openvpn/server.crt"
}


generate_Diffie_Hellman_key_and_HMAC_signature() {
    logMessage "--- Start generating Diffie Hellman key and HMAC signature"
    
    # Generate Diffie-Hellman key and HMAC signature
    do_cmd "${EASYRSA_CMD} gen-dh"
    do_cmd "openvpn --genkey --secret ta.key"

    # Move them to the OpenVPN directory
    do_cmd "cp ta.key /etc/openvpn/"
    do_cmd "cp pki/dh.pem /etc/openvpn/dh2048.pem"
    logMessage "--- End generating Diffie Hellman key and HMAC signature, at: /etc/openvpn/ta.key and dh2048.pem"
}


parse_command_line_arguments() {
    CLIENTS=("$@") # Get them as an array
    NUM_CLIENTS=${#clients[@]}

    if [ NUM_CLIENTS -eq 0 ]; then
        message="No clients names provided on command line, none will be assigned fixed ips."
        logMessage $message
        usage
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
    do_cmd "cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/ovpn-$client/$client.ovpn"
    cd ~/ovpn-$client
    do_cmd "chown $USER:$USER *"
    do_cmd "sed -i 's/cert client.crt/cert $client.crt/g' $client.ovpn"
    do_cmd "sed -i 's/key client.key/key $client.key/g' $client.ovpn"
    do_cmd "sed -i 's/remote my-server-1/remote $vpnserver/g' $client.ovpn"
    do_cmd "zip $client.ovpn.zip $client.ovpn $client.key $client.crt ca.crt ta.key"
}

setup_ovpn_client_as_service(){
#    
#/etc/systemd/system/openvpn@client.service (replace client with your specific client name if needed). Use a text editor like nano to edit the file.
#
#Add the following content to the file, replacing placeholders with your actual details:
#
# first, get the .ovpn file from the currnet dir
if [[ $(ls *.ovpn | grep -c ".ovpn") == 1 ]]; then
    # first
    do_cmd "clientName=$(ls *.ovpn)"
    logMessage "--- Start generating service for client: $clientName"
    do_cmd "CLIENT_DIR=$(pwd)"
    cat << EOF > /etc/systemd/system/openvpn@client.service
[Unit]
Description=OpenVPN Client Service - $clientName
After=network.target

[Service]
Type=simple
Restart=on-failure
ExecStart=/usr/sbin/openvpn --config $CLIENT_DIR/$clientName
User=nobody  # Adjust user privileges if needed
Group=nogroup # Adjust group privileges if needed

[Install]
WantedBy=multi-user.target
EOF

    do_cmd "systemctl daemon-reload"
    do_cmd "systemctl enable openvpn@client.service"
    do_cmd "systemctl restart openvpn@client.service"
fi

}
#-------------------------------------------------------#
#                Start script execution                 #
#-------------------------------------------------------#



main "$@"
