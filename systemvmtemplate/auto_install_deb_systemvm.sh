

# on our nfs server we did:
# wget https://cdimage.debian.org/cdimage/archive/11.11.0/s390x/iso-cd/debian-11.11.0-s390x-netinst.iso
# on our dlinux make sure the nfs iso is mounted to /mnt/iso:
# mkdir -p /mnt/iso;mount -t nfs 54.227.191.101:/iso /mnt/iso
# on the host s390x machine we did:
virsh undefine deb11-a --remove-all-storage
parms1=" netcfg/get_ipaddress=192.168.124.100 netcfg/get_netmask=255.255.255.0 netcfg/get_gateway=192.168.124.1 netcfg/get_nameservers=8.8.8.8 "
parms2=" network-console/password=password network-console/password-again password passwd/root-password=password passwd/root-password-again=password"
parms3=" passwd/root-password=password passwd/root-password-again=password"
virt-install --name deb11-a \
    --memory 2048 \
    --vcpus=2 \
    --os-variant=debian11 \
    --graphics=none \
    -v \
    --disk path=/data/primary/vm/images/deb11-a.qcow2,size=6 \
    --check disk_size=off \
    --location=/mnt/iso/debian/debian-11.11.0-s390x-netinst.iso \
    --extra-args="priority=critical $parms1 s390-netdevice/choose_networktype=virtio preseed/url=http://localhost:8090/preseed_s390x.cfg DEBCONF_DEBUG=5 DEBIAN_FRONTEND=noninteractive auto-install/enable=true"




# --network network=default \
#    --extra-args="auto=true priority=critical preseed/file=/preseed_s390x.cfg DEBCONF_DEBUG=5 DEBIAN_FRONTEND=noninteractive auto-install/enable=true" \
#    --extra-args="auto=true priority=critical s390-netdevice/choose_networktype=virtio $parms1 $parms2 $parms3 file=/preseed_s390x.cfg DEBCONF_DEBUG=5 DEBIAN_FRONTEND=noninteractive auto-install/enable=true" \
#     --extra-args="auto=true priority=critical s390-netdevice/choose_networktype=virtio $parms1 $parms2 $parms3 preseed/url=http://localhost:8090/preseed_s390x.cfg DEBCONF_DEBUG=5 DEBIAN_FRONTEND=noninteractive auto-install/enable=true"







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