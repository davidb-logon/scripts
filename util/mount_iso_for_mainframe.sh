mkdir -p /mnt/iso
mkdir -p /mnt/linuxu
mount -t nfs 54.227.191.101:/iso /mnt/iso
mount -t nfs 54.227.191.101:/linuxu /mnt/linuxu
mount -o loop /mnt/iso/rhel/rhel-8.6-s390x-dvd.iso /mnt/rhel86/baseos
mount -o loop /mnt/iso/rhel/supp-supplementary-8.6-rhel-8-s390x-dvd.iso /mnt/rhel86/supp/
mount -o loop /mnt/iso/rhel/rhel-baseos-9.1-s390x-dvd.iso /mnt/rhel91/BaseOs
#mount -o loop /mnt/iso/rhel/supp-supplementary-8.6-rhel-8-s390x-dvd.iso /mnt/rhel86/supp/
alias v='/mnt/linuxu/v.sh' 