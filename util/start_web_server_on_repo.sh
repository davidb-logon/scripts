#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

init_utils_vars

port=${1:-8090} # You can provide a port via $1, or it will use the default 8090

# PACKAGES_OUTPUT_DIR="/home/davidb/logon/packages"
# DEBIAN_PACKAGES_OUTPUT_DIR="$PACKAGES_OUTPUT_DIR/debian"

#DEBIAN_PACKAGES_OUTPUT_DIR="$PACKAGES_OUTPUT_DIR/debian"
RPM_PACKAGES_OUTPUT_DIR="/data/repo"

#cd "$DEBIAN_PACKAGES_OUTPUT_DIR"
cd "$RPM_PACKAGES_OUTPUT_DIR"

if ! ps aux | grep "python3 -m http.server" | grep -v grep; then
    #python3 -m http.server $port &
    python3 -m http.server $port > access.log 2> error.log &

    logMessage "Server started on port $port"
else
    logMessage "Server is already running on port $port"
fi

