

# on our nfs server we did:
# wget https://cdimage.debian.org/cdimage/archive/11.11.0/s390x/iso-cd/debian-11.11.0-s390x-netinst.iso
# on our dlinux make sure the nfs iso is mounted to /mnt/iso:
# mkdir -p /mnt/iso;mount -t nfs 54.227.191.101:/iso /mnt/iso
# on the host s390x machine we did:
virsh destroy  deb11-b
virsh undefine deb11-b --remove-all-storage
# virt-install --name deb11-b \
#     --memory 2048 \
#     --vcpus=2 \
#     --os-variant=debian11 \
#     --graphics none \
#     --console pty,target_type=serial \
#     -v \
#     --disk path=/data/primary/vm/images/deb11-b.qcow2,size=6 \
#     --check disk_size=off \
#     --location=/mnt/iso/debian/debian-11.11.0-s390x-netinst.iso \
#     --initrd-inject="/data/scripts/systemvmtemplate/http/preseed_simple.cfg" \
#     --extra-args="auto=true priority=critical net.ifnames=0 biosdevname=0 preseed/file=/preseed_simple.cfg s390-netdevice/choose_networktype=virtio DEBCONF_DEBUG=5 DEBIAN_FRONTEND=noninteractive auto-install/enable=true interface=eth0"


virt-install --name deb11-b \
--vcpus 2 \
--memory 2048 \
--disk size=5,bus=virtio,format=qcow2 \
--boot cdrom,hd \
--network bridge=virbr0 \
--graphics none \
--console pty,target_type=sclp \
--location=/mnt/iso/debian/debian-11.11.0-s390x-netinst.iso \
--initrd-inject="/data/scripts/systemvmtemplate/http/preseed_simple.cfg" \
--extra-args="locale=en_US auto=true priority=critical s390-netdevice/choose_networktype=virtio netcfg/use_autoconfig=true netcfg/disable_dhcp=false netcfg/get_hostname=ubu-vm-03 netcfg/get_domain=domain.com network-console/password=instpass network-console/start=true file=file:/preseed.cfg"



# --network network=default \
# --noautoconsole \





# virt-install \
#     --name debian-vm \
#     --ram 2048 \
#     --vcpus 2 \
#     --disk size=20 \
#     --os-type linux \
#     --os-variant debian11 \
#     --location 'http://deb.debian.org/debian/dists/bullseye/main/installer-amd64/' \
#     --extra-args="auto=true priority=critical  s390-netdevice=virtio preseed/file=/preseed.cfg" \
#     --initrd-inject=/path/to/your/preseed.cfg \
#     --graphics none