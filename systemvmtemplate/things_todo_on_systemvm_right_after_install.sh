# root password should be "password"
# after installation finished, i added the folowing packages:
apt install -y mc vim sudo

cat >> ~/.bashrc << EOF
export EDITOR=vi
export VISUAL=vi
EOF

# =====================================================
#post install addons
# apt install sudo rsync
# usermod -aG sudo sefi
# visudo
#sefi ALL=(ALL) NOPASSWD: ALL
#edit sshd_config to permit root login with password
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