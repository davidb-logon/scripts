

# on our nfs server we did:
# wget https://cdimage.debian.org/cdimage/archive/11.11.0/s390x/iso-cd/debian-11.11.0-s390x-netinst.iso
# on our dlinux make sure the nfs iso is mounted to /mnt/iso:
# mkdir -p /mnt/iso;mount -t nfs 54.227.191.101:/iso /mnt/iso
# on the host s390x machine we did:
virsh undefine deb11-a
virt-install --name deb11-a \
    --memory 2048 \
    --vcpus=2 \
    --os-variant=debian11 \
    --graphics=none \
    -v \
    --disk path=/data/primary/vm/images/deb11-a.qcow2,size=6 \
    --check disk_size=off \
    --location=/mnt/iso/debian/debian-11.11.0-s390x-netinst.iso \
    --extra-args="auto=true priority=critical preseed/file=preseed_s390x.cfg DEBIAN_FRONTEND=noninteractive auto-install/enable=true" \
    --initrd-inject="/data/scripts/systemvmtemplate/http/preseed_s390x.cfg"

# --network network=default \






# virt-install \
#     --name debian-vm \
#     --ram 2048 \
#     --vcpus 2 \
#     --disk size=20 \
#     --os-type linux \
#     --os-variant debian11 \
#     --location 'http://deb.debian.org/debian/dists/bullseye/main/installer-amd64/' \
#     --extra-args="auto=true priority=critical preseed/file=/preseed.cfg" \
#     --initrd-inject=/path/to/your/preseed.cfg \
#     --graphics none