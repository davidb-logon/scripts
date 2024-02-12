#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# See usage for what this script does.
# TODOs:


# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

script_ended_ok=false
trap 'cleanup' EXIT

usage() {
cat << EOF
-------------------------------------------------------------------------------
Install Cloudstack server from local repo at 10.0.0.20

Following instructions at:
http://docs.cloudstack.apache.org/en/4.19.0.0/installguide/management-server/index.html


-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

prepare_os() {
    logMessage "--- Start to prepare OS"
    #!/bin/bash

    # Check if the current user ID is 0 (root user)
    if [ "$(id -u)" -ne 0 ]; then
        logMessage "--- You are not root. Will prepend 'sudo' to all commands."
        SUDO="sudo "
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
    do_cmd "install_java.sh"




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
    logMessage "--- End of installing and configuring mysql"

}

prepqare_nfs_shares() {
    logMessage "--- Start to prepare NFS shares"
    logMessage "--- End of preparing NFS shares"
}

prepare_system_vm_template() {
    logMessage "--- Start to preparing system VM template"
    logMessage "--- End of preparing system VM template"
}

main() {
    # Replace logon and template with your own values
    init_vars "logon" "install_cloudstack_server_and_agent"
    parse_command_line_arguments "$@"
    start_logging
    prepare_os
    install_management_server
    install_and_configure_mysql_database
    prepqare_nfs_shares
    prepare_system_vm_template
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

cleanup() {
    if $script_ended_ok; then 
        echo -e "$green"
        echo 
        echo "--- SCRIPT WAS SUCCESSFUL"
    else
        echo -e "$red"
        echo 
        echo "--- SCRIPT WAS UNSUCCESSFUL"
    fi
    echo "--- Logfile at: cat $LOGFILE"
    echo "--- End Script"
    echo -e "$reset"
}
    
main "$@"
