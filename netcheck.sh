while true; do
    datetime=$(date +"%Y%m%d-%H%M%S")
    ping -c 1 8.8.8.8
    if [[ $? = 1 ]]; then
        echo "$datetime sudo /data/primary/net1.sh"|tee >> logs/netcheck.log
        sudo /data/primary/net1.sh
      else
         gcho "$datetime network is fine" | tee >> logs/netcheck.log    
    fi
    sleep 60  # Optional: Adds a delay of 1 second before the next iteration
done


