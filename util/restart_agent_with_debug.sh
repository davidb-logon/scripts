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
    init_vars "logon" "cloudstack-restart-agent-with-debug"
    start_logging
    check_if_root

    logMessage "--- Updating /etc/cloudstack/agent/log4j-cloud.xml to DEBUG level"
    sed -i 's/value="INFO"/value="DEBUG"/g' /etc/cloudstack/agent/log4j-cloud.xml

    do_cmd "systemctl stop cloudstack-agent"
    do_cmd "truncate --size=0 /var/log/cloudstack/agent/agent.log
    do_cmd "systemctl start cloudstack-agent

    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    logMessage "The script took $elapsed_time seconds to complete."
    script_ended_ok=true
}

init_vars() {
    init_utils_vars $1 $2
}

# main
main "$@"
