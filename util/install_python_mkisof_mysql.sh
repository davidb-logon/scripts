#!/bin/bash

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

# Function to check and install a package if not installed
check_and_install_package() {
    local package=$1
    logMessage "Checking for $package..."
    if ! dpkg -l | grep -qw $package; then
        logMessage "$package is not installed. Installing..."
        do_cmd "sudo apt-get install -y $package"
    else
        logMessage "$package is already installed."
    fi
}

# Main script starts here
init_utils_vars "logon" "install_python_mkisof_mysql"
start_logging

# Update package list
logMessage "Updating package list..."
do_cmd "sudo apt-get update"

# Check and install python-setuptools
check_and_install_package python-setuptools

# Check and install mkisofs
# Note: The mkisofs package may be provided by genisoimage in some Ubuntu versions
if ! dpkg -l | grep -qw mkisofs; then
    if ! dpkg -l | grep -qw genisoimage; then
        logMessage "mkisofs (provided by genisoimage) is not installed. Installing..."
        do_cmd "sudo apt-get install -y genisoimage"
    else
        logMessage "mkisofs (provided by genisoimage) is already installed."
    fi
else
    logMessage "mkisofs is already installed."
fi

# Check and install mysql-server
check_and_install_package mysql-server

logMessage "Installation process completed."
