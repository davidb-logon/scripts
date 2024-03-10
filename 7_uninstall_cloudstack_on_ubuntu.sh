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
This script uninstalls cloudstack management server and agent from Ubuntu / KVM
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

backup_agent_files() {
    files=( 
        "/etc/cloudstack/agent/agent.properties" 
        "/etc/cloudstack/agent/cloud.ca.crt" 
        "/etc/cloudstack/agent/cloud.crt" 
        "/etc/cloudstack/agent/cloud.csr" 
        "/etc/cloudstack/agent/cloud.jks" 
        "/etc/cloudstack/agent/cloud.key" 
        "/etc/cloudstack/agent/environment.properties" 
        "/etc/cloudstack/agent/log4j-cloud.xml" 
     )

    backup_dir="/home/davidb/logon/work/agent-backup"
    mkdir -p "$backup_dir"

    # Loop through the files
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            # Extract base name
            base_name=$(basename "$file")

            # Get current date and time
            datetime=$(date +"%Y%m%d-%H%M%S")

            # Construct backup file path
            backup_file="$backup_dir/${base_name%.*}-$datetime.${base_name##*.}"

            # Copy the file to the backup directory with the new name
            do_cmd "sudo cp -pv $file $backup_file" "Backed up '$file' to '$backup_file'"

        else
            logMessage "File '$file' does not exist and was not backed up."
        fi
    done

}

main() {
    # Replace logon and template with your own values
    init_vars "logon" "uninstall_cloudstack"
    start_logging
    backup_agent_files

    do_cmd "sudo systemctl stop cloudstack-management" "Stopped cloudstack_management service"
    do_cmd "sudo systemctl stop cloudstack-agent" "Stopped cloudstack_agent service"
    do_cmd "sudo apt-get remove --purge cloudstack-management"
    do_cmd "sudo apt-get remove --purge cloudstack-agent"
    do_cmd "sudo apt-get autoremove"
    do_cmd "sudo apt-get autoclean"
    do_cmd "sudo rm -rf /etc/cloudstack"
    do_cmd "sudo rm -rf /usr/share/cloudstack-common"
    do_cmd "sudo rm -rf /usr/share/cloudstack-agent"
    do_cmd "sudo rm -rf /var/log/cloudstack"
    do_cmd "mysql -u cloud -pcloud -e 'DROP DATABASE cloud;'"
    do_cmd "mysql -u cloud -pcloud -e 'DROP DATABASE cloud_usage;'"
    #do_cmd "mysql -u cloud -pcloud -e 'DROP USER cloud@localhost';"

    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}
    
main "$@"
