#install packer - very long compilation time
# cd /data
# git clone https://github.com/hashicorp/packer.git
# cd packer
# make bin


virsh net-start default
virt-install --name deb390-12-1 \
     --memory 2048 \
     --vcpus=2  \
     --os-variant=debian11   \
     --location=/data/iso/debian-12.5.0-s390x-netinst.iso  \
     --network network=default   \
     --graphics=none -v \
     --disk path=/data/primary/vm/images/deb390-12-1.qcow2,size=6   \
     --check disk_size=off

