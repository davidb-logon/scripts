#!/bin/bash

#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

script_ended_ok=false
trap 'cleanup' EXIT

main() {
    start_time=$(date +%s)
    usage
    init_vars "logon" "cloudstack"
    start_logging
    check_if_root

    install_qemu_prerequisites
    compile_qemu
    test_x86_64_image

    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    logMessage "The script took $elapsed_time seconds to complete."
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}

parse_command_line_arguments() {
    # if [[ $# -lt 1 || $# -gt 2 ]]; then
    #     usage
    #     exit
    # fi
    temp=1
}

install_qemu_prerequisites() {
    logMessage "Start installing qemu prerequisites"
    do_cmd "yum install cmake -y"
    do_cmd "yum install sparse -y"
    do_cmd "yum install glib2-devel -y"
    do_cmd "yum install flex -y"
    do_cmd "pip3 install tomli"

    # had to compile the utility ninja
    # git clone https://github.com/ninja-build/ninja.git
    logMessage "End installing qemu prerequisites"
}

compile_qemu() {
    logMessage "Start compiling qemu"
    cd /data
    if ! [ -d qemu ]; then  
        logMessage "qemu dir does not exists. cloning."
        do_cmd "git clone https://git.qemu.org/git/qemu.git"
    fi
    cd qemu
    do_cmd "./configure --target-list='x86_64-softmmu' --enable-kvm"
    do_cmd "make"           
    do_cmd "make install"
    logMessage "End compiling qemu"
}

test_x86_64_image() {
    logMessage "Start testing image"
    do_cmd "qemu-system-x86_64 -hda /data/mainframe_secondary/template/tmpl/1/3/c5f8b5e2-e592-4c1a-8fc0-5dc3abcdf6f6.qcow2"
    logMessage "End testing image"
}


usage() {
cat << EOF
-------------------------------------------------------------------------------
This script 
-------------------------------------------------------------------------------
EOF
script_ended_ok=true
}

main "$@"
