#sed 's/.*\([0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\),\([0-9]*\)\s\+\(INFO\|WARN\|ERROR\)\s\+\[.*\]\s\+(.*:\(.*\))\s\+(logid:.*\)\s\(.*\)$/\1 \3 \6/' /var/log/cloudstack/management/management-server.log
cd ~/logon/work
pwd
sudo cp /var/log/cloudstack/management/management-server.log 1.txt
sudo sed -E 's/^.*([0-9]{2}:[0-9]{2}:[0-9]{2}),[0-9]+ (INFO|WARN|ERROR).*\] \([^)]*\) \([^)]*\) (.*)$/\1 \2 \3/'  1.txt | tee 2.txt > /dev/null 
