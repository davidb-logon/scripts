#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# This script checks the OS type (Ubuntu, CentOS, or Red Hat), verifies if KVM can
# run on the system, checks if KVM is installed, installs it if it's not already installed, 
# and finally verifies the installation. Please note that this script requires root privileges
# to install packages and make system changes. You might need to adjust the script according
# to your specific system configuration or requirements.

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

# Function to check if KVM can run on the system
check_kvm_support() {
    logMessage "Checking for CPU virtualization support..."
    do_cmd  "egrep -c '(vmx|svm)' /proc/cpuinfo > /dev/null" \
            "CPU virtualization is supported" "CPU does not support virtualization. Exiting."
}

# Function to install KVM on Ubuntu
install_kvm_ubuntu() {
    logMessage "Updating package list..."
    sudo apt update -y
    logMessage "Installing KVM and required packages on Ubuntu..."
    sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
}

# Function to install KVM on CentOS/Red Hat
install_kvm_centos() {
    logMessage "Installing KVM and required packages on CentOS/Red Hat..."
    sudo yum install -y qemu-kvm libvirt libvirt-python libguestfs-tools virt-install
    logMessage "Starting and enabling libvirtd service..."
    sudo systemctl start libvirtd
    sudo systemctl enable libvirtd
}

# Function to verify KVM installation
verify_installation() {
    logMessage "Verifying KVM installation..."
    if lsmod | grep -i kvm > /dev/null; then
        logMessage "KVM is installed and loaded."
    else
        logMessage "KVM installation failed or KVM modules are not loaded."
        exit 1
    fi
}

# Main script starts here
init_utils_vars "logon" "install_kvm"
start_logging

# Check for root privileges
# if [ "$(id -u)" -ne 0 ]; then
#     logMessage "This script requires root privileges. Please run as root."
#     exit 1
# fi

# Check OS type
logMessage "Detecting OS type..."
OS=$(awk -F= '/^NAME/{print $2}' /etc/os-release)

if [[ $OS == *"Ubuntu"* ]]; then
    logMessage "OS detected: Ubuntu"
    check_kvm_support
    if ! dpkg -l | grep -qw qemu-kvm; then
        install_kvm_ubuntu
    else
        logMessage "KVM is already installed."
    fi
elif [[ $OS == *"CentOS"* ]] || [[ $OS == *"Red Hat"* ]]; then
    logMessage "OS detected: CentOS/Red Hat"
    check_kvm_support
    if ! rpm -q qemu-kvm libvirt libvirt-python libguestfs-tools virt-install &>/dev/null; then
        install_kvm_centos
    else
        logMessage "KVM is already installed."
    fi
else
    logMessage "Unsupported OS. This script supports Ubuntu, CentOS, and Red Hat."
    exit 1
fi

# Verify KVM installation
verify_installation

logMessage "KVM setup is complete."
