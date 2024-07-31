#!/bin/bash

#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

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
    check_if_root
    download_golang_for_mainframe
    remove_previous_go_installation
    extract_tar_to_installation_dir
    add_go_to_path /root

    # Apply the changes
    source ~/.bashrc

    # Verify the installation
    logMessage "Verifying Go installation..."
    go version
    
    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    logMessage "The script took $elapsed_time seconds to complete."
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
    GO_VERSION="1.22.5"
    GO_TAR_URL="https://go.dev/dl/go${GO_VERSION}.linux-s390x.tar.gz"
    INSTALL_DIR="/usr/local"
    GO_PATH_LINE="export PATH=${INSTALL_DIR}/go/bin:$PATH"
    
}

download_golang_for_mainframe() {
    logMessage "Downloading the Go tarball: $GO_TAR_URL"
    do_cmd "wget -q $GO_TAR_URL -O /tmp/go${GO_VERSION}.linux-s390x.tar.gz" "Successfully downloaded Go $GO_VERSION" "Failed to download Go Tar file"
}

remove_previous_go_installation(){
    # Remove any previous Go installation
    logMessage "Removing any previous Go installation..."
    do_cmd "sudo rm -rf ${INSTALL_DIR}/go"
}

extract_tar_to_installation_dir() {
    logMessage "Extracting Go ${GO_VERSION} to ${INSTALL_DIR}..."
    do_cmd "sudo tar -C ${INSTALL_DIR} -xzf /tmp/go${GO_VERSION}.linux-s390x.tar.gz"
}

add_go_to_path() {
    local user_home=$1
    local bashrc_file="${user_home}/.bashrc"

    if ! grep -q "${INSTALL_DIR}/go/bin" "$bashrc_file"; then
        logMessage "Adding Go to PATH in ${bashrc_file}..."
        echo "$GO_PATH_LINE" >> "$bashrc_file"
    else
        logMessage "Go path already present in ${bashrc_file}"
    fi
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
-------------------------------------------------------
This script downloads and installs go for the mainframe
-------------------------------------------------------
EOF
script_ended_ok=true
}

main "$@"



