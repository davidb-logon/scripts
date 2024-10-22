#!/bin/bash

# Set CloudMonkey (cmk) to the desired profile and configure options
cmk set profile cloudstack
cmk set asyncblock true
cmk sync

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
if [ ! -f /data/repo/deb11-1-1.qcow2 ]; then
  cp /data/primary/vm/images/deb11-1-1.qcow2 /data/repo
fi
start_web_server_on_repo.sh
# Template details
TEMPLATE_NAME="Debian 11.11 s390x"
TEMPLATE_DISPLAY_TEXT="Debian 11.11 s390x"
REPO_PATH="http://localhost:8090/deb11-1-1.qcow2"
TEMPLATE_URL=$REPO_PATH
HYPERVISOR="kvm"
FORMAT="QCOW2"
OS_TYPE="Debian GNU/Linux 9 (64-bit)"
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
