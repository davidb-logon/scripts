#!/bin/bash

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

check_dch_installed() {
    if command -v dch &> /dev/null; then
        return 0
    else
        return 1
    fi
}

is_debhelper_installed() {
    dpkg -s debhelper &> /dev/null
}

install_debhelper() {
    logMessage "Debhelper is not installed. Installing now..."
    do_cmd "sudo apt update"
    do_cmd "sudo apt install -y debhelper"
    logMessage "Debhelper has been installed."
}

# Function to install Maven 3
install_dch() {
    logMessage "Installing 'devscripts' package which includes 'dch'..."
    do_cmd "sudo apt-get update"
    do_cmd "sudo apt-get install -y devscripts"
    logMessage "dch installation complete."
}

# Main script starts here
init_utils_vars "logon" "install_dch_and_debhelper"
start_logging
# Check if dch is installed
if check_dch_installed; then
    logMessage "dch is already installed."
else
    install_dch
    # Verify installation
    if check_dch_installed; then
        logMessage "dch has been successfully installed."
    else
        logMessage "Failed to install dch."
        exit 1
    fi
fi

if is_debhelper_installed; then
    logMessage "debhelper is already installed"
else
    install_debhelper
fi

