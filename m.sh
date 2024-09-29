#!/bin/bash

#!/bin/bash 
#set -x
#############################################################################################
#  A simple menu system  by Sefi Merkel                                                     #
#                                                                                           #
# The next lines are the menu defenition                                                    #
# Each line consist of 3 parameters seperated by the = and @ chars                          #
# First parameter is the menu hot key                                                       #
# Seconf is the menue descripition                                                          #
# This is what to run. it can be a linux command line instrunctions or a name of            #
# a function that later apear in the file                                                   #
#############################################################################################

readarray -t  VAR <<EOF
r1=Run zVM Logon1@/home/ibmsys1/runz1.sh
r2=Run zVM Logon2@/home/ibmsys1/runz2.sh
r22=Run zVM Logon2@runz logon2 123
r3=Run zVM Logon3@/home/ibmsys1/runz3.sh
r4=Run zVM Logon4@/home/ibmsys1/runz4.sh
rs4=Run zVM LogonSSI4@/home/ibmsys1/runzssi4.sh
r21=Run zVM Logon21@/home/ibmsys1/runz21.sh
rt=Run zVM LogonT@/home/ibmsys2/runzt.sh
rl12=Run zLinux12@/home/ibmsys1/runzlinux12.sh
rl155=Run zLinux15@/home/ibmsys1/runzlinux15.sh
rlu20=Run zLinuxu20@/home/ibmsys1/runzlinuxu20.sh
rlu23=Run zLinuxu20@/home/ibmsys1/runzlinuxu23.sh
rca=Run zVM LogonCA@/home/ibmsys2/runca.sh
rca3=Run zVM LogonCA3@/home/ibmsys2/runCA3.sh
sz=Stop zPDT@stopz
sz2=Stop zPDT & Shutdown@/mnt/linuxu/stopz2.sh
zs=zPDT Status@zpdtStatus
c1=Check if zPDT is running@wave_check_zpdt
i1=Wave Install Java@wave_install_java
lwr=List Wave Repository@wave_list_repository
wi=Wave Install@wave_update -i
wu=Wave Update@wave_update $2 $3
wc=Wave Create Certificate@/mnt/linuxu/wave_create_certificate.sh
wic=Wave Install Certificate@wave_install_certificate liberty! $2
wr=Wave restart services@/mnt/linuxu/wave_irestart_services.sh
n=Netstat servers@ss -lnt
m=Edit menu@vim /mnt/linuxu/m.sh
o=OprMsg to zpdt@oprmsg $2 $3 $4 $5 $6
w=Watch emily@watch -n1 w;ss -lnt; ps aux | grep emily | grep -v grep | grep -v watch
wj=Watch java@watch -n1 w;ss -lnt; ps aux | grep java | grep -v watch | grep -v grep
pj=ps java@ps -eaf | grep java
a=Set alias@alias m='/home/sefi/app/ibm/m.sh'
al=List alias@echo ${BASH_ALIASES}alias
mr=Mount Repository@wave_list_repository
b2=Backup Logon2@backup_logon2
bl=Backup Linuxu@backup_linuxu
im=Install Menu@install_m
ar=Allow Root SSH@arssh
rqa=rpm -qa wave@rpmqa
rme=rpm -e wave@rpmme
rmei=rpm -e IBM-Wave@rpmmei
iibm=Install IBM-Wave@cd /home/ec2-user/WaveFixpack16;cp ../IBM-Wave-1.20-1.s390x.rpm install;./doUpdate.sh -i install/IBM-Wave-1.20-1.s390x.rpm
ulog=Update Log-On-Wave@cd /home/ec2-user/WaveFixpack_feature_WAVE-65-migration-from-ibm-wave-1.2.0;./doUpdate.sh
fsz=Force Stop ZPDT@forcestopz
dm=Display Menu@display_menu_main
q=Quit@qmenu
EOF
declare -A Menu
OMenu=()
i=1
for line in "${VAR[@]}"; do
  Menu[${line%%=*}]=${line#*=}
  OMenu[$i]=${line%%=*}
  i=$i+1
done
#echo ">>>>> associative <<<<<<"
#for key in "${OMenu[@]}"; do
# echo $key  ${Menu[$key]}
#done

#------------------------------------------------------------------------------
# Licensed Materials (c) Copyright Log-On 2024, All Rights Reserved.
#------------------------------------------------------------------------------
# Function to display the menu
display_menu_numbers() {
  local files=("$@")
  local cols=3
  local total_files=${#files[@]}
  local rows=$(( (total_files + cols - 1) / cols ))

  for (( i=0; i<rows; i++ )); do
    for (( j=0; j<cols; j++ )); do
      idx=$(( i + j * rows ))
      if [ $idx -lt $total_files ]; then
        printf "%2d) %-50s" $((idx+1)) "${files[$idx]}"
      fi
    done
    echo
  done
}

display_menu_main() {
  # Get the list of files and sort them by the numeric part of the filename
  files=($(ls | grep -E '^[0-9]+_.*\.sh$' | sort -V))

  # Display the menu
  echo "Select a file to run:"
  display_menu_numbers "${files[@]}"

  # Get the user's choice
  read -p "Enter the number of the file you want to run: " choice

  # Validate the choice and run the selected file
  if [[ $choice =~ ^[0-9]+$ ]] && [ $choice -ge 1 ] && [ $choice -le ${#files[@]} ]; then
    selected_file=${files[$((choice-1))]}
    echo "Running $selected_file..."
    ./$selected_file
  else
    echo "Invalid choice. Exiting."
  fi
  
}

MountUB16Repository(){
mkdir -p  /mnt/ub16
mount -t nfs 10.0.78.231:/ubuntu16 /mnt/ub16/
sudo apt-cdrom -m -d /mnt/ub16 add

}


rpmmei(){
rpm -e IBM-Wave
}
rpmme(){
rpm -e Log-On-Wave
}

arssh(){
#as root
sed -i s/#PermitRootLogin/PermitRootLogin/g /etc/ssh/sshd_config
cd /root/.ssh/;cat  authorized_keys | awk -Fssh-rsa '{print "ssh-rsa "$2}' > a;  mv -f a authorized_keys
cat /home/ec2-user/.ssh/authorized_keys >> /root/.ssh/authorized_keys
systemctl restart sshd
}

rpmqa(){
rpm -qa | grep -i wave
}

forcestopz(){
#pkill -P $(pgrep awsstart 
p1=$(ps xu | grep fsz | grep -v grep | head -n 1 | awk '{print $2}')
p2=$(ps xu | grep "\-bash" | grep -v grep | head -n 1| awk '{print $2}')
p3=$(ps xu | grep "sshd:" | grep -v grep | head -n 1| awk '{print $2}')
echo "p1=$p1"
ps $p1
echo "p2=$p2"
ps $p2
echo "p3=$p3"
ps $p3
ps xuh 
ps xuh | awk '{if ($2!='$p2' && $2!='$p1' && $2!='$p3') print "kill -9 "$2}' 
ps xuh | awk '{if ($2!='$p2' && $2!='$p1' && $2!='$p3') print "kill -9 "$2}' | bash
}

runz(){
devmfile="$1"
ipladdr="$2"
echo " starting $1 $2  ipl $ipladdr"
exit 1
#[ibmsys1@ip-10-0-78-151 ~]$ cat runz2.sh
#/bin/bash
rm -f ~/core-aws*
awsstart
sudo pkill tail
nohup awsstart ~/$devmfile.devmap &
tail -f nohup.out &
echo "ipl $ipladdr"
sleep 15
ipl $ipladdr
sleep 10
oprmsg FORCE
oprmsg enable all
}
stopz(){
#[ibmsys1@ip-10-0-78-151 ~]$ cat stopz.sh
#/bin/bash
echo %1
/usr/z1090/bin/awsstat
/usr/z1090/bin/oprmsg q n
sleep 1
tail nohup.out
/usr/z1090/bin/oprmsg shutdown within 90
sudo pkill tail
CNT="0"
tail -f $HOME/nohup.out  | while   read -r line && [ "$CNT" !=  1 ]  ; do
    echo "${line}"
#    if [[ "${line}" == *"SEFI"* ]]; then
    if [[ "${line}" == *"SYSTEM SHUTDOWN COMPLETE FOR"* ]]; then
      echo "It's there."
      CNT="1"
      break
    fi
    if [[ "${line}" == *"Shutdown complete"* ]]; then
      echo "It's there."
      CNT="1"
      break
    fi
done

echo 'Z/VM is down'
/usr/z1090/bin/awsstop
/usr/z1090/bin/awsstat
}

wave_install_certificate(){
echo "this function takes two parameters the hostnem/ip and keystor password"
hname=$2
password=$1
if test -z "$password" 
      then
      echo "password is empty"
      st="\E[33;44m\033[1m"
      en="\033[0m"
      echo -e -n "$st Your Password? : $en"
      read password
      if test -z "$password" 
      then
        exit -1
      fi
fi
OUTPUT_DIR="/root/self_signed_certificate"
LINUXU_DIR="/mnt/linuxu/cer"
mkdir -p $OUTPUT_DIR
if test -z "$hname" ; then 
	cert_name=$(hostname)
	dnsip="dns"
else
        cert_name=$hname
	dnsip="ip"
fi
#echo "creating certificate for "$cert_name $1
cd $OUTPUT_DIR
if test -f $OUTPUT_DIR/$cert_name.cer ; then
  echo "+---------------------------------------------+"
  echo "| we have a certificate, just need install it |"
  echo "+---------------------------------------------+"
elif  test -f $LINUXU_DIR/$cert_name/$cert_name.cer ; then
  #check if we have a backup of the certificate in linuxu folder
  echo "+-------------------------------------------------------+"
  echo "| we have a backup of certificate, just need install it |"
  echo "+-------------------------------------------------------+"
  mkdir -p $OUTPUT_DIR
  cp $LINUXU_DIR/$cert_name/*  $OUTPUT_DIR
else
  echo "+-------------------------------------------------------------------------+"
  echo "| We need to create a new self sign certificate at $OUTPUT_DIR/$cert_name |"
  echo "+-------------------------------------------------------------------------+"
  mkdir -p $OUTPUT_DIR
  cd $OUTPUT_DIR
  echo ">>>> genkey"
  set -o xtrace
d=`date +%Y%m%d-%H-%M-%S`
echo $d
keytool -delete \
-keystore /usr/wave/websphere/wlp/usr/servers/defaultServer/resources/security/key.jks \
-alias default -v -storepass $password 
echo `date +%Y%m%d-%H-%M-%S`
keytool -v -list  -deststorepass $password  -srcstorepass $password \
-keystore  /usr/wave/websphere/wlp/usr/servers/defaultServer/resources/security/key.jks 
echo `date +%Y%m%d-%H-%M-%S`

  keytool -genkey -alias default \
    -keyalg RSA \
    -keypass $password \
    -storepass $password \
    -keystore keystore.p12 \
    -storetype PKCS12 \
    -ext san=$dnsip:$cert_name \
    -validity 3650 \
    -dname "CN="$cert_name",OU=Wave,O=Log-On Software LTD,L=Ramat Gan,ST=NA,C=IL"
echo `date +%Y%m%d-%H-%M-%S`

  keytool -export -alias default \
    -storepass $password \
    -file $OUTPUT_DIR/$cert_name.cer \
    -keystore $OUTPUT_DIR/keystore.p12 \
    -storetype PKCS12
echo `date +%Y%m%d-%H-%M-%S`
   #now backup the newly created certificate to linuxu folder
   mkdir -p $LINUXU_DIR/$cert_name
   cp  $OUTPUT_DIR/* $LINUXU_DIR/$cert_name

fi

   #also copy to public Z: drive for the developers
   mkdir -p /mnt/z
   mount -t cifs -o username=sadmin,password=Samba+123456! //sw_repo.dev.wave.log-on.com/share /mnt/z
   cp $LINUXU_DIR/$cert_name/*.cer /mnt/z/Linux/cer/
   umount /mnt/z

keytool -delete \
-keystore /usr/wave/websphere/wlp/usr/servers/defaultServer/resources/security/key.jks \
-alias default -v -storepass $password 
echo `date +%Y%m%d-%H-%M-%S`
  
keytool -importkeystore -deststorepass $password -srcstorepass $password \
-destkeystore /usr/wave/websphere/wlp/usr/servers/defaultServer/resources/security/key.jks \
-srckeystore $OUTPUT_DIR/keystore.p12 \
-srcstoretype PKCS12
echo `date +%Y%m%d-%H-%M-%S`

keytool -v -list  -deststorepass $password  -srcstorepass $password \
-keystore  /usr/wave/websphere/wlp/usr/servers/defaultServer/resources/security/key.jks 
echo `date +%Y%m%d-%H-%M-%S`
/usr/wave/websphere/wlp/bin/server stop
systemctl restart WAVEBackgroundServices WAVEWebServer 
echo `date +%Y%m%d-%H-%M-%S`
set +o xtrace

}

MountRHR71epository(){
#>> use the redhat dvd as a repo for yum
mkdir -p  /mnt/rh71
mount -t nfs 10.0.78.231:/rhel /mnt/rh71/
cp /mnt/rh71/media.repo /etc/yum.repos.d/rhel7dvd.repo
chmod 644 /etc/yum.repos.d/rhel7dvd.repo
#vi /etc/yum.repos.d/rhel7dvd.repo

#>> need to have:
cat << EOF | tee /etc/yum.repos.d/rhel7dvd.repo
[InstallMedia]
name=Red Hat Enterprise Linux 7.1
mediaid=1424360759.931683
metadata_expire=-1
gpgcheck=0
cost=500
enabled=1
baseurl=file:///mnt/rh71/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
EOF
#>> then do:
yum clean all
yum repolist enabled
yum update
}

zpdtStatus(){
	txt=`sudo ps aux | grep awsstart | grep -v grep`
	txtc=`echo $txt | wc -l`
	if [ "$txtc" == "0" ]; then
		echo "No zPDT running"
	else
 		cpu=`ps aux | grep emily | head -n 1 |  awk -F'-c' '{print $2}' | awk -F, '{print $1}'`
		echo "$txt cpu use=$cpu" 
	fi
}

backup_logon2(){
d=`date +%Y%m%d-%H-%M-%S`
cd /home/ibmsys1
# grep '/z/' logon2.devmap | grep -v tape | awk '{print "zip /z/logon2.bak/logon2$d.zip "$5}' | sh
 grep '/z/' logon2.devmap | grep -v tape | awk '{print "ls -l "$5}' | sh
}
wave_install(){
lm=`ls /mnt/wavez | awk '{print NR" "$0}'`
CHOICE=$( whiptail --title "Operative Systems" --menu "Make your choice" 16 100 9 $lm  3>&2 2>&1 1>&3)

}
mount_repository()
{
mkdir -p  /mnt/rh71
mount -t nfs 10.0.78.231:/rhel /mnt/rh71/
cp /mnt/rh71/media.repo /etc/yum.repos.d/rhel7dvd.repo
chmod 644 /etc/yum.repos.d/rhel7dvd.repo

cat << EOF > /etc/yum.repos.d/rhel7dvd.repo
[InstallMedia]
name=Red Hat Enterprise Linux 7.1
mediaid=1424360759.931683
metadata_expire=-1
gpgcheck=0
cost=500
enabled=1
baseurl=file:///mnt/rh71/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
EOF


}
backup_linuxu()
{
d=`date +%Y%m%d`
zip -rv linuxu$d.zip /mnt/linuxu
ls -l linuxu$d.zip 
}
install_m()
{
cat << EOF > ~/.vimrc
colorschem blue
fu! SaveSess()
execute 'mksession! ' . getcwd() . '/.' . expand('%:t') . '.vim'
endfunction

fu! RestoreSess()
 if filereadable(getcwd() . '/.' . expand('%:t') . '.vim')
 execute 'so ' . getcwd() . '/.' . expand('%:t') . '.vim'
 if bufexists(1)
 for l in range(1, bufnr('$'))
 if bufwinnr(l) == -1
 exec 'sbuffer ' . l
 endif
 endfor
 endif
 endif
endfunction

autocmd VimLeavePre * call SaveSess()
autocmd VimEnter * nested call RestoreSess()
EOF

cat << EOF >> /etc/rc.local
if [ ! -f /mnt/linuxu/m.sh ]; then
    sudo mkdir -p /mnt/linuxu
    sudo mount -t nfs 10.0.78.231:/linuxu /mnt/linuxu
fi
EOF
chmod +x /etc/rc.local

cat << EOF  >> /etc/bashrc
alias m='/mnt/linuxu/m.sh'
alias t='tail -f ~/nohup.out &'
alias vi='/usr/bin/vim'
alias hg='history | grep '
EOF
}

wave_check_zpdt()
{
ps aux | grep emily | grep -v grep
}
wave_install_java()
{
mkdir /mnt/wavez
mount -t nfs 10.0.78.231:/wavez /mnt/wavez/
rpm -i /mnt/wavez/Linux/rpm/ibm-java-s390x-jre-8.0-5.41.s390x.rpm
}

wave_list_repository()
{
mkdir /mnt/wavez
mount -t nfs 10.0.78.231:/wavez /mnt/wavez/
ls -l /mnt/wavez
}

wave_update()
{
#set -x
date
start=`date +%s`
if test -z "$1" ; then
  fltr="."
else
  fltr=$1
fi
#/usr/wave/websphere/wlp/bin/server stop
#for suse we need to install whiptail by
# wget https://www.rpmfind.net/linux/opensuse/ports/zsystems/tumbleweed/repo/oss/s390x/newt-0.52.21-2.15.s390x.rpm

mkdir -p /mnt/wavez
mount -t nfs 10.0.78.231:/wavez /mnt/wavez/ > /dev/null 2>/dev/null
os=`cat /etc/*releas* | grep -e ^NAME= | awk -F= '{print $2}' | awk -F\" '{print $2"\n"}'`
echo ">>>>>>>>>>>>>>>>>>>>>>>> $os"
if [ "$os" == "SLES" ]; then
  echo "suse here [" $fltr "]"
  if [ "$fltr" == "" ]; then
     lm=`ls -1 /mnt/wavez | awk '{print NR" "$0}'`
  else
    lm=`ls -1 /mnt/wavez | grep $fltr | awk '{print NR" "$0}'`
  fi
  #ls -1 /mnt/wavez | awk '{print NR" "$0}'
  n=`echo "$lm" | wc -l`
  echo $fltr
  echo $n
  if [ $n -gt 1 ]; then
    c=0
    for f in ${lm[@]} ; do
      c=$((c+1))
      echo "$c) $f"
    done
    echo -e -n "$st Your choice? : $en"
    read CHOICE
    c=0
    for f in ${lm[@]} ; do
      c=$((c+1))
      if [ $c -eq $CHOICE ]; then
         reponame=$f
      fi   
    done
    #reponame="${lm[5]}" #| awk '{if(NR==$CHOICE)print $2}'`
    echo $reponame
    
  else
    reponame=`echo "$lm" | awk '{print $2}'`
    echo $reponame
  fi    
else
  if [ "$fltr" == "" ]; then
     lm=`ls -1 /mnt/wavez | awk '{print NR" "$0}'`
  else
    lm=`ls -1 /mnt/wavez | grep $fltr | awk '{print NR" "$0}'`
  fi
  #ls -1 /mnt/wavez | awk '{print NR" "$0}'
  n=`echo "$lm" | wc -l`
  echo $fltr
  echo $n
  if [ $n -gt 1 ]; then
    CHOICE=$( whiptail --title "Operative Systems" --menu "Make your choice" 16 100 9 $lm  3>&2 2>&1 1>&3)
    reponame=` ls /mnt/wavez | awk -v var=$CHOICE '{if (var==NR){print $0}}'`
  else
    reponame=`echo "$lm" | awk '{print $2}'`
    echo $reponame
  fi
fi
tarname=`ls /mnt/wavez/$reponame`
base=`tar -tf /mnt/wavez/$reponame/$tarname | head -n1`
#echo $reponame  $tarname $base

cd /home/ec2-user
#rm -rf /root/wave;mkdir -p /root/wave;cd /root/wave
tar xvf /mnt/wavez/$reponame/$tarname
cd /home/ec2-user/$base
\cp /mnt/linuxu/.license install/.license
echo "cd /home/ec2-user/$base"
echo $2
if [ "$2" == "u" ]; then
    cd /home/ec2-user/$base
    sed -i 's/read userInput nonBlank/read userInput #nonBlank/g' install/wavesrv-name.sh
    ./doUpdate.sh < /mnt/linuxu/autot/dou.txt
fi
#pwd
#date
#end=`date +%s`
#runtime=$((end-start))
#echo "running for:" $runtime
#./doUpdate.sh $1
#end=`date +%s`
#runtime=$((end-start))
#echo "running for:" $runtime
#date
#alias ok='cd /home/ec2-user/$base'
}



    upperLeftCorner='\u250C'
    upperRightCorner='\u2510'
    lowerLeftCorner='\u2514'
    lowerRightCorner='\u2518'
    horizontalLine='\u2500'
    verticalLine='\u2502'


st="\E[33;44m\033[1m"
en="\033[0m"
ptl='\u250F'
pt='\u2501'
ptr='\u2513'
pl='\u2503'
pr='\u2503'
pbl='\u2517'
pb='\u2501'
pbr='\u251b'
if [ "$demo" == "yes" ]; then
echo -e $ptl
echo -e $pt
echo -e $ptr
echo -e $pl
echo -e $pr
echo -e $pbl
echo -e $pb
echo -e $pbr
fi
#for i in {1..78}: do printf  $i: done

function topline()
{
printf "$st$upperLeftCorner"
for i in {1..90};
do
    printf "$horizontalLine"
done
printf "$upperRightCorner$en\n"
}

function botline()
{
printf "$st$lowerLeftCorner"
for i in {1..90};
do
   printf "$horizontalLine"
done
printf "$lowerRightCorner$en\n"
}


function mkline()
{
s=$2
se=$((s+38))
if [ ${#3} -gt 0 ]; then
  p3=$3"                                                "
  pe=${p3:0:38}
  printf "${1:0:s}$pe${1:$se}"
fi
}

function midline()
{
p1=$1
p2=$2
p1n=${#p1}
p2n=${#p2}
#echo $p1n $p2n
line=`printf ' %.0s' {1..90}`
if [ $p1n -gt 0 ]; then
line=$(mkline "$line" 3 "$1")
fi
if [ $p2n -gt 0 ]; then
line=$(mkline "$line" 48 "$2")
fi
printf "$st$verticalLine$line$verticalLine$en\n"
}

function qmenu(){
exit
}

function doproccess()
{
echo "doProccess: $1" ${Menu[$1]}
#for key in "${!Menu[@]}"; do
# echo $key  ${Menu[$key]}
#done
first="${Menu[$1]#*@}"
echo "Doing $first"
$first
}

mkspace(){
if (( ${#1} == 1 )) ; then
  echo "  "
else
  echo " "
fi
}
function pmenu()
{
topline
lb=${#OMenu[@]}
l=$(($lb/2 + 1))
i=1
while [ $i -lt $(($l+1)) ]
   do
    entry=${OMenu[$i]}
    if (( (i+l) <= lb )) ; then
     entry2=${OMenu[$(($i+l))]}
     midline "$entry.$(mkspace $entry)${Menu[$entry]%%@*}" "$entry2.$(mkspace $entry2)${Menu[$entry2]%%@*}"
    else
     midline "$entry.$(mkspace $entry)${Menu[$entry]%%@*}"
    fi
     i=$(($i+1))
   done
botline

echo -e -n "$st Your choice? : $en"
read choise
doproccess $choise

}

batch=0
if [ "$1" !=  ""   ]; then
batch=1
choise=$1
#echo "runnin in batch with", $choice , $1,$batch
fi

if [ $batch -eq 0 ]; then
  while : # Loop forever
  do
    pmenu
  done
else
  doproccess $choise
fi

