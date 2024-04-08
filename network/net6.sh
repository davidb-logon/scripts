set -x
ip -c -br link show
ip link add name eth1 type veth peer eth_1
ip -c -br link show
ip link set dev eth_1 up
ip address add 204.90.115.239/24 dev eth_1
ip link set dev eth1 master cloudbr0
ip link set dev eth1 up
sleep 5
ip link set dev cloudbr0 up
ip -c -br address show

