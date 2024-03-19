

# From "Mastering KVM Virtualization_Second Edition" bt Vedran Dakic, Humble Devassy Chirammal, Prasad Mukhedkar, Anil Vettathu

sudo dnf install qemu-img qemu-kvm libvirt libvirt-client virt-manager virt-install virt-viewer -y

sudo systemctl enable libvirtd
sudo systemctl start libvirtd

sudo virsh net-list --all
sudo virsh net-start default
sudo virsh net-autostart default

virt-host-validate
cat /proc/cpuinfo 
lscpu



#  yum install -y epel-release -- does not work
# http://docs.cloudstack.apache.org/en/4.19.0.0/installguide/hypervisor/kvm.html#configure-cpu-model-for-kvm-guest-optional
# Edit /etc/cloudstack/agent/agent.properties and add:
guest.cpu.mode=host-passthrough
guest.cpu.features=esan3 zarch stfle msa ldisp eimm dfp edat etf3eh highgprs te vx vxd vxe gs vxe2 vxp sort dflt vxp2 nnpa sie

# edit /etc/libvirt/libvirtd.conf and ensure it has the following settings:
sudo cat /etc/libvirt/libvirtd.conf

listen_tls=0

listen_tcp=0

tls_port="16514"

tcp_port="16509"

mdns_adv = 0

auth_tcp="none"

key_file="/etc/pki/libvirt/private/serverkey.pem"
cert_file="/etc/pki/libvirt/servercert.pem"
ca_file="/etc/pki/CA/cacert.pem"
auth_tls="none"

# Then:
cd /home/davidb/libvirt_saved
sudo cp -v libvirtd.conf.cloudstack /etc/libvirt/libvirtd.conf
sudo chmod --reference=libvirtd.conf.original /etc/libvirt/libvirtd.conf

# edit /etc/sysconfig/libvirtd
LIBVIRTD_ARGS="--listen"

systemctl mask libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket libvirtd-tls.socket libvirtd-tcp.socket

rpm -qa | grep selinux

vi /etc/selinux/config
SELINUX=permissive
setenforce permissive

# debugging the agent on Z
cp /etc/cloudstack/agent/log4j-cloud.xml /etc/cloudstack/agent/log4j-cloud.xml.orig
sed -i "s/INFO/DEBUG/g" /etc/cloudstack/agent/log4j-cloud.xml
systemctl restart cloudstack-agent