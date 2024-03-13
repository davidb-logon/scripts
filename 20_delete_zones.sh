#!/bin/bash

zone_ids=$(cmk list zones | grep "id =" | awk '{print $3}')
echo zone_ids:$zone_ids
# Loop through each zone ID and delete the zone
for id in $zone_ids; do
    
    cmk delete zone id=$id
    rc=$?
    if [ rc = 0 ]; then
        echo "Deleted zone: $id"
    else
        echo "failed to delete zone: $id"
        #exit 1
    fi
done

echo "All zones have been deleted."