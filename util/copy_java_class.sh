#!/bin/bash
set -x
ssh dlinux "systemctl stop cloudstack-agent"
TREE="com/cloud/hypervisor/kvm/resource/wrapper"
SRC_DIR="/home/davidb/logon/cloudstack/plugins/hypervisors/kvm/target/classes/$TREE"
DST_DIR="/home/davidb/logon/java-classes/$TREE"
scp ${SRC_DIR}/LibvirtStartCommandWrapper.class dlinux:${DST_DIR}/.
ssh dlinux "systemctl start cloudstack-agent"
