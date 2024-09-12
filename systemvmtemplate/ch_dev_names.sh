#!/bin/bash
# this file is being called from /opt/cloud/bin/setup/init.sh#22 ;ike that:
# /root/ch_dev_names.sh 2>&1 | tee >> ch_dev_names.log3 # logon addition

#alos i have the  shutd.sh
# \rm -f ch_dev_names.log ch_dev_names.log2 ch_dev_names.log3
# \rm -f /etc/udev/rules.d/70-persistent-net.rules
# echo "systemvm from $(date)" >> template.version
# shutdown -h now


PS4='${BASH_SOURCE}:$LINENO + '
set -x


check_mac_addresses() {
    local rule_file="/etc/udev/rules.d/70-persistent-net.rules"
    local mismatches=0

    # Get all the interfaces except lo
    interfaces=$(ls /sys/class/net | grep -v 'lo')

    # Loop through the interfaces
    for iface in $interfaces; do
        # Get the current MAC address of the interface
        mac=$(ip link show "$iface" | awk '/link\/ether/ {print $2}')

        # Find the corresponding MAC in the rule file
        rule_mac=$(grep -i "NAME=\"$iface\"" "$rule_file" | grep -oP 'ATTR{address}=="\K[^"]+')

        if [ -z "$rule_mac" ]; then
            echo "No MAC address found in rule file for interface $iface"
            mismatches=$((mismatches + 1))
        elif [ "$mac" != "$rule_mac" ]; then
            echo "Mismatch for $iface: current MAC ($mac) does not match rule MAC ($rule_mac)"
            mismatches=$((mismatches + 1))
        else
            echo "MAC address for $iface matches the rule"
        fi
    done

    # Return the number of mismatches
    return $mismatches
}

check_system_devices() {
    echo "Checking for device presence using lszdev and lscss..."

    # Check for devices using lszdev (for s390x devices)
    if command -v lszdev &> /dev/null; then
        echo "Running lszdev:"
        lszdev
    else
        echo "lszdev not found. Install it for detailed device information."
    fi

    # Check CSS (Channel Subsystem) configuration
    if command -v lscss &> /dev/null; then
        echo "Running lscss:"
        lscss
    else
        echo "lscss not found. Install it for CSS device details."
    fi

    echo
    echo "Checking loaded modules..."

    # Check loaded modules to see if required drivers are present
    echo "Currently loaded kernel modules (lsmod):"
    lsmod | grep -E 'qeth|zfcp|dasd|ccw'
    
    # Check for failed drivers or hardware initialization errors in dmesg
    echo
    echo "Checking for hardware initialization errors in dmesg..."
    dmesg | grep -E 'hwup|udevadm|ccw|qeth|zfcp|dasd|Error'

    # Check udev logs to investigate issues with device rules
    echo
    echo "Checking for udev related errors in journalctl..."
    journalctl -xe | grep -E 'udev|hwup|settle|ccw'

    echo
    echo "Checking /var/log/messages or /var/log/syslog (depends on the system)..."
    if [ -f /var/log/messages ]; then
        grep -E 'udev|hwup|settle|ccw|error' /var/log/messages
    elif [ -f /var/log/syslog ]; then
        grep -E 'udev|hwup|settle|ccw|error' /var/log/syslog
    else
        echo "No /var/log/messages or /var/log/syslog found."
    fi

    echo
    echo "Hardware checks complete. Review the output above for issues."
}

# Call the function


