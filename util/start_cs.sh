sudo systemctl stop cloudstack-management.service
sudo systemctl stop cloudstack-agent.service 
sudo rm -f /var/log/cloudstack/management/management-server.log
sudo rm -f /var/log/cloudstack/agent/agent.log 
virsh net-start default
sudo systemctl start cloudstack-management.service
sudo systemctl start cloudstack-agent.service 