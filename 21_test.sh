#!/bin/bash

parse() {
    clients=("$@")
}

parse "$@"

for client in "${clients[@]}"; do
    echo "client:"$client
done

echo "${clients[*]}"

# #echo "`cmk  list zones`" | grep ^id\ = | awk '{print $3}'
# ip3="192.168.1"
# ip4="192.168.1.248"
# dns_ext=8.8.8.8
# dns_int="$ip3.1"

# #20_delete_zones.sh

# cmk set display text
# zone_ids=$(cmk list zones | grep "id =" | awk '{print $3}')
# echo "$zone_ids"

# # zone_id=$(echo "`cmk -o text create zone dns1=$dns_ext internaldns1=$dns_int name=ubuntu_zone networktype=Basic`") # | grep ^id\ = | awk '{print $3}')
# # echo $zone_id


# # List all zones and their storagepools
# #
# # @example
# # list_all_zones
# #
# # @return void
# list_all_zones() {
#     # Get list of zone names
#     cmk list zones | \
#     grep "name =" | \
#     awk '{print $3}' | \
#     # For each zone name
#     while read zone_name; do
#         # Print zone name and a colon
#         echo "$zone_name:"
#         # Get list of storagepool names for the zone
#         cmk list storagepools -z "$zone_name" | \
#         grep "name =" | \
#         awk '{print "    "$3}'
#     done
# }




# # put a storagepool in maintenance state
# #
# # @example
# # put_storagepool_in_maintenance ubuntu_zone StoragePool-248
# #
# # @param string $zone_name
# # @param string $sp_name
# # @return void


