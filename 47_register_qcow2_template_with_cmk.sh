#!/bin/bash
#  cmk listOsTypes | jq -r '.ostype[].name' | grep -i ubuntu 
# Set CloudMonkey (cmk) to the desired profile and configure options
cmk set profile cloudstack
cmk set asyncblock true
cmk sync

function register_template() {
    TEMPLATE_NAME="$1"
    HYPERVISOR="kvm"
    FORMAT="QCOW2"
    ZONE_NAME="dlinux_zone"
    IS_PUBLIC="true"
    case "$TEMPLATE_NAME" in
        "CentOS 9 Stream")
            TEMPLATE_DISPLAY_TEXT="CentOS 9 Stream - GenericCloud 20240527.0"
            TEMPLATE_URL="https://cloud.centos.org/centos/9-stream/s390x/images/CentOS-Stream-GenericCloud-9-20240527.0.s390x.qcow2"
            OS_TYPE="CentOS 9"
            ;;
        "Ubuntu 24")
            TEMPLATE_DISPLAY_TEXT="Ubuntu 24.04 LTS (Noble Numbat) daily [20241004]"
            TEMPLATE_URL="https://cloud-images.ubuntu.com/noble/20241004/noble-server-cloudimg-s390x.img"
            OS_TYPE="Ubuntu 22.04 LTS"
            ;;
        "Debian 11.11 s390x")
            TEMPLATE_DISPLAY_TEXT="Debian 11.11 s390x"
            TEMPLATE_URL="http://192.168.122.1:8090/deb11-1-1-clone.qcow2"
            OS_TYPE="Debian GNU/Linux 11.11 (64-bit)"
            ;;
        "Debian 12.5 s390x")
            TEMPLATE_DISPLAY_TEXT=$TEMPLATE_NAME
            TEMPLATE_URL="http://192.168.122.1:8090/deb390-12-6.qcow2"
            OS_TYPE="Debian GNU/Linux 12 (64-bit)"
            ;;
        "AlmaLinux 9.4 s390x")
            TEMPLATE_DISPLAY_TEXT=$TEMPLATE_NAME
            TEMPLATE_URL="https://repo.almalinux.org/almalinux/9/cloud/s390x/images/AlmaLinux-9-GenericCloud-9.4-20240805.s390x.qcow2"
            TEMPLATE_URL="http://192.168.122.1:8090/AlmaLinux-9-GenericCloud-9.4-20240805.s390x.qcow2"
            OS_TYPE="AlmaLinux 9"
            ;;
        *)
            echo "Unknown template: $TEMPLATE_NAME"
            exit 1
            ;;
    esac
    ZONE_ID=$(cmk list zones name="$ZONE_NAME" | jq -r '.zone[] | select(.name=="'"$ZONE_NAME"'") | .id')
    # Register the template
  cmk register template \
    name="$TEMPLATE_NAME" \
    displaytext="$TEMPLATE_DISPLAY_TEXT" \
    url="$TEMPLATE_URL" \
    zoneid="$ZONE_ID" \
    hypervisor="$HYPERVISOR" \
    format="$FORMAT" \
    ostypeid=$(cmk list ostypes description="$OS_TYPE" | jq -r '.ostype[] | select(.description) | .id') \
    ispublic="$IS_PUBLIC"

  # Print confirmation message
  echo "Template '$TEMPLATE_NAME' has been registered successfully in zone '$ZONE_NAME'!"
}



#first the template list
# Define an array with some template names
my_templates=("CentOS 9 Stream" "Ubuntu 24" "Debian 11.11 s390x" "Debian 12.5 s390x" "AlmaLinux 9.4 s390x")

#second get current list of templates
ctemplates=$(cmk listTemplates listall=true templatefilter=all | jq -r '.template[].name')
# echo $ctemplates
# echo "#############################"
# # For loop to iterate over each template
# # Loop through each template from the cmk command
# while IFS= read -r template; do
#     # Check if the template is in the my_templates array
#     if [[ " ${my_templates[*]} " =~ " ${template} " ]]; then
#         echo "Template '$template' is in the array."
#     else
#         echo "Template '$template' is NOT in the array."
#     fi
# done <<< "$ctemplates"

# third - make sure the repo have all needed files

if [ ! -f /data/repo/deb11-1-1-clone.qcow2 ]; then
  cp /data/primary/vm/images/deb11-1-1-clone.qcow2 /data/repo
fi

if [ ! -f /data/repo/deb390-12-6.qcow2 ]; then
  cp /data/primary/vm/images/deb390-12-4-1-clone-clone.qcow2 /data/repo/deb390-12-6.qcow2
fi

echo "############################# start ############################"
for my_template in "${my_templates[@]}"; do
    # Check if the template exists in the ctemplates list
    if echo "$ctemplates" | grep -qFx "$my_template"; then
        echo "Template '$my_template' exists in the list."
    else
        echo "Template '$my_template' does NOT exist in the list."
        register_template "$my_template"
    fi
done


exit 0

