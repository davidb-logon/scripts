# .bashrc
# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi
if [ -f ~/.bash_alias  ]; then
        . ~/.bash_alias
fi
if [ ! -f /mnt/linuxu/workstation/.bashrc ]; then
# mkdir -p /mnt/linuxu
# mount -t nfs 10.0.78.231:/linuxu /mnt/linuxu
# mount -t nfs 54.227.191.101:/iso /mnt/iso
# mount -t nfs 54.227.191.101:/linuxu /mnt/linuxu/
 mkdir -p /mnt/linuxu;mount -t nfs 54.227.191.101:/linuxu /mnt/linuxu;alias m='/mnt/linuxu/m.sh'
 mkdir -p /mnt/iso;mount -t nfs 54.227.191.101:/iso /mnt/iso
fi
export PATH="/data/scripts:/data/scripts/util:$PATH"
export M2_HOME=/usr/bin/maven
export PATH=${M2_HOME}/bin:${PATH}
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.14.1.1-6.el8.s390x
export PATH=${JAVA_HOME}/bin:${PATH}
export PATH=/usr/local/nodejs/bin:$PATH
export PATH=/usr/local/bin:/usr/local/go/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH
export PATH=/usr/local/glib-2.66.8/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/glib-2.66.8/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=/usr/local/glib-2.66.8/lib/pkgconfig:$PKG_CONFIG_PATH

