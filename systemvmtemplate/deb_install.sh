#install packer - very long compilation time - compile and install packer
# cd /data
# git clone https://github.com/hashicorp/packer.git
# cd packer
# make bin
#   GOOS=linux GOARCH=s390x go build -o bin/packer .
#   mv bin/packer /usr/local/bin/
#   rm /sbin/packer
#   ln -s /usr/local/bin/packer /sbin/packer




#   │                                                                                                                                                                                                                           │
#   │                                                                                   Virtual disk 1 (vda) - 6.4 GB Virtio Block Device                                                                                       │
#   │                                                                                   >     #1  primary   99.6 MB    f  ext2    /boot                                                                                         │
#   │                                                                                   >     #2  primary    6.0 GB    f  xfs     /                                                                                             │
#   │                                                                                   >     #3  primary  340.8 MB    f  swap    swap
# on our nfs server we did:
# wget https://cdimage.debian.org/cdimage/archive/11.11.0/s390x/iso-cd/debian-11.11.0-s390x-netinst.iso
# on our dlinux make sure the nfs iso is mounted to /mnt/iso:
# mkdir -p /mnt/iso;mount -t nfs 54.227.191.101:/iso /mnt/iso
# on the host s390x machine we did:
virt-install --name deb11-1 \
     --memory 2048 --vcpus=2  --os-variant=debian11  \
     --network network=default --graphics=none -v \
     --disk path=/data/primary/vm/images/deb11-1.qcow2,size=6 \
     --check disk_size=off --boot hd --location=/mnt/iso/debian/debian-11.11.0-s390x-netinst.iso --extra-args ro

# root password should be "password"
# after installation finished, i added the folowing packages:
apt install -y mc vim sudo

cat >> ~/.bashrc << EOF
export EDITOR=vi
export VISUAL=vi
EOF

IP_ADDR=$(ip a | grep 192 | awk '{print $2}' | awk -F/ '{print $1}')
cat > /etc/hosts << EOF
127.0.0.1	localhost
$IP_ADDR systemvm
EOF

Edit /etc/zipl.conf
in the [debian] section,
parameters = "root=UUID=34efa390-b335-4f52-aeed-855490465f7f net.ifnames=0"
where the uuid can be extracted by running: lsblk -f and taking the uuid of the ext4 partition
then do:
sudo zipl


# =====================================================
virsh net-start default
virsh undefine deb390-12-1
virt-install --name deb390-12-1 \
     --memory 2048 \
     --vcpus=2  \
     --os-variant=debian11   \
     --location=/data/iso/debian-12.5.0-s390x-netinst.iso  \
     --network network=default   \
     --graphics=none -v \
     --disk path=/data/primary/vm/images/deb390-12-1.qcow2,size=6   \
     --check disk_size=off

#post install addons
# apt install sudo rsync
# usermod -aG sudo sefi
# visudo
# apt-get install cloud-init
# apt install uuid-runtime
# update-alternatives --config editor
# apt-get install sharutils
# apt-get install s390-tools

#working on guest deb390-12-1
/home/sefi/scripts/apt_upgrade.sh
#/home/sefi/scripts/configure_grub.sh
/home/sefi/scripts/configure_locale.sh
/home/sefi/scripts/configure_networking.sh
/home/sefi/scripts/configure_acpid.sh
/home/sefi/scripts/install_systemvm_packages.sh  <-- we are here
/home/sefi/scripts/configure_conntrack.sh
/home/sefi/scripts/authorized_keys.sh
/home/sefi/scripts/configure_persistent_config.sh
/home/sefi/scripts/configure_login.sh
/home/sefi/cloud_scripts_shar_archive.sh
/home/sefi/scripts/configure_systemvm_services.sh
/home/sefi/scripts/cleanup.sh
/home/sefi/scripts/finalize.shroot@debs390-2:/home/sefi# scripts/apt_upgrade.sh

E: Unable to locate package xenstore-utils
E: Unable to locate package libxenstore4
E: Package 'open-vm-tools' has no installation candidate
E: Unable to locate package hyperv-daemons                                                                               │

ssh -p 3922 -i /root/.ssh/systemvm.rsa sefi@192.168.124.171
scp /data/scripts/exec_scripts_for_svm.sh -P 3922 -i /root/.ssh/systemvm.rsa $USER_AT_HOST:.
scp /data/scripts/exec_scripts_for_svm.sh -P 3922 -i /root/.ssh/systemvm.rsa sefi@192.168.124.171:.
scp  -P 3922 -i /root/.ssh/systemvm.rsa /data/cloudstack/tools/appliance/cloud_scripts_shar_archive.sh sefi@192.168.124.171:.
iptables -A INPUT -p tcp --dport 3922 -j ACCEPT   #need to open ssh port in firewall in a persistent way
vi /run/dnsmasq/resolv.conf  #need to update dns resolve to 8.8.8.8

systemctl disable cloud-init-local
systemctl disable cloud-init
systemctl disable cloud-config
systemctl disable cloud-final

systemctl stop cloud-init-local
systemctl stop cloud-init
systemctl stop cloud-config
systemctl stop cloud-final


+ apt-get --no-install-recommends -q -y --no-install-recommends -q -y install rsyslog logrotate cron net-tools ifupdown tmux vim-tiny htop netbase iptables nftables openssh-server e2fsprogs tcpdump iftop socat wget coreutils systemd python-is-python3 python3 python3-flask python3-netaddr ieee-data bzip2 sed gawk diffutils grep gzip less tar telnet ftp rsync traceroute psmisc lsof procps inetutils-ping iputils-arping httping curl dnsutils zip unzip ethtool uuid file iproute2 acpid sudo sysstat apache2 ssl-cert dnsmasq dnsmasq-utils nfs-common samba-common cifs-utils ipvsadm conntrackd libnetfilter-conntrack3 keepalived irqbalance openjdk-17-jre-headless ipcalc ipset iptables-persistent libssl-dev libapr1-dev haproxy haveged radvd sharutils genisoimage strongswan libcharon-extra-plugins libstrongswan-extra-plugins strongswan-charon strongswan-starter virt-what qemu-guest-agent cloud-guest-utils conntrack apt-transport-https ca-certificates curl gnupg gnupg-agent software-properties-common
Setting up apache2 (2.4.61-1~deb12u1) ...
ERROR: Conf security not properly enabled: /etc/apache2/conf-enabled/security.conf is a real file, not touching it
dpkg: error processing package apache2 (--configure):
 installed apache2 package post-installation script subprocess returned error exit status 1
Errors were encountered while processing:
 apache2
E: Sub-process /usr/bin/dpkg returned an error code (1)