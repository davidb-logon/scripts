#!/bin/bash

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

main() {
    init_vars "logon" "install_node"
    start_logging
    check_if_root
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
    NODE_VERSION="16"
}

install_node() {
    logMessage "Installing node version $NODE_VERSION"
    case "$LINUX_DISTRIBUTION" in
    "UBUNTU")
        curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo $INSTALL_CMD install -y nodejs
        ;;
    "RHEL")
        # For IBM Z only
        mkdir -p /data/installation
        cd installation/
        # for node 14:  https://nodejs.org/dist/v14.21.0/node-v14.21.0-linux-s390x.tar.xz
        # for node 16:  https://nodejs.org/dist/latest-v16.x/node-v16.20.2-linux-s390x.tar.gz
        NODE_FILE="node-v16.20.2-linux-s390x"
        curl https://nodejs.org/dist/latest-v16.x/${NODE_FILE}.tar.xz -o ${NODE_FILE}.tar.xz
        tar -xvf ${NODE_FILE}.tar.xz
        yum remove nodejs -y
        rm -rf /usr/local/nodejs
        mv ${NODE_FILE} /usr/local/nodejs
        update_and_reload_bashrc
        node -v
        npm -v
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

update_and_reload_bashrc() {
    local line="export PATH=/usr/local/nodejs/bin:$PATH"
    for user in root sefi davidb; do
        add_line_to_bashrc_if_not_exists $user "$line"
    done
    source ~/.bashrc
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