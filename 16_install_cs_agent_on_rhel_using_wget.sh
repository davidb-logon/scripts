mkdir -p /home/davidb/cloudstack-rpms
cd /home/davidb/cloudstack-rpms
wget http://download.cloudstack.org/el/9/4.19/cloudstack-common-4.19.0.0-1.x86_64.rpm
wget http://download.cloudstack.org/el/9/4.19/cloudstack-agent-4.19.0.0-1.x86_64.rpm


# yum -y install  bzip2  ipmitool qemu-guest-agent   
# yum -y install java-11-openjdk
# yum -y install python36
sudo rpm -i --ignorearch  --nodeps   --nosignature cloudstack-common-4.19.0.0-1.x86_64.rpm
sudo rpm -i --ignorearch  --nodeps   --nosignature cloudstack-agent-4.19.0.0-1.x86_64.rpm