# Template details
TEMPLATE_NAME="CentOS 9 Stream"
TEMPLATE_DISPLAY_TEXT="CentOS 9 Stream - GenericCloud 20240527.0"
TEMPLATE_URL="https://cloud.centos.org/centos/9-stream/s390x/images/CentOS-Stream-GenericCloud-9-20240527.0.s390x.qcow2"
HYPERVISOR="kvm"
FORMAT="QCOW2"
OS_TYPE="CentOS 9"
ZONE_NAME="dlinux_zone"
IS_PUBLIC="true"

# Get the Zone ID for the zone named "dlinux_zone" using jq
ZONE_ID=$(cmk list zones name="$ZONE_NAME" | jq -r '.zone[] | select(.name=="'"$ZONE_NAME"'") | .id')

# Ensure the zone was found
if [ -z "$ZONE_ID" ]; then
  echo "Error: Zone '$ZONE_NAME' not found!"
  exit 1
fi

# Register the template
cmk register template \
  name="$TEMPLATE_NAME" \
  displaytext="$TEMPLATE_DISPLAY_TEXT" \
  url="$TEMPLATE_URL" \
  zoneid="$ZONE_ID" \
  hypervisor="$HYPERVISOR" \
  format="$FORMAT" \
  ostypeid=$(cmk list ostypes description="$OS_TYPE" | jq -r '.ostype[] | select(.description | contains("CentOS")) | .id') \
  ispublic="$IS_PUBLIC"

# Print confirmation message
echo "Template '$TEMPLATE_NAME' has been registered successfully in zone '$ZONE_NAME'!"


# Template details
TEMPLATE_NAME="Ubuntu 24.04 LTS"
TEMPLATE_DISPLAY_TEXT="Ubuntu 24.04 LTS (Noble Numbat) daily [20241004]"
TEMPLATE_URL="https://cloud-images.ubuntu.com/noble/20241004/noble-server-cloudimg-s390x.img"
HYPERVISOR="kvm"
FORMAT="QCOW2"
OS_TYPE="UBUNTU 24.04 LTS"
ZONE_NAME="dlinux_zone"
IS_PUBLIC="true"

# Get the Zone ID for the zone named "dlinux_zone" using jq
ZONE_ID=$(cmk list zones name="$ZONE_NAME" | jq -r '.zone[] | select(.name=="'"$ZONE_NAME"'") | .id')

# Ensure the zone was found
if [ -z "$ZONE_ID" ]; then
  echo "Error: Zone '$ZONE_NAME' not found!"
  exit 1
fi

# Register the template
cmk register template \
  name="$TEMPLATE_NAME" \
  displaytext="$TEMPLATE_DISPLAY_TEXT" \
  url="$TEMPLATE_URL" \
  zoneid="$ZONE_ID" \
  hypervisor="$HYPERVISOR" \
  format="$FORMAT" \
  ostypeid=$(cmk list ostypes description="$OS_TYPE" | jq -r '.ostype[] | select(.description | contains("CentOS")) | .id') \
  ispublic="$IS_PUBLIC"

# Print confirmation message
echo "Template '$TEMPLATE_NAME' has been registered successfully in zone '$ZONE_NAME'!"


#################################################### debian 
if [ ! -f /data/repo/deb11-1-1-clone.qcow2 ]; then
  cp /data/primary/vm/images/deb11-1-1-clone.qcow2 /data/repo
fi
start_web_server_on_repo.sh
# Template details
TEMPLATE_NAME="Debian 11.11 s390x"
TEMPLATE_DISPLAY_TEXT="Debian 11.11 s390x"
REPO_PATH="http://192.168.122.1:8090"
TEMPLATE_URL=$REPO_PATH/deb11-1-1-clone.qcow2
HYPERVISOR="kvm"
FORMAT="QCOW2"
#OS_TYPE="Debian GNU/Linux 9 (64-bit)"
#OS_TYPE="UBUNTU 24.04 LTS"
OS_TYPE="CentOS 9"
ZONE_NAME="dlinux_zone"
IS_PUBLIC="true"
 

# Get the Zone ID for the zone named "dlinux_zone" using jq
ZONE_ID=$(cmk list zones name="$ZONE_NAME" | jq -r '.zone[] | select(.name=="'"$ZONE_NAME"'") | .id')

# Ensure the zone was found
if [ -z "$ZONE_ID" ]; then
  echo "Error: Zone '$ZONE_NAME' not found!"
  exit 1
fi
set -x
# Register the template
cmk register template \
  name="$TEMPLATE_NAME" \
  displaytext="$TEMPLATE_DISPLAY_TEXT" \
  url="$TEMPLATE_URL" \
  zoneid="$ZONE_ID" \
  hypervisor="$HYPERVISOR" \
  format="$FORMAT" \
  ostypeid=$(cmk list ostypes description="$OS_TYPE" | jq -r '.ostype[] | select(.description | contains("CentOS")) | .id') \
  ispublic="$IS_PUBLIC"
set +x
# Print confirmation message
echo "Template '$TEMPLATE_NAME' has been registered successfully in zone '$ZONE_NAME'!"