init_interfaces_orderby_macs() {
    macs=( $(echo $1 | sed "s/|/ /g") )
    total_nics=${#macs[@]}
    interface_file=${2:-"/etc/network/interfaces"}
    rule_file=${3:-"/etc/udev/rules.d/70-persistent-net.rules"}

    echo -n "auto lo" > $interface_file
    for((i=0; i<total_nics; i++))
    do
        if [[ $i < 3 ]]
        then
           echo -n " eth$i" >> $interface_file
        fi
    done

    cat >> $interface_file << EOF
iface lo inet loopback
EOF

    echo "" > $rule_file

    for((i=0; i < ${#macs[@]}; i++))
    do
        echo "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"${macs[$i]}\", NAME=\"eth$i\"" >> $rule_file
    done
    udevadm control --reload-rules
    udevadm trigger

}

add_apparmor_rule_for_dhclient() {
    # Define the rule to be added
    local rule="/usr/bin/true Px,"

    # Define the AppArmor profile path
    local profile="/etc/apparmor.d/sbin.dhclient"

    # Check if the rule is already present
    if grep -q "$rule" "$profile"; then
        echo "Rule already exists in $profile"
    else
        # Backup the existing profile
        sudo cp "$profile" "${profile}.bak.$(date +%Y%m%d%H%M%S)"

        # Add the rule to the profile
        echo "$rule" | sudo tee -a "$profile" > /dev/null
        sed -i "/bash/a $rule" "$profile"

        echo "Rule added to $profile"

        # Reload the AppArmor profile
        apparmor_parser -r "$profile"
        echo "AppArmor profile reloaded."
    fi
}

change_name_online() {
    OLD_NAME=$1
    NEW_NAME=$2
    ip link set dev $OLD_NAME down
    #Replace <old_interface_name> with the current interface name (e.g., enc1).
    #Rename the interfaces manually (if supported by the system):
    ip link set dev $OLD_NAME $NEW_NAME
    #Replace <old_interface_name> with the current interface name (e.g., enc1), and <new_interface_name> with the desired new name (e.g., eth0).
    #Bring the interfaces back up:
    ip link set dev $NEW_NAME up
}

write_log() {
    cat << EOF > $1
==== Erase this file to enable reboot ================== $(date)
$(ip a)
$(cat $rule_file)
======================================
EOF
}
# Define the AppArmor profile path
local profile="/etc/apparmor.d/sbin.dhclient"
# Check if the rule is already present
apparmor_parser -r "$profile"

# Get all network interfaces
interfaces=$(ip -br link show | awk '{print $1}')

# Iterate over each interface and get IP and MAC addresses
macs=""
need_to_reboot=0
i=0
for iface in $interfaces; do
    mac=$(ip link show "$iface" | awk '/link\/ether/ {print $2}')
    ip=$(ip -br addr show "$iface" | awk '{print $3}')
    echo "$iface: MAC=$mac, IP=$ip"
    # change_name_online $iface eth$i
    i=$((i+1))
    if ! [[ $iface == eth* ]]; then
      if ! [[ $iface == lo ]]; then
       need_to_reboot=1
      fi
    fi
    macs=${macs}"|"${mac}
done

local rule="/usr/bin/true Px,"
# Define the AppArmor profile path
local profile="/etc/apparmor.d/sbin.dhclient"
# Check if the rule is already present
if ! grep -q "$rule" "$profile"; then
   add_apparmor_rule_for_dhclient
else
   echo "Rule already exists in $profile"
fi

if [ "$need_to_reboot" -eq 1 ]; then
    if ! [ -f /root/ch_dev_names.log ]; then
        init_interfaces_orderby_macs $macs
        write_log /root/ch_dev_names.log
        #cat $rule_file
        reboot
    else
        # the log already exists, this is a seond boot
        check_mac_addresses
        nerr=$?
        if [ $nerr -ne 0 ]; then
            echo "Error: $nerr MAC addresses found" >> /root/ch_dev_names.log
            echo "need to regenerate $profile"
            if ! [ -f /root/ch_dev_names.log2 ]; then
                #create the rules for the second time
                init_interfaces_orderby_macs $macs
                write_log /root/ch_dev_names.log2
                reboot
            else
                echo "Error: $nerr MAC addresses found" >> /root/ch_dev_names.log2
            fi
        fi
    fi
fi

