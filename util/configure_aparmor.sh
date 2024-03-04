#!/bin/bash

# Check to see whether AppArmor is installed on your machine. If not, you can skip this section.

# In Ubuntu AppArmor is installed and enabled by default. You can verify this with:

#$ dpkg --list 'apparmor'
echo "Disable the AppArmor profiles for libvirt"

ln -s /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmor.d/disable/
ln -s /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper /etc/apparmor.d/disable/
apparmor_parser -R /etc/apparmor.d/usr.sbin.libvirtd
apparmor_parser -R /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper