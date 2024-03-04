virt-install --name rocky9 --memory 4096 --vcpus=2  --os-variant=rocky9.0  \
    --network network=default --graphics=none -v \
    --disk path=/export/primary/rocky9.qcow2,size=40 \
    --extra-args ro \
    --check disk_size=off --boot hd \
    --location=/export/secondary/template/tmpl/2/202/202-2-0a553cca-3527-34cf-9099-18ac6b6b4938.iso