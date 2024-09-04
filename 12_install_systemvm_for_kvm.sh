#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
set -x
SCRIPT_PATH="/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt"
#SVM_PATH=http://download.cloudstack.org/systemvm/4.19/systemvmtemplate-4.19.1-kvm.qcow2.bz2
SVM_PATH=http://localhost:8090/deb390-12-4-1.qcow2.bz2
DOAMIN="deb390-12-4"
virsh destroy $DOAMIN
sleep 3
bzip2 -kv $SVM_PATH
SVM_PATH=$(virsh dumpxml deb390-12-4 | grep 'source file' |  grep -oP "file='\K[^']+")
sudo $SCRIPT_PATH -m /data/mainframe_secondary -u ${SVM_PATH}.bz2 -h kvm -F