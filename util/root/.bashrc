# .bashrc
# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

function qipa() {
    local vm_name="$1"

    # Execute the ip -br a command inside the VM and get the PID
    local exec_command='{"execute":"guest-exec", "arguments":{"path":"/bin/ip", "arg":["-br", "a"], "capture-output":true}}'
    local exec_result=$(virsh qemu-agent-command "$vm_name" "$exec_command")
    local pid=$(echo "$exec_result" | grep -oP '(?<="pid":)\d+')

    if [ -z "$pid" ]; then
        echo "Failed to execute the command in the VM."
        return 1
    fi

    # Fetch the command status using the PID
    local status_command='{"execute":"guest-exec-status", "arguments":{"pid":'"$pid"'}}'
    local status_result=$(virsh qemu-agent-command "$vm_name" "$status_command")

    # Extract base64 encoded output
    local encoded_output=$(echo "$status_result" | grep -oP '(?<="out-data":")[^"]+')

    if [ -z "$encoded_output" ]; then
        echo "Failed to retrieve the command output."
        return 1
    fi

    # Decode the base64 output
    echo "$encoded_output" | base64 --decode
}

# Example usage:
# qemu_agent_ip_br_a "deb11-systemvm"


function qls_root() {
    local vm_name="$1"

    # Execute the ls /root command inside the VM and get the PID
    local exec_command='{"execute":"guest-exec", "arguments":{"path":"/bin/ls", "arg":["/root"], "capture-output":true}}'
    local exec_result=$(virsh qemu-agent-command "$vm_name" "$exec_command")
    local pid=$(echo "$exec_result" | grep -oP '(?<="pid":)\d+')

    if [ -z "$pid" ]; then
        echo "Failed to execute the command in the VM."
        return 1
    fi

    # Fetch the command status using the PID
    local status_command='{"execute":"guest-exec-status", "arguments":{"pid":'"$pid"'}}'
    local status_result=$(virsh qemu-agent-command "$vm_name" "$status_command")

    # Extract base64 encoded output
    local encoded_output=$(echo "$status_result" | grep -oP '(?<="out-data":")[^"]+')

    if [ -z "$encoded_output" ]; then
        echo "Failed to retrieve the command output."
        return 1
    fi

    # Decode the base64 output
    echo "$encoded_output" | base64 --decode
}

# Example usage:
# qemu_agent_ls_root "deb11-systemvm"


function vssh(){
HOST=$1
set -x
HOSTIP=$(vnd $HOST | grep 169.254 )
ip=$(echo "$HOSTIP" | grep -oE '169\.[0-9]+\.[0-9]+\.[0-9]+')
ssh  -p 3922 -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa.cloud root@$ip
set +x
}
function vsc() {
    vm_name="$1"

    # Check if the default network is active
    if virsh net-info default | grep -q 'Active:         yes'; then
        echo "The 'default' network is already active."
    else
        echo "The 'default' network is not active. Starting it..."
        virsh net-start default
        if [ $? -ne 0 ]; then
            echo "Failed to start the 'default' network."
            return 1
        fi
    fi

    # Start the VM
    echo "Starting the VM: $vm_name"
    virsh start "$vm_name"
    if [ $? -ne 0 ]; then
        echo "Failed to start the VM: $vm_name."
        return 1
    fi

    # Connect to the console
    echo "Connecting to the console of the VM: $vm_name"
    virsh console "$vm_name"
}
function vnd(){
   vm_name="$1"

    # Function to get IPs for a given VM using domifaddr
    get_ip_for_vm() {
        local vm="$1"
        # Get all IP addresses associated with the VM
        ip_info=$(virsh domifaddr "$vm" --source agent 2>/dev/null | grep ipv4 | awk '{print $4}' | cut -d'/' -f1 | tr '\n' ' ')

        if [ -n "$ip_info" ]; then
            echo "VM: $vm, IP: $ip_info"
        else
            echo "VM: $vm, IP: Not found or Guest Agent not installed"
        fi
    }

    # Check if a VM name was passed
    if [ -n "$vm_name" ]; then
        # Report IP for the specified VM
        get_ip_for_vm "$vm_name"
    else
        # Get a list of all online VMs
        vm_list=$(virsh list --name)

        # Loop through each VM and fetch its IP
        for vm in $vm_list; do
            get_ip_for_vm "$vm"
        done
    fi
}

function vndo(){
   vm_name="$1"

    # Function to get IPs for a given VM using domifaddr
    get_ip_for_vm() {
        local vm="$1"
        # Get IP addresses associated with the VM
        ip_info=$(virsh domifaddr "$vm" --source agent 2>/dev/null | grep ipv4 | awk '{print $4}' | cut -d'/' -f1)

        if [ -n "$ip_info" ]; then
            echo "VM: $vm, IP: $ip_info"
        else
            echo "VM: $vm, IP: Not found or Guest Agent not installed"
        fi
    }

    # Check if a VM name was passed
    if [ -n "$vm_name" ]; then
        # Report IP for the specified VM
        get_ip_for_vm "$vm_name"
    else
        # Get a list of all online VMs
        vm_list=$(virsh list --name)

        # Loop through each VM and fetch its IP
        for vm in $vm_list; do
            get_ip_for_vm "$vm"
        done
    fi
}

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi
if [ -f ~/.bash_alias  ]; then
        . ~/.bash_alias
fi
if [ ! -f /mnt/linuxu/workstation/.bashrc ]; then
# mkdir -p /mnt/linuxu
# mount -t nfs 10.0.78.231:/linuxu /mnt/linuxu
# mount -t nfs 54.227.191.101:/iso /mnt/iso
# mount -t nfs 54.227.191.101:/linuxu /mnt/linuxu/
 mkdir -p /mnt/linuxu;mount -t nfs 54.227.191.101:/linuxu /mnt/linuxu;alias m='/mnt/linuxu/m.sh'
 mkdir -p /mnt/iso;mount -t nfs 54.227.191.101:/iso /mnt/iso
fi
export PATH="/data/scripts:/data/scripts/util:$PATH"
export M2_HOME=/usr/bin/maven
export PATH=${M2_HOME}/bin:${PATH}
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.14.1.1-6.el8.s390x
export PATH=${JAVA_HOME}/bin:${PATH}
export PATH=/usr/local/nodejs/bin:$PATH
export PATH=/usr/local/bin:/usr/local/go/bin:$PATH
export PATH=/usr/local/glib-2.66.8/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/glib-2.66.8/lib64:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=/usr/local/glib-2.66.8/lib64/pkgconfig:$PKG_CONFIG_PATH
# Split the PATH by ':' and convert it to an array
IFS=':' read -r -a path_array <<< "$PATH"

# Use awk to remove duplicates while preserving order
unique_path=$(printf "%s\n" "${path_array[@]}" | awk '!seen[$0]++' | paste -sd ':' -)

# Set the cleaned PATH
export PATH="$unique_path"

# Print the cleaned PATH
#echo "Cleaned PATH: $PATH"
export PATH=/usr/local/glib-2.66.8/bin:/usr/local/bin:/usr/local/go/bin:/usr/local/nodejs/bin:/usr/lib/jvm/java-11-openjdk-11.0.14.1.1-6.el8.s390x/bin:/usr/bin/maven/bin:/data/scripts:/data/scripts/util:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:
