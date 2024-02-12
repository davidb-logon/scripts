#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

script_ended_ok=false
trap 'cleanup' EXIT

usage() {
cat << EOF
-------------------------------------------------------------------------------
This script follows the instructions at: 
http://docs.cloudstack.apache.org/en/4.18.1.0/installguide/building_from_source.html#building-deb-packages
and configures an ubuntu repo to serve the packages.
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
    PACKAGES_OUTPUT_DIR="$HOME/logon/packages"
    DEBIAN_PACKAGES_OUTPUT_DIR="$PACKAGES_OUTPUT_DIR/debian"
    
}

start_web_server_in_background() {
    port="$1"
    if ! ps aux | grep "python3 -m http.server $port" | grep -v grep; then
        python3 -m http.server $port &
        logMessage "Server started on port $port"
    else
        logMessage "Server is already running on port $port"
    fi
}

main() {
    init_vars "logon" "cloudstack_apt_repo"
    start_logging
    install_dch_and_debhelper.sh
    cd "$DEBIAN_PACKAGES_OUTPUT_DIR"
    touch override_file.txt
    do_cmd "dpkg-scanpackages . override_file.txt > Packages"
    do_cmd "gzip -9k Packages"
    do_cmd "apt-ftparchive release . > Release"
    logMessage "NOTE: temprarily not signing the repo, as mentioned in http://docs.cloudstack.apache.org/en/4.18.1.0/installguide/building_from_source.html#repository-signing"
    logMessage "Bringing up an HTTP server on port 8090"
    start_web_server_in_background 8090
    script_ended_ok=true
}

cleanup() {
    if $script_ended_ok; then 
        return
    fi
    echo -e "$red"
    echo 
    echo "--- SCRIPT WAS UNSUCCESSFUL"
    echo "--- Logfile at: cat $LOGFILE"
    echo "--- End Script"
    echo -e "$reset"
}
    
main "$@"
