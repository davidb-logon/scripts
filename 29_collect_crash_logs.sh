#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

main() {
    start_time=$(date +%s)
    usage
    init_vars "logon" "collect_crash_logs"
    start_logging

    # Define the name of the output zip file
    output_zip="server_logs_$(date +%Y-%m-%d_%H-%M-%S).zip"

    # Create a temporary directory to store the log files
    temp_dir=$(mktemp -d)

    # Copy the relevant log files and directories to the temporary directory
    cp /var/log/syslog* "${temp_dir}/"
    cp /var/log/kern.log* "${temp_dir}/"
    cp /var/log/auth.log* "${temp_dir}/"
    cp /var/log/boot.log* "${temp_dir}/"
    cp /var/log/dmesg* "${temp_dir}/"
    cp -r /var/log/apache2/ "${temp_dir}/apache2_logs" 2>/dev/null
    cp -r /var/log/nginx/ "${temp_dir}/nginx_logs" 2>/dev/null
    cp -r /var/log/mysql/ "${temp_dir}/mysql_logs" 2>/dev/null
    cp -r /var/crash/ "${temp_dir}/crash_reports" 2>/dev/null
    cp -r /var/log/apparmor/ "${temp_dir}/apparmor_logs" 2>/dev/null

    # Use journalctl to dump logs into a file, if available
    if command -v journalctl &> /dev/null; then
        journalctl -xb > "${temp_dir}/systemd_journal_current_boot.log"
    fi

    # Change to the temporary directory
    cd "${temp_dir}"

    # Zip the contents of the temporary directory
    zip -r "${output_zip}" .

    # Move the zip file to the current working directory (or any directory you prefer)
    mv "${output_zip}" "/home/davidb/logon/work/"

    # Clean up by removing the temporary directory
    cd /
    cd "/home/davidb/logon/work"
    rm -rf "${temp_dir}"

    echo "Log files have been zipped into ${output_zip}"

    
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
