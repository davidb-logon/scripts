\rm -f ch_dev_names.log ch_dev_names.log2 ch_dev_names.log3
 \rm -f /etc/udev/rules.d/70-persistent-net.rules
 echo "systemvm from $(date)" >> template.version
 systemctl daemon-reload
 shutdown -h now