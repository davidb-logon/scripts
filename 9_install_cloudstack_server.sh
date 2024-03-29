#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# See usage for what this script does.
# TODOs:
#      - to work around issue with multiple ip addresses for cs management, add 
#        1. set in the hypervisor config the ip to "csmanagement"
#        2. In the agent install, add to the /etc/hosts file an entry with "csmangement" pointing
#           to the local or public cs management server ip address (this can be added as a 
#           parameter to agent install

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"
source "$DIR/lib/nfsconfig.sh"

script_ended_ok=false
trap 'cleanup' EXIT

usage() {
cat << EOF
-------------------------------------------------------------------------------
Install Cloudstack server from local repo 

Following instructions at:
http://docs.cloudstack.apache.org/en/4.19.0.0/installguide/management-server/index.html


-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

main() {
    # Replace logon and template with your own values
    init_vars "logon" "install_cloudstack_server" "$@"
    start_logging
    prepare_os
    install_management_server
    
    install_and_configure_mysql_database
    check_if_running_kvm_here
    do_cmd "$SUDO cloudstack-setup-management"
    10_configure_nfs.sh
    11_configure_firewall.sh #$SEFI_NETWORK $MAINFRAME_NETWORK
    prepare_system_vm_template
    fix_cluster_node_ip_in_db_properties "$LOCAL_IP"
    sleep 10
    logMessage "--- Restarting CloudStack management server"
    restart
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
    
    HOME_NETWORK="192.168.1.0/24"
    SEFI_NETWORK="80.178.85.20"
    MAINFRAME_NETWORK="204.90.115.208"
    LOCAL_IP="192.168.1.248"
}

fix_cluster_node_ip_in_db_properties() {
    logMessage "--- Start to fix db.properties"
    local NEW_IP="$1"
    FILE_PATH="/etc/cloudstack/management/db.properties"

    # Check if the file exists
    if [ -f "$FILE_PATH" ]; then
        # Use sed to change any IP address that follows 'cluster.node.IP=' to the new IP address
        if sed -i "s/^cluster\.node\.IP=.*$/cluster.node.IP=$NEW_IP/" "$FILE_PATH"; then
            logMessage "The IP address for cluster.node.IP has been successfully updated to $NEW_IP in $FILE_PATH."
        else
            logMessage "Failed to update the IP address for cluster.node.IP in $FILE_PATH."
        fi
    else
        logMessage "Error: $FILE_PATH does not exist."
    fi
}

prepare_os() {
    logMessage "--- Start to prepare OS"
    #!/bin/bash

    # Check if the current user ID is 0 (root user)
    if [ "$(id -u)" -ne 0 ]; then
        logMessage "--- You are not root. exiting."
        exit 1
    else
        logMessage "--- Logged in as root."
        SUDO=""
    fi
    HOSTNAME=$(hostname --fqdn)
    confirm "--- hostname: $HOSTNAME, confirm " || exit 1
    

    if ! check_if_connected_to_internet; then
        logMessage "--- Not connected to internet"
        exit 1
    fi
    logMessage "Connected to the internet."

    logMessage "Installing ntp"
    do_cmd "$SUDO apt install chrony" "Installed chrony"
    install_java.sh

    logMessage "--- End of preparing OS"
}

install_management_server() {
    logMessage "--- Start to install management server"
    do_cmd "$SUDO apt-get update"  # Update apt's index, to ensure getting the latest version.
    do_cmd "$SUDO apt install cloudstack-management"
    logMessage "--- End of installing management server"
}

install_and_configure_mysql_database() {
    logMessage "--- Start to install and configure mysql"
    do_cmd "$SUDO apt install mysql-server" "mysql-server installed."
    check_mysql_configuration
    do_cmd "$SUDO systemctl restart mysql" "mysql server was started" "failed to start mysql server"
    # cloudstack-setup-databases cloud:<dbpassword>@localhost [ --deploy-as=root:<password> | --schema-only ] -e <encryption_type> -m <management_server_key> -k <database_key> -i <management_server_ip>
    do_cmd "$SUDO cloudstack-setup-databases cloud:cloud@localhost --deploy-as=root"
    logMessage "--- End of installing and configuring mysql"
}

check_mysql_configuration() {
    echo "Please ensure that /etc/mysql/mysql.conf.d/mysqld.cnf contains:"
cat << EOF
[mysqld]
server-id=source-01
innodb_rollback_on_timeout=1
innodb_lock_wait_timeout=600
max_connections=350
log-bin=mysql-bin
binlog-format = 'ROW'
EOF
    confirm "Please confirm" || exit 1

}

check_if_running_kvm_here() {
    if confirm "Are you running KVM hypervisor on this machine as well?"; then
        confirm "Ensure the line: Defaults:cloud !requiretty is in your /etc/sudoers" || exit 1
    fi
}

prepare_system_vm_template() {
    logMessage "--- Start to preparing system VM template"
    do_cmd "sudo /usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /mnt/secondary -u http://download.cloudstack.org/systemvm/4.19/systemvmtemplate-4.19.0-kvm.qcow2.bz2 -h kvm -F" \
            "SystemVM template for KVM has been seeded in secondary storage" \
            "Unable to seed secondary storage with SystemVM template"

    logMessage "--- End of preparing system VM template"
}
  
main "$@"
