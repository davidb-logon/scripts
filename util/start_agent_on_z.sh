
#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

# Source script libraries as needed.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$DIR/lib/common.sh"

script_ended_ok=false
trap 'cleanup' EXIT

init_vars() {
    init_utils_vars $1 $2
    
}

main() {
    init_vars "logon" "cs_agent_restart"
    start_logging
    do_cmd "sudo systemctl stop cloudstack-agent.service" "Stopped cloudstack agent"
    do_cmd "sudo truncate --size 0 /var/log/cloudstack/agent/agent.log" "Emptied agent log file"     
    do_cmd "sudo virsh net-define /home/davidb/libvirt.backup/qemu/networks/default.xml --validate" "Defined default network"
    do_cmd "sudo virsh net-autostart default" "Made default network autostart"
    do_cmd "sudo virsh net-start default" "Started default network"
    sleep 5
    do_cmd "sudo sudo systemctl start cloudstack-agent.service" "Started agent"
    script_ended_ok=true
}
    
main "$@"
