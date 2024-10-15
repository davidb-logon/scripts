#!/bin/bash

# Set CloudMonkey (cmk) to the desired profile and configure options
cmk set profile cloudstack
cmk set asyncblock true

# Template details
TEMPLATE_NAME="CentOS 9 Stream"
TEMPLATE_DISPLAY_TEXT="CentOS 9 Stream - GenericCloud 20240527.0"
TEMPLATE_URL="https://cloud.centos.org/centos/9-stream/s390x/images/CentOS-Stream-GenericCloud-9-20240527.0.s390x.qcow2"
HYPERVISOR="kvm"
FORMAT="QCOW2"
OS_TYPE="CentOS"
ZONE_ID="<your-zone-id>"
IS_PUBLIC="true"

# Register the template
cmk register template \
  name="$TEMPLATE_NAME" \
  displaytext="$TEMPLATE_DISPLAY_TEXT" \
  url="$TEMPLATE_URL" \
  zoneid="$ZONE_ID" \
  hypervisor="$HYPERVISOR" \
  format="$FORMAT" \
  ostypeid=$(cmk list ostypes description="$OS_TYPE" | grep -i 'CentOS' | awk '{print $2}') \
  ispublic="$IS_PUBLIC"

# Print confirmation message
echo "Template '$TEMPLATE_NAME' has been registered successfully!"
