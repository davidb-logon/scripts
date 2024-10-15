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
    init_vars "logon" "cloudstack-setup-systemvm"
    start_logging
    check_if_root
    do_cmd "rm -f exec.log"
    echo "@@@@@@@ Start executing scripts in order: $(date "+%m-%d %H:%M:%S")" | tee -a  exec.log

    echo "@@@@@@@ Doing apt_upgrade.sh: $(date "+%m-%d %H:%M:%S")" | tee -a exec.log
    do_cmd "/home/sefi/scripts/apt_upgrade.sh  2>&1 | tee -a  exec.log"

    echo "@@@@@@@ Doing configure_locale.sh: $(date "+%m-%d %H:%M:%S")" | tee -a exec.log
    do_cmd "/home/sefi/scripts/configure_locale.sh 2>&1 | tee -a exec.log"

    echo "@@@@@@@ Doing configure_networking.sh: $(date "+%m-%d %H:%M:%S")" | tee -a exec.log
    do_cmd "/home/sefi/scripts/configure_networking.sh 2>&1 | tee -a exec.log"

    echo "@@@@@@@ Doing configure_acpid.sh: $(date "+%m-%d %H:%M:%S")" | tee -a exec.log
    do_cmd "/home/sefi/scripts/configure_acpid.sh 2>&1 | tee -a exec.log"

    echo "@@@@@@@ Doing install_systemvm_packages.sh: $(date "+%m-%d %H:%M:%S")" | tee -a exec.log
    do_cmd "/home/sefi/scripts/install_systemvm_packages.sh 2>&1 | tee -a exec.log"
    # confirm "Continue?" || exit 1

    echo "@@@@@@@ Doing configure_conntrack.sh: $(date "+%m-%d %H:%M:%S")" | tee -a exec.log
    do_cmd "/home/sefi/scripts/configure_conntrack.sh 2>&1 | tee -a exec.log"

    echo "@@@@@@@ Doing authorized_keys.sh: $(date "+%m-%d %H:%M:%S")" | tee -a exec.log
    do_cmd "/home/sefi/scripts/authorized_keys.sh 2>&1 | tee -a exec.log"

    echo "@@@@@@@ Doing configure_persistent_config.sh: $(date "+%m-%d %H:%M:%S")" | tee -a exec.log
    do_cmd "/home/sefi/scripts/configure_persistent_config.sh 2>&1 | tee -a exec.log"

    echo "@@@@@@@ Doing configure_login.sh: $(date "+%m-%d %H:%M:%S")" | tee -a exec.log
    do_cmd "/home/sefi/scripts/configure_login.sh 2>&1 | tee -a exec.log"

    echo "@@@@@@@ Doing cloud_scripts_shar_archive.sh: $(date "+%m-%d %H:%M:%S")" | tee -a exec.log
    do_cmd "/home/sefi/cloud_scripts_shar_archive.sh 2>&1 | tee -a exec.log"

    echo "@@@@@@@ Doing configure_systemvm_services.sh: $(date "+%m-%d %H:%M:%S")" | tee -a exec.log
    do_cmd "/home/sefi/scripts/configure_systemvm_services.sh 2>&1 | tee -a exec.log"

    echo "@@@@@@@ Doing cleanup.sh: $(date "+%m-%d %H:%M:%S")" | tee -a exec.log
    do_cmd "/home/sefi/scripts/cleanup.sh 2>&1 | tee -a exec.log"

    echo "@@@@@@@ Doing finalize.sh: $(date "+%m-%d %H:%M:%S")" | tee -a exec.log
    do_cmd "/home/sefi/scripts/finalize.sh 2>&1 | tee -a exec.log"

    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    logMessage "The script took $elapsed_time seconds to complete."
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}

main