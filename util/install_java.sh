#!/bin/bash
# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

# Function to check if Java 11 is installed
check_java11_installed() {
    if java -version 2>&1 | grep -q 'openjdk version "11.0'; then  # i have set it to 21 to force instalation of java 11
        logMessage "Java 11 is already installed."
        return 0
    else
        logMessage "Java 11 is not installed."
        return 1
    fi
}

# Function to install Java 11
install_java11() {
    logMessage "Installing Java 11..."
    CMD="yum"
    package="java-11-openjdk"
    if [[ $LINUX_DISTRIBUTION = "UBUNTU" ]]; then
        CMD="apt"
        package="openjdk-11-jdk"
    fi
    do_cmd "sudo $CMD update"
    do_cmd "sudo $CMD install -y $package"

    #after the installation you need to run:
    #sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/jre-11-openjdk-11.0.14.1.1-6.el8.s390x/bin/java 100
    #sudo update-alternatives --config java
    #and select the java u want to use by the number from the list
    java_option=$(echo "" | sudo update-alternatives --config java | grep java-11 |  cut -c 4)
    do_cmd "echo $java_option | sudo update-alternatives --config java"

    logMessage "Java 11 installation complete."
}

# Function to update .bashrc with Java environment variables
update_bashrc() {
    local BASHRC="$HOME/.bashrc"
    local JAVA_HOME_SET=$(grep -c 'export JAVA_HOME=' "$BASHRC")
    local JAVA_PATH_SET=$(grep -c 'export PATH=.*JAVA_HOME' "$BASHRC")

    local updated=0
    path_for_java=$(echo "" | sudo update-alternatives --config java | grep java-11 |  sed -n 's/.*(\(.*\)).*/\1/p' | sed 's|/bin/.*||' )
    if [ $JAVA_HOME_SET -eq 0 ]; then
        logMessage "--- Setting JAVA_HOME in .bashrc..."
        #sudo echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> "$BASHRC"
        sudo echo "export JAVA_HOME=${path_for_java}" >> "$BASHRC"
        updated=1
    else
        logMessage "--- JAVA_HOME is already set in .bashrc."
    fi

    if [ $JAVA_PATH_SET -eq 0 ]; then
        logMessage "--- Setting Java PATH in .bashrc..."
        sudo echo 'export PATH=${JAVA_HOME}/bin:${PATH}' >> "$BASHRC"
        updated=1
    else
        logMessage "--- Java PATH is already set in .bashrc."
    fi

    if [ updated == 1 ]; then 
        logMessage "--- .bashrc updated. Please reload it by executing: source ~/.bashrc"
    fi
}

# Main script starts here
init_utils_vars "logon" "install_java"
detect_linux_distribution

start_logging
# Check if Java 11 is installed
if ! check_java11_installed; then
    install_java11
    # Verify Java 11 installation
    if check_java11_installed; then
        logMessage "Java 11 has been successfully installed."
        
    else
        logMessage "Failed to install Java 11."
        exit 1
    fi
fi
update_bashrc  # Update .bashrc with Java environment variables
