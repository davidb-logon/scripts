#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# See usage for what this script does.
# TODOs:


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
to build deb packages from cloudstack source dir, assuming build was done successfully.
 
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
    CLOUDSTACK_DIR="/home/davidb/logon/cloudstack"
    PACKAGING_DIR="${CLOUDSTACK_DIR}/packaging"
    RULES_FILE="${CLOUDSTACK_DIR}/debian/rules" # Define the path to the debian/rules file for packaging
}

package_cloudstack() {

    cp "$RULES_FILE" "${RULES_FILE}.backup" # Backup the original rules file

    # Add -DskipTests to the mvn command in the rules file
    sed -i '/mvn clean package -Psystemvm,developer -Dsystemvm \\/a\\t-DskipTests \\' "$RULES_FILE"

    cd "$PACKAGING_DIR"
    sudo ./build-deb.sh

    mv -f "${RULES_FILE}.backup" "$RULES_FILE" # Restore the original rules file from the backup
}

main() {
    init_vars "logon" "cloudstack_packaging"
    start_logging
    install_dch_and_debhelper.sh
    install_node_14.sh
    package_cloudstack
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
