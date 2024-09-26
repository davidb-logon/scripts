vmcp link lnxdist 208 2208 rr
chccwdev 2208 -e
cio_ignore -r 2208
chccwdev 2208 -e
lsdasd -a
mount /dev/dasdm1 /mnt/dvd
mkdir /mnt/dvd
mount /dev/dasdm1 /mnt/dvd
cd /mnt/dvd
ls
cp -a wureport.tar.gz WUReport.sh /opt
cd /opt
ls
tar -zxvf wureport.tar.gz 
ls
rm wureport*gz
ls -al
vi WUReport.sh 
./WUReport.sh 
find / -name 'libnsl.so*'
ls -al /usr/lib64/libnsl.so*
cd /usr/lib64
ln -s libnsl.so.2.0.0 /usr/lib64/libnsl.so.1
ls -al /usr/lib64/libnsl.so*
cd /opt
ls
./WUReport.sh 
yum install mail
cd /etc/yum.repos.d
vi rhel86.repo
lsdasd -a
cat rhel86.repo 
mkdir /mnt/rhel
mount /dev/dasdl1 /mnt/rhelp
mount /dev/dasdl1 /mnt/rhel
pwd
ls -al
yum 
yum -h
yum repolist
cd /etc/yum
ls
\ls
cd pluginconf.d/
\ls -al
vi subscription-manager.conf 
cd
yum repolist
yum install mail
cd /mnt/rhel
ls
find . -name '*mail*'
yum install sendmail
cd /opt
ls
./WUReport.sh 
mail
mailx
shutdown -h now
systemctl restart sshd
ip a
ping 192.86.33.3
shutdown -h now
yum install mailx
cd /opt
ls
./WUReport.sh 
mail
mailx
vi /etc/fstab
mount -a
yum install mailx
./WUReport.sh 
lsdasd -a
vmcp link lnxdist 208 2208 rr
cio_ignore -r 2208
chccwdev -e 2208
lsdasd -a
mount -a
cd /mnt/rhel
ls -al
ls /mnt
mount /dev/dasdm1 /mnt/dvd
cd /mnt/dvd
ls
cp -a banner.txt /mnt/ssh/.
cp -a banner.txt /etc/ssh/.
vi /etc/ssh/sshd_config 
Systemctl restart sshd
systemctl restart sshd
ping -c3 192.86.33.3
ping -c3 192.86.33.2
shutdown -h now
cd /mnt/rhel
ls -al
vmcp link lnxdist 208 2208 rr
chccwdev -e 2208
cio_ignore -r 2208
chccwdev -e 2208
mount /dev/dasdm1 /mnt/dvd
cd /mnt/dvd
ls
cp -a start_etpstaff.sh /sbin/. 
cp -a trigger.sh /sbin/. 
cp -a 10-local.rules /etc/udev/rules.d/.
cat /sbin/start_etpstaff.sh 
which usermod
which echo
which passwd
which chpasswd
which sleep
which usermod
cat /sbin/trigger.sh 
which at
usermod -G wheel svtscu
cp smsgiucv.service /usr/lib/systemd/system/
systemctl enable smsgiucv.service 
systemctl start smsgiucv.service 
systemctl status smsgiucv.service 
lsshut
reboot
ping 192.86.33.3
cd /var/log
ls -al
echo > boot.log
echo > btmp
echo > cron
echo > lastlog
clear
ls -al
rm -rf dnf*
clear
ls -al
echo > messages 
echo > secure
echo > wtmp
clear
ls -al
echo > maillog
echo > kdump.log
clear
ls -al
shutdown -h now
systemctl network stop
ifdown eth0
cd /etc/yum.repos.d
ls
cat rhel*
ls
cat redhat.repo
cd /etc/yum.repos.d
ls
cat rhel*
shutdown -h now
cd /etc/sysconfig/network
ls /etc
cd /etc/sysconfig
ls
cd network-scripts
ls
ed -p $ ifcfg-enc1c00
reboot
cat /etc/password
cat /etc/passwd
ls /hom
ls /home
useradd firstuser
ls /home
usermod -aG wheel firstuser
groups
passwd firstuser
cd
ls
chmod +x autodasdfmt.sh 
./autodasdfmt.sh 
vim autodasdfmt.sh 
./autodasdfmt.sh 
vim autodasdfmt.sh 
vim autodasdfmt.sh 
./autodasdfmt.sh 
vim autodasdfmt.sh 
seq 525 571 | while read n; do printf "%04x " $n; done
./autodasdfmt.sh 
vim autodasdfmt.sh 
lvdisplay 
pvdisplay 
ls -l /dev/disk/
ls -l /dev/disk/by-path/
lszdev
cio_ignore -r 200
lszdev
chzdev -e 200
chzdev -p 200
chzdev -ep 200
dasdfmt -y -b 4096 /dev/disk/by-path/ccw-0.0.0200 
reboot
visudo
yum install mc
exit
chown sefi.sefi -R .ssh
vi /etc/ssh/sshd_config 
systemctl restart sshd
exit
vmcp q dasd
vmcp q vswitch
ip -br a
ll
cat autodasdfmt.sh
ssh-keygen -t rsa
cd .ssh
ll
cp id_rsa.pub authorized_keys
ll
cd ..
mc
cat id_rsa
history
vmcp link lnxdist 208 2208 rr
chccwdev 2208 -e
cio_ignore -r 2208
chccwdev 2208 -e
lsdasd -a
mkdir /mnt/dvd
mount /dev/dasdm1 /mnt/dvd
cd /mnt/dvd
ls
mount /dev/dasdb1 /mnt/dvd
cd ..
mount /dev/dasdb1 /mnt/dvd
mc
vmcp q dasd
ip -br a
vmcp q dasd
ll
ls
lsblk
lsblk -f
mount /dev/dasdbl/dasdbl1 /mnt/dvd
mount /dev/dasdbl1 /mnt/dvd
cd /mnt/
mc
mkdir -p /mnt/linuxu;mount -t nfs 54.227.191.101:/linuxu /mnt/linuxu;alias m='/mnt/linuxu/m.sh'
yum install nfs-utils
mkdir -p /mnt/linuxu;mount -t nfs 54.227.191.101:/linuxu /mnt/linuxu;alias m='/mnt/linuxu/m.sh'
ping 54.227.191.101
ssh ec2-user@54.227.191.101
ll
ls ~sefi
ll
cd root/
ll
ll ~sefi
cd .ssh/
ll
cp ~sefi/Radius.rsa .
ll
chmod 700 *
ll
vi config
ssh nfs ls
ssh nfs ls /linuxu
ssh nfs ls find /linuxu
ssh nfs find /linuxu
ssh nfs find /linuxu | gtrp mnt
ssh nfs find /linuxu | grep mnt
ssh nfs find /linuxu | grep net
ssh nfs find /linuxu | grep iso
ll /etc/yum.repos.d/
cat /etc/yum.repos.d/rhel86.repo 
mount
mount | grep mnt
vmcp q dasd
lvdisplay
lvcreate 
ll /dev/
lsblk
lsblk -f
lsblk --help
cat /proc/dasd/devices
lsblk
dasdfmt -b 4096 -d cdl -f /dev/dasdm
dasdfmt -b 4096  -f /dev/dasdm
dasdfmt --help
dasdfmt -b 4096 -d ldl -f /dev/dasdm
dasdfmt  -d ldl -f /dev/dasdm
seq 525 571 | while read n; do printf "%04x " $n; done
vi autoformat.sh
chmod +x autoformat.sh 
ll
mc
./autoformat.sh 
yum install vim
vi .vimrc
echo "colorscheme blue" > ~/.vimrc
echo "set nu" >> ~/.vimrc
echo "set nocompatible" >> ~/.vimrc
echo "set viminfo='100,<1000,s100,h" >> ~/.vimrc
echo "syntax on" >> ~/.vimrc
echo "filetype plugin indent on" >> ~/.vimrc
echo "autocmd FileType sh setlocal filetype=sh" >> ~/.vimrc
echo "fu! SaveSess()" > ~/.vimrc
echo "execute 'mksession! ' . getcwd() . '/.' . expand('%:t') . '.vim'" >> ~/.vimrc
echo "endfunction" >> ~/.vimrc
echo " " >> ~/.vimrc
echo "fu! RestoreSess()" >> ~/.vimrc
echo " if filereadable(getcwd() . '/.' . expand('%:t') . '.vim')" >> ~/.vimrc
echo " execute 'so ' . getcwd() . '/.' . expand('%:t') . '.vim'" >> ~/.vimrc
echo " if bufexists(1)" >> ~/.vimrc
echo " for l in range(1, bufnr('$'))" >> ~/.vimrc
echo " if bufwinnr(l) == -1" >> ~/.vimrc
echo " exec 'sbuffer ' . l" >> ~/.vimrc
echo " endif" >> ~/.vimrc
echo " endfor" >> ~/.vimrc
echo " endif" >> ~/.vimrc
echo "endfunction" >> ~/.vimrc
echo " " >> ~/.vimrc
echo "autocmd VimLeavePre * call SaveSess()" >> ~/.vimrc
echo "autocmd VimEnter * nested call RestoreSess()" >> ~/.vimrc
echo "colorscheme blue" >> ~/.vimrc
echo "set nu" >> ~/.vimrc 
echo "set noswapfile" >> ~/.vimrc 
echo "set nobackup" >> ~/.vimrc 
echo "set nowritebackup" >> ~/.vimrc 
echo "set noundofile" >> ~/.vimrc 
alias ipa='ip -c -br address'
alias hg='history | grep  -i '
alias al='sudo tail -f /var/log/cloudstack/agent/agent.log'
alias ml='sudo tail -f /var/log/cloudstack/management/management-server.log'
alias alc='sudo ail -f /var/log/cloudstack/agent/agent.log | GREP_COLOR='\''01;36'\'' egrep --color=always '\''DEBUG|$'\'' |  GREP_COLOR='\''01;31'\'' egrep --color=always '\''ERROR|$'\'' |  GREP_COLOR='\''01;32'\'' egrep --color=always '\''WARN|$'\'''
alias ap='sudo i /etc/cloudstack/agent/agent.properties'
alias cw='cd /home/davidb/cloudstack/tools/appliance_s390x'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias fip='virsh net-dhcp-leases default '
alias grep='grep --color=auto'
alias ipa='ip -c -br address show'
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
alias ls='ls --color=auto'
alias snet='/data/primary/net9.sh'
alias tm='ps -aux -o rss,command | awk "!/peruser/ {sum+=\$1} END {print sum/1024}"'
alias vd='virsh dumpxml '
alias vi='vim '
alias vibash='vim /mnt/linuxu/workstation/.bashrc'
alias vl='virsh list --all'
alias vn='virsh list --state-running | grep  "running\|paused" | awk "{print \"virsh domifaddr  \"\$2} " | sh'
alias astart='sudo systemctl start cloudstack-agent;sudo systemctl status cloudstack-agent;'
alias arestart='sudo systemctl restart cloudstack-agent;sudo systemctl status cloudstack-agent;'
alias astatus='sudo systemctl status cloudstack-agent;'
alias s2='sudo systemctl status cloudstack-management;sudo systemctl status cloudstack-agent;'
alias ahelp='colums=8;cn=0;alias | awk -F= "{print \$1}" | awk "{print \$2}" | while read -r sal; do  printf  "%-15s"  $sal;((cn++));if ((cn % colums == 0)); then echo ;fi;done;echo'
alias sst='while true; do clear;head -v -n 8 /proc/meminfo; head -v -n 2 /proc/stat /proc/version /proc/uptime /proc/loadavg /proc/sys/fs/file-nr /proc/sys/kernel/hostname; tail -v -n 32 /proc/net/dev;echo "==> /proc/df <==";df -l;echo "==> /proc/who <==";who;echo "==> /proc/end <==";echo "##Moba##"; sleep 1;done'
alias psj='ps aux | grep java'
alias sts="systemctl | grep -E 'openvpn|cloudstack-agent|cloudstack-management'"
ll -a
alias > .bash_alias
vi .vimrc
vi autoformat.sh 
./autoformat.sh 
vi autoformat.sh 
./autoformat.sh 
for n in  200 20a 20b 20c;  do printf "%04x " $n; done
for n in 200 20a 20b 20c; do printf "%04x " "0x$n"; done
vi autoformat.sh 
./autoformat.sh 
lsblk
fdasd -a /dev/dasdm
fdasd -a /dev/dasdn
fdasd -a /dev/dasdo
fdasd -a /dev/dasdp
lsblk
pvcreate /dev/dasdm1 /dev/dasdn1 /dev/dasdo1 /dev/dasdp1
vgcreate lvmdata  /dev/dasdm1 /dev/dasdn1 /dev/dasdo1 /dev/dasdp1
vgdisplay /dev/lvmdata
cat /proc/dasd/devices
vi autoformat.sh 
./autoformat.sh 
for i in q r s t u v w x y z; do fdasd -a /dev/dasd$i; done
pvs
for i in q r s t u v w x y z; do pvcreate /dev/dasd$i1; done
for i in q r s t u v w x y z; do pvcreate /dev/dasd$(i)1; done
for i in q r s t u v w x y z; do pvcreate /dev/dasd${i}1; done
for i in q r s t u v w x y z; do vgextend lvmdata /dev/dasd${i}1; done
pvs
ll /dev/lvm*
vgdisplay /dev/lvmdata
lvcreate -n data lvmdata
lvcreate -L 73GB -n data lvmdata
lvdisplay /dev/lvmdata/data
mke2fs -j /dev/lvmdata/data
mkdir /data
mount /dev/lvmdata/data /data
lsblk
vi /etc/fstab 
reboot
pvchange --help
vgextend 
pvs
