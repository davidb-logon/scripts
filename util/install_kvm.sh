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

main() {
    # Main script starts here
    init_utils_vars "logon" "install_kvm"
    start_logging

    check_if_root
    detect_linux_distribution
    detect_architecture

    if [[ $LINUX_DISTRIBUTION == *"Ubuntu"* ]]; then
        check_kvm_support
        if ! dpkg -l | grep -qw qemu-kvm; then
            install_kvm_ubuntu
        else
            logMessage "KVM is already installed."
        fi
    elif [[ $LINUX_DISTRIBUTION == *"CentOS"* ]] || [[ $$LINUX_DISTRIBUTION == *"Red Hat"* ]]; then
        if [[ $MACHINE_ARCHITECTURE="x86_64" ]]; then
            check_kvm_support
        fi
        if ! rpm -q qemu-kvm libvirt libvirt-python libguestfs-tools virt-install &>/dev/null; then
            install_kvm_centos
        else
            logMessage "KVM is already installed."
        fi
    else
        error_exit "Unsupported OS. This script supports Ubuntu, CentOS, and Red Hat."
    fi

    # Verify KVM installation
    verify_installation

    logMessage "KVM setup is complete."
}


# Function to check if KVM can run on the system
check_kvm_support() {
    logMessage "Checking for CPU virtualization support..."
    do_cmd  "egrep -c '(vmx|svm)' /proc/cpuinfo > /dev/null" \
            "CPU virtualization is supported" "CPU does not support virtualization. Exiting."
}

check_kvm_support_on_Z() {
    logMessage "Checking for CPU virtualization support on Z"
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
        error_exit "KVM installation failed or KVM modules are not loaded."
    fi
}

main