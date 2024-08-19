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
    init_vars "logon" "install_qemu_for_x86_64_on_Z"
    start_logging
    check_if_root

    install_qemu_prerequisites
    compile_qemu
    #test_x86_64_image

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
    do_cmd "yum update -y"
    do_cmd "yum install cmake -y"
    do_cmd "yum install sparse -y"
    do_cmd "yum install glib2-devel -y"
    do_cmd "yum install flex -y"
    do_cmd "yum install gnutls-devel -y"

    install_re2c
    logMessage "Installing python qemu prerequisites"
    do_cmd "python3.8 -m pip install tomli sphinx sphinx_rtd_theme meson ninja"
    ln -fs /usr/local/bin/meson /usr/bin/meson
    logMessage "Installing ninja"
    
    cd /data
    if ! [ -d ninja ]; then
        do_cmd "git clone https://github.com/ninja-build/ninja.git"
    fi
    cd ninja
    do_cmd "./configure.py --bootstrap"
    do_cmd "ln -fs /data/ninja/ninja /usr/bin/ninja"
    logMessage "Installing glib2 version 2.66.0"
    install_glib2
    logMessage "End installing qemu prerequisites"
}

install_re2c() {
    logMessage "Start installing re2c"
    local version="3.1"
    local workdir="/data"

    # Ensure the working directory exists
    do_cmd "cd ${workdir}"

    # Download the source code
    do_cmd "wget https://github.com/skvadrik/re2c/releases/download/${version}/re2c-${version}.tar.xz"

    # Extract the tarball
    do_cmd "tar -xvf re2c-${version}.tar.xz"

    # Change to the source directory
    do_cmd "cd re2c-${version}"

    # Build and install
    do_cmd "./configure"
    do_cmd "make"
    do_cmd "make install"
    cd ..
    logMessage "End installing re2c"
}

install_glib2() {
    # Variables
    GLIB_VERSION="2.66.0"
    GLIB_URL="https://download.gnome.org/sources/glib/2.66/glib-${GLIB_VERSION}.tar.xz"

    do_cmd "yum groupinstall -y 'Development Tools'"
    do_cmd "yum install -y wget gettext-devel libffi-devel zlib-devel"
    do_cmd "yum install -y libmount libselinux"
    cd /data
    
    do_cmd "rm -rf glib-${GLIB_VERSION}"
    do_cmd "wget ${GLIB_URL} -O glib-${GLIB_VERSION}.tar.xz"
    do_cmd "tar -xf glib-${GLIB_VERSION}.tar.xz"
    do_cmd "cd glib-${GLIB_VERSION}"

    # Configure, compile, and install glib2
    do_cmd "mkdir -p build"
    cd build
    do_cmd "meson setup .. --prefix=/usr/local"
    do_cmd "ninja"
    do_cmd "ninja install"
    #do_cmd "export PKG_CONFIG_PATH=/usr/local/lib64/pkgconfig"
    do_cmd "export PKG_CONFIG_PATH=/usr/local/glib-2.66.8/lib64/pkgconfig"
    # Update library cache
    do_cmd "ldconfig"

    # Verify the installation
    if pkg-config --modversion glib-2.0; then
        logMessage "glib2 version ${GLIB_VERSION} installed successfully."
    else
        logMessage "Failed to install glib2 version ${GLIB_VERSION}."
    fi

    # Cleanup
    cd ..
    rm -rf glib-${GLIB_VERSION} glib-${GLIB_VERSION}.tar.xz
}

compile_qemu() {
    logMessage "Start compiling qemu"
    cd /data
    if ! [ -d qemu ]; then  
        logMessage "qemu dir does not exists. cloning."
        do_cmd "git clone https://git.qemu.org/git/qemu.git"
        do_cmd "git fetch"
        do_cmd "git checkout -b stable-8.2 origin/stable-8.2" # version 9 is not compatible with our virsh
    fi
    cd qemu
    do_cmd "./configure --target-list='x86_64-softmmu' --enable-kvm --python=python3.8 --enable-gnutls"
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
