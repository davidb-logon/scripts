virt-install --name ubuntu --memory 4096 --vcpus=2  --os-variant=ubuntu22.04  \
    --network network=default --graphics=none -v \
    --disk path=/export/primary/ubuntu2204.qcow2,size=10 \
    --extra-args ro \
    --check disk_size=off --boot hd \
    --location=/export/secondary/ubuntu-22.04.4-desktop-amd64.iso