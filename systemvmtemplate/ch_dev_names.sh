#!/bin/bash

PS4='${BASH_SOURCE}:$LINENO + '
set -x

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
        sudo sed -i "/bash/a $rule" "$profile"

        echo "Rule added to $profile"

        # Reload the AppArmor profile
        sudo apparmor_parser -r "$profile"
        echo "AppArmor profile reloaded."
    fi
}



# Get all network interfaces
interfaces=$(ip -br link show | awk '{print $1}')

# Iterate over each interface and get IP and MAC addresses
macs=""
need_to_reboot=0
for iface in $interfaces; do
    mac=$(ip link show "$iface" | awk '/link\/ether/ {print $2}')
    ip=$(ip -br addr show "$iface" | awk '{print $3}')
    echo "$iface: MAC=$mac, IP=$ip"
    if ! [[ $iface == eth* ]]; then
    need_to_reboot=1
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
  init_interfaces_orderby_macs $macs
  cat $rule_file
  reboot
fi    