#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
set -x
SCRIPT_PATH="/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt"
#SVM_PATH=http://download.cloudstack.org/systemvm/4.19/systemvmtemplate-4.19.1-kvm.qcow2.bz2
SVM_PATH=http://localhost:8090/systemvmtemplate-deb12-s390x.qcow2.bz2

sudo $SCRIPT_PATH -m /data/mainframe_secondary -u $SVM_PATH -h kvm -F
exit

mkdir -p /data/test_qemu
cd /data/test_qemu
if ! [ -f systemvmtemplate-4.19.1-kvm.qcow2 ]; then
    wget $SVM_PATH
    bzip2 -d systemvmtemplate-4.19.1-kvm.qcow2.bz2
fi
cat > /data/test_qemu/systemvmtemplate.xml <<EOF
<!-- domain type need to be qemu -->
<domain type='qemu'>
  <name>systemvm-1</name>
  <memory unit='MiB'>1024</memory>
  <vcpu placement='static'>1</vcpu>
  <os>
    <type arch='x86_64' machine='pc-i440fx-5.1'>hvm</type>
    <boot dev='hd'/>
  </os>
  <devices>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
	  <!-- path to the qcow2 file -->
      <source file='/data/test_qemu/systemvmtemplate-4.19.1-kvm.qcow2'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <interface type='network'>
      <source network='default'/>
    </interface>
  <!-- Other device configurations here -->
  <console type='pty'>
    <target type='serial' port='0'/>
  </console>

  </devices>
<!-- i added this to evoid the error -no-acpi when starting the machine -->  
 <features>
   <pae/>
   <apic/>
   <acpi/>
  </features>
</domain>
EOF
virsh undefine systemvm-1
virsh define systemvmtemplate.xml 
virsh start systemvm-1
virsh console systemvm-1

