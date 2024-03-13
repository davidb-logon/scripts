
#echo "`cmk  list zones`" | grep ^id\ = | awk '{print $3}'
ip3="192.168.1"
ip4="192.168.1.248"
dns_ext=8.8.8.8
dns_int="$ip3.1"

#20_delete_zones.sh

cmk set display text
zone_ids=$(cmk list zones | grep "id =" | awk '{print $3}')
echo "$zone_ids"

# zone_id=$(echo "`cmk -o text create zone dns1=$dns_ext internaldns1=$dns_int name=ubuntu_zone networktype=Basic`") # | grep ^id\ = | awk '{print $3}')
# echo $zone_id