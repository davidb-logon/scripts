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
    detect_linux_distribution # Sets global variable $LINUX_DISTRIBUTION
    init_vars "logon" "install_cloudstack_server" "$@"
    start_logging

    prepare_os
    start_web_server_on_repo.sh
    stop_cs # stop managment and agent
    uninstall_management_server
    install_management_server
    22_install_cmk_and_jq.sh  # need to run this after managment instalation to reinstall cmk for s390x
    install_and_configure_mysql_database
    10_configure_nfs.sh
    check_if_running_kvm_here

    do_cmd "cloudstack-setup-management"

    if [[ $LINUX_DISTRIBUTION = "UBUNTU" ]]; then
        11_configure_firewall.sh #$SEFI_NETWORK $MAINFRAME_NETWORK
    else
        logMessage "Start to Configure firewall for Red Hat"
        do_cmd "firewall-cmd --permanent --add-port=8080/tcp"
        do_cmd "firewall-cmd --permanent --add-port=8250/tcp"
        do_cmd "firewall-cmd --permanent --add-port=8443/tcp"
        do_cmd "firewall-cmd --permanent --add-port=9090/tcp"
        do_cmd "firewall-cmd --permanent --add-port=5000/tcp"
        do_cmd "firewall-cmd --reload"
        logMessage "End of Configure firewall for Red Hat"
    fi

    prepare_system_vm_template
    fix_cluster_node_ip_in_db_properties "$LOCAL_IP"
    sleep 10
    logMessage "--- Restarting CloudStack management server"
    add_env_vars_to_cloudstack_management
    restart
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
    case "$LINUX_DISTRIBUTION" in
    "UBUNTU")
        CMD="apt"
        MYSQL_SERVICE="mysql"
        SEFI_NETWORK="80.178.85.20"
        MAINFRAME_NETWORK="204.90.115.226"
        LOCAL_IP="192.168.1.248"
      ;;
    "RHEL")
        CMD="yum"
        MYSQL_SERVICE="mysqld"
        SEFI_NETWORK="80.178.85.20"
        MAINFRAME_NETWORK="204.90.115.226"
        LOCAL_IP="204.90.115.226"
      ;;
    *)
      logMessage "Unknown or Unsupported LINUX_DISTRIBUTION: $LINUX_DISTRIBUTION, exiting"
      exit 1
      ;;
    esac
}

add_env_vars_to_cloudstack_management() {
    local file="/etc/default/cloudstack-management"

        # Add the specified lines to the file
        cat <<EOL >> "$file"
JAVA_DEBUG="-agentlib:jdwp=transport=dt_socket,address=*:8000,server=y,suspend=n"
EOL

        logMessage "--- Java debug enabled in $file."
    fi
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

    install_ntp
    install_java.sh


    logMessage "--- End of preparing OS"
}

install_ntp() {
    logMessage "--- Start Installing ntp"
    do_cmd "$CMD install chrony" "Installed chrony" "Unable to install chrony"
    do_cmd "systemctl start chronyd" "Started chronyd" "Unable to start chronyd"
    do_cmd "systemctl enable chronyd" "Enabled chronyd" "Unable to enable chronyd"
    logMessage "--- End of Installing and enabling ntp"

}

uninstall_management_server() {
    logMessage "--- Start to install management server"
    case "$LINUX_DISTRIBUTION" in
    "UBUNTU")
        do_cmd "$CMD update"  # Update apt's or yum's index, to ensure getting the latest version.
        do_cmd "$CMD remove cloudstack-management "
        ;;
    "RHEL")
        do_cmd "$CMD update"  # Update apt's or yum's index, to ensure getting the latest version.
        do_cmd "$CMD remove cloudstack-management --allowerasing -y" "" "INFO: cloudstack-management is not installed"
        #do_cmd "$CMD remove cloudstack-common --allowerasing -y" "" "INFO: cloudstack-common is not installed"
       ;;
    *)
      logMessage "Unknown or Unsupported LINUX_DISTRIBUTION: $LINUX_DISTRIBUTION, exiting"
      exit 1
      ;;
    esac
    logMessage "--- End of installing management server"
}

install_management_server() {
    logMessage "--- Start to install management server"
    case "$LINUX_DISTRIBUTION" in
    "UBUNTU")
        do_cmd "$CMD update"  # Update apt's or yum's index, to ensure getting the latest version.
        do_cmd "$CMD install cloudstack-management"
        ;;
    "RHEL")
        do_cmd "$CMD update"  # Update apt's or yum's index, to ensure getting the latest version.
        do_cmd "$CMD install cloudstack-management --allowerasing -y"
        # do_cmd "mkdir -p /home/davidb/logon/work/rpm"
        # do_cmd "cd /home/davidb/logon/work/rpm"
        # files=("cloudstack-common-4.19.0.0-1.x86_64.rpm" "cloudstack-management-4.19.0.0-1.x86_64.rpm")  # cloudstack-agent-4.19.0.0-1.x86_64.rpm
        # for file in $files:
        #     if [ ! -f "$file" ]; then
        #         do_cmd "wget http://download.cloudstack.org/el/9/4.19/$file"
        #         do_cmd "rpm -i --ignorearch  --nodeps  $file"
        #     fi
        # done
       ;;
    *)
      logMessage "Unknown or Unsupported LINUX_DISTRIBUTION: $LINUX_DISTRIBUTION, exiting"
      exit 1
      ;;
    esac
    logMessage "--- End of installing management server"
}

install_and_configure_mysql_database() {
    logMessage "--- Start to install and configure mysql"
    do_cmd "$CMD install mysql-server" "mysql-server installed."
    check_mysql_configuration
    do_cmd "systemctl restart $MYSQL_SERVICE" "mysql server was started" "failed to start mysql server"
    # cloudstack-setup-databases cloud:<dbpassword>@localhost [ --deploy-as=root:<password> | --schema-only ] -e <encryption_type> -m <management_server_key> -k <database_key> -i <management_server_ip>
    do_cmd "cloudstack-setup-databases cloud:cloud@localhost --deploy-as=root"
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
    12_install_systemvm_for_kvm.sh
    logMessage "--- End of preparing system VM template"
}

main "$@"
