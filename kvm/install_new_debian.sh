# curl https://plug-mirror.rcac.purdue.edu/debian-cd-archive/12.5.0/s390x/iso-dvd/debian-12.5.0-s390x-DVD-1.iso -o debian-12.5.0-s390x-DVD-1.iso
#testing new instalation of debian in third level (under rh91 guest)
virsh net-start default
virt-install --name debnew125-1 \
             --memory 2048 \
             --vcpus=2 \
             --os-variant=debian11 \
             --location=/mnt/iso/debian/debian-12.5.0-s390x-DVD-1.iso \
             --network network=default \
             --graphics=none \
             -v \
             --disk path=/data/primary/vm/images/debnew125-1.qcow2,size=6 \
             --check disk_size=off

