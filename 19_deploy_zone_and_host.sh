#!/bin/bash
# root@ubuntu:~/snap/cloudmonkey/17/.cmk# vi config
#apt-get install js
 
ip3="192.168.1"
ip4="192.168.1.248"
dns_ext=8.8.8.8
dns_int="$ip3.1"
gw="$ip3.1"
nmask=255.255.255.0
hpvr=KVM
pod_start="$ip3.160"
pod_end="$ip3.169"
vlan_start="$ip3.170"
vlan_end="$ip3.179"

20_delete_zones.sh

#Put space separated host ips in following
host_ips="$ip4"
host_user=root
host_passwd=logon1vm
sec_storage=nfs://${ip4}/data/ubuntu_secondary
prm_storage=nfs://${ip4}/data/ubuntu_primary

create_zone() {
  local json=$(cmk create zone dns1=$dns_ext internaldns1=$dns_int name=ubuntu_zone networktype=Basic)
  rc=$?
  echo rc=$rc
  if [ $rc = 0 ]; then
    local zone_id=$(echo $json | sed 's/zone = //g' | jq -r '.id')
    echo "$zone_id"
  else
    echo "Create zone failed, rc = $rc"
    exit 1
  fi
}

create_physical_network() {
  local zone_id=$1
  local json=$(cmk create physicalnetwork name=phy-network zoneid=$zone_id)
  rc=$?
  if [ rc = 0 ]; then
    local phy_id=$(echo $json | sed 's/physicalnetwork = //g' | jq -r '.id')
    echo "$phy_id"
  else
    echo "Create physical netwwork failed. rc = $rc"
    exit 1
  fi
}


ZONE_ID=$(create_zone)
echo Created zone: $ZONE_ID
create_physical_network "$ZONE_ID"




exit


phy_id=`$cli create physicalnetwork name=phy-network zoneid=$zone_id | grep ^id\ = | awk '{print $3}'`
echo "Created physical network" $phy_id


$cli add traffictype traffictype=Guest physicalnetworkid=$phy_id
echo "Added guest traffic"
$cli add traffictype traffictype=Management physicalnetworkid=$phy_id
echo "Added mgmt traffic"
$cli update physicalnetwork state=Enabled id=$phy_id
echo "Enabled physicalnetwork"
 
nsp_id=`$cli list networkserviceproviders name=VirtualRouter physicalnetworkid=$phy_id | grep ^id\ = | awk '{print $3}'`
vre_id=`$cli list virtualrouterelements nspid=$nsp_id | grep ^id\ = | awk '{print $3}'`
$cli api configureVirtualRouterElement enabled=true id=$vre_id
$cli update networkserviceprovider state=Enabled id=$nsp_id
echo "Enabled virtual router element and network service provider"
 
nsp_sg_id=`$cli list networkserviceproviders name=SecurityGroupProvider physicalnetworkid=$phy_id | grep ^id\ = | awk '{print $3}'`
$cli update networkserviceprovider state=Enabled id=$nsp_sg_id
echo "Enabled security group provider"
 
netoff_id=`$cli list networkofferings name=DefaultSharedNetworkOfferingWithSGService | grep ^id\ = | awk '{print $3}'`
net_id=`$cli create network zoneid=$zone_id name=guestNetworkForBasicZone displaytext=guestNetworkForBasicZone networkofferingid=$netoff_id | grep ^id\ = | awk '{print $3}'`
echo "Created network $net_id for zone" $zone_id
 
pod_id=`$cli create pod name=MyPod zoneid=$zone_id gateway=$gw netmask=$nmask startip=$pod_start endip=$pod_end | grep ^id\ = | awk '{print $3}'`
echo "Created pod"
 
$cli create vlaniprange podid=$pod_id networkid=$net_id gateway=$gw netmask=$nmask startip=$vlan_start endip=$vlan_end forvirtualnetwork=false
echo "Created IP ranges for instances"
 
cluster_id=`$cli add cluster zoneid=$zone_id hypervisor=$hpvr clustertype=CloudManaged podid=$pod_id clustername=MyCluster | grep ^id\ = | awk '{print $3}'`
echo "Created cluster" $cluster_id
 
#Put loop here if more than one
for host_ip in $host_ips;
do
  $cli add host zoneid=$zone_id podid=$pod_id clusterid=$cluster_id hypervisor=$hpvr username=$host_user password=$host_passwd url=http://$host_ip;
  echo "Added host" $host_ip;
done;
 
#$cli create storagepool zoneid=$zone_id podid=$pod_id clusterid=$cluster_id name=MyNFSPrimary url=$prm_storage
#echo "Added primary storage"
 
$cli add secondarystorage zoneid=$zone_id url=$sec_storage
echo "Added secondary storage"
 
$cli update zone allocationstate=Enabled id=$zone_id
echo "Basic zone deloyment completed!"