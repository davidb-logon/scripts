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
and Builds deb packages from cloudstack source dir, but skips the tests.
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
    # Input
    CLOUDSTACK_DIR="$HOME/logon/cloudstack"
    /home/davidb/logon/work

    LOGON_RULES_FILE="$CLOUDSTACK_DIR/a_logon_workdir/rules.logon" # rules file that skips tests and adds sources
    SAVED_RULES_FILE="$CLOUDSTACK_DIR/a_logon_workdir/rules.original" # As it came from cloudstack, rc2
    RULES_FILE="$CLOUDSTACK_DIR/debian/rules" # As it came from cloudstack, rc2
    
    PACKAGING_DIR="${CLOUDSTACK_DIR}/packaging" # Where the build-deb.sh script resides

    # Output of the build
    PACKAGES_OUTPUT_DIR="$HOME/logon/packages"
    DEBIAN_PACKAGES_OUTPUT_DIR="$PACKAGES_OUTPUT_DIR/debian"
    
}

text_files_are_different() {
    cmp -s "$1" "$2" && return 1 || return 0
}

package_cloudstack() {

    # check if the current rules file is different than the original RC2 files that was saved
    # in a_logon_workdir. If not, the script is stopped and user is asked to update the files.
    if text_files_are_different "$RULES_FILE" "$SAVED_RULES_FILE"; then
        logMessage "$RULES_FILE and $SAVED_RULES_FILE are different. Please fix manually."
        exit 1
    fi
    
    cp -fv "$LOGON_RULES_FILE" "$RULES_FILE" # copy the rules fileto skip tests and add sources

    cd "$PACKAGING_DIR"
    sudo ./build-deb.sh -o "$DEBIAN_PACKAGES_OUTPUT_DIR" # -b "Log-On" # Beware that such branding will change all pom files (> 100) in the project

    cp -fv  "$SAVED_RULES_FILE" "$RULES_FILE"  # Restore the original rules file 
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
