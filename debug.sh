#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# Default parameter value
mode=${1:-on}

# Display usage message and ports info
echo "Usage: ./debug.sh [on|off]"
echo "Default mode is 'on'."
echo "Ports used: 8000 for cloudstack-management and 8001 for cloudstack-agent."

# Function to enable debugging
enable_debug() {
    # Enable debug for cloudstack-management
    sudo sed -i 's/#JAVA_DEBUG="-agentlib:jdwp=transport=dt_socket,address=\*:8000,server=y,suspend=n"/JAVA_DEBUG="-agentlib:jdwp=transport=dt_socket,address=\*:8000,server=y,suspend=n"/' /etc/default/cloudstack-management
    
    # Enable debug for cloudstack-agent and change port to 8001
    sudo sed -i 's/#JAVA_DEBUG="-agentlib:jdwp=transport=dt_socket,address=\*:8000,server=y,suspend=n"/JAVA_DEBUG="-agentlib:jdwp=transport=dt_socket,address=\*:8001,server=y,suspend=n"/' /etc/default/cloudstack-agent
}

# Function to disable debugging
disable_debug() {
    # Disable debug for cloudstack-management
    sudo sed -i 's/JAVA_DEBUG="-agentlib:jdwp=transport=dt_socket,address=\*:8000,server=y,suspend=n"/#JAVA_DEBUG="-agentlib:jdwp=transport=dt_socket,address=\*:8000,server=y,suspend=n"/' /etc/default/cloudstack-management
    
    # Disable debug for cloudstack-agent
    sudo sed -i 's/JAVA_DEBUG="-agentlib:jdwp=transport=dt_socket,address=\*:8001,server=y,suspend=n"/#JAVA_DEBUG="-agentlib:jdwp=transport=dt_socket,address=\*:8000,server=y,suspend=n"/' /etc/default/cloudstack-agent
}

# Check mode and call the appropriate function
if [ "$mode" == "on" ]; then
    enable_debug
elif [ "$mode" == "off" ]; then
    disable_debug
else
    echo "Invalid mode. Please use 'on' or 'off'."
    exit 1
fi
