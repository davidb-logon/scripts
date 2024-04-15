#!/bin/bash

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

# Function to check if Maven 3 is installed
check_maven3_installed() {
    if command -v mvn &> /dev/null; then
        MAVEN_VERSION=$(mvn -version 2>&1 | head -n 1)
        logMessage "Maven is installed: $MAVEN_VERSION"
        if [[ $MAVEN_VERSION == *"Apache Maven 3"* ]]; then
            logMessage "Maven 3 is already installed."
            return 0
        else
            logMessage "Maven 3 is not installed."
            return 1
        fi
    else
        logMessage "Maven is not installed."
        return 1
    fi
}

# Function to install Maven 3
install_maven3() {
    logMessage "Installing Maven 3..."
    do_cmd "sudo apt update"
    do_cmd "sudo apt install -y maven"
    logMessage "Maven 3 installation complete."
}

# Function to update .bashrc with Maven environment variables
update_bashrc() {
    local BASHRC="$HOME/.bashrc"
    if ! grep -q 'export M2_HOME=/usr/bin/maven' "$BASHRC"; then
        logMessage "Updating .bashrc with Maven environment variables..."
        echo 'export M2_HOME=/usr/bin/maven' >> "$BASHRC"
        echo 'export PATH=${M2_HOME}/bin:${PATH}' >> "$BASHRC"
        logMessage ".bashrc has been updated. Please reload it by executing: source ~/.bashrc"
    else
        logMessage "Maven environment variables are already set in .bashrc."
    fi
}

# Main script starts here
init_utils_vars "logon" "install_maven"
start_logging
# Check if Maven 3 is installed
if check_maven3_installed; then
    logMessage "Maven 3 is already installed."
    update_bashrc  # Call the function to update .bashrc
else
    install_maven3
    # Verify installation
    if check_maven3_installed; then
        logMessage "Maven 3 has been successfully installed."
        update_bashrc  # Call the function to update .bashrc
    else
        logMessage "Failed to install Maven 3."
        exit 1
    fi
fi
