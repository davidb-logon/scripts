#!/bin/bash
cd /home/davidb
for dir in "/var/log/cloudstack" "/etc/cloudstack"; do
    sudo chmod -R 777 "$dir"
    link_name="link-to${dir//\//-}"
    echo link_name="$link_name"
    ln -s "$dir" "$link_name"
done