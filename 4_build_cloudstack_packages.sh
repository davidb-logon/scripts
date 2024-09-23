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
    if [ $(uname -m) == "x86_64" ]; then
        CLOUDSTACK_DIR="$HOME/logon/cloudstack"
    else
        CLOUDSTACK_DIR="/data/cloudstack" # For s390x @ dallas
    fi
    #/home/davidb/logon/work

    PACKAGING_DIR="${CLOUDSTACK_DIR}/packaging" # Where the build-deb.sh script resides

    # Output of the build
    PACKAGES_OUTPUT_DIR="$HOME/logon/packages"
    DEBIAN_PACKAGES_OUTPUT_DIR="$PACKAGES_OUTPUT_DIR/debian"
    
}

package_cloudstack() {
    cd "$PACKAGING_DIR"
    case "$LINUX_DISTRIBUTION" in
        "UBUNTU")
            # Note that the option -b "Log-On" for branding will change all pom files (> 100) in the project
            export DEBUG=1 # To generate sources and skip tests. See debian/rules file.
            install_dch_and_debhelper.sh
            install_node_14.sh
            install_python_mkisof_mysql.sh
            ./build-deb.sh -o "$DEBIAN_PACKAGES_OUTPUT_DIR" 2>&1 | tee $LOGFILE  #W2 DB 3
            ;;
        "RHEL")
            ./package.sh -d centos8
            do_cmd "\\cp -fv /data/cloudstack/dist/rpmbuild/RPMS/s390x/* /data/repo/" "Copied RPMs to /data/repo" "Failed copying"
            do_cmd "createrepo /data/repo/" "Created RPMs signatures" "failed to create RPMS signatures"
            ;;
        *)
            logMessage "Unknown or Unsupported LINUX_DISTRIBUTION: $LINUX_DISTRIBUTION, exiting"
            exit 1
            ;;
    esac
}

main() {
    detect_linux_distribution # Sets global variable $LINUX_DISTRIBUTION
    init_vars "logon" "cloudstack_packaging"
    start_logging
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
