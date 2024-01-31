#!/bin/bash

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

main() {
    init_utils_vars "logon" "install_node"
    start_logging
    node_version=$(node -v 2>/dev/null)
    case $node_version in
        v14.*)
            logMessage "Node.js version 14 is already installed."
            ;;
        "")
            logMessage "Node.js is not installed."
            install_node_14
            ;;
        *)
            logMessage "Node.js $node_version is installed. Will remove and replace with 14."
            uninstall_node
            install_node_14
            ;;
    esac
}

install_node_14() {
    logMessage "Installing Node.js version 14..."
    curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
    sudo apt-get install -y nodejs
    logMessage "Node.js version 14 has been installed."
}

uninstall_node() {
    logMessage "Uninstalling Node.js..."

    # Remove Node.js and npm packages
    sudo apt-get remove -y nodejs npm

    # Autoremove to clean up unused packages
    sudo apt-get autoremove -y

    logMessage "Node.js has been uninstalled."
}

main

#