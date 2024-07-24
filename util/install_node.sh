#!/bin/bash

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

main() {
    init_vars "logon" "install_node"
    start_logging
    node_version=$(node -v 2>/dev/null)
    case $node_version in
        v${NODE_VERSION}.*)
            logMessage "Node.js version $NODE_VERSION is already installed."
            ;;
        "")
            logMessage "Node.js is not installed."
            install_node
            ;;
        *)
            logMessage "Node.js $node_version is installed. Will remove and replace."
            uninstall_node
            install_node
            ;;
    esac
}

init_vars() {
    init_utils_vars $1 $2
    detect_linux_distribution
    detect_install_cmd # exports INSTALL_CMD
    NODE_VERSION="18"
}

install_node() {
    logMessage "Installing node version $NODE_VERSION"
    case "$LINUX_DISTRIBUTION" in
    "UBUNTU")
        curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo $INSTALL_CMD install -y nodejs
        ;;
    "RHEL")
      curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
      sudo $INSTALL_CMD install -y nodejs
      ;;
    "Unknown")
      logMessage "--- Unknown Linux distribution, exiting"
      exit 1
      ;;    
    *)
      logMessage "Unknown Unsupported LINUX_DISTRIBUTION: $LINUX_DISTRIBUTION, exiting"
      exit 1
      ;;
  esac
}

uninstall_node() {
    logMessage "Uninstalling Node.js..."

    # Remove Node.js and npm packages
    sudo $INSTALL_CMD remove -y nodejs npm

    # Autoremove to clean up unused packages
    sudo $INSTALL_CMD autoremove -y

    logMessage "Node.js has been uninstalled."
}

main

#