#!/bin/bash
#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------

SCRIPT_PATH="/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt"
SVM_PATH=http://download.cloudstack.org/systemvm/4.19/systemvmtemplate-4.19.1-kvm.qcow2.bz2

sudo $SCRIPT_PATH -m /data/mainframe_secondary -u $SVM_PATH -h kvm -F