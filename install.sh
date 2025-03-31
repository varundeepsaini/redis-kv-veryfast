sudo sysctl -w net.core.somaxconn=65535
sudo sysctl -w net.core.netdev_max_backlog=250000
sudo sysctl -w net.ipv4.tcp_tw_reuse=1
sudo sysctl -w net.ipv4.tcp_fin_timeout=15
sudo sysctl -w net.ipv4.ip_local_port_range="1024 65535"

docker run -p 7171:7171 --ulimit nofile=65536:65536 --network=host deepsainivarun/redis-kv-veryfast-c
