# 参考资料
```
https://www.youtube.com/watch?v=x_Wjic4K4c4
https://jessexuan.github.io/2019/01/28/l2tpv3_setup_manual/
```

# 命令
```
# https://github.com/lukuichina/youtube/blob/main/2026/895/memo.txt

server
ip l2tp add tunnel tunnel_id 101 peer_tunnel_id 501 local 10.2.80.2 remote 111.101.5.1 encap udp udp_sport 2600 udp_dport 13606
ip l2tp add session tunnel_id 101 session_id 1001 peer_session_id 5001
ip link set l2tpeth0 up mtu 1488
ip addr add 10.42.1.1 peer 10.42.1.2 dev l2tpeth0
ip route add 192.168.10.0/24 via 10.42.1.2 dev l2tpeth0

client
ip l2tp add tunnel tunnel_id 501 peer_tunnel_id 101 local 192.168.10.9 remote 57.129.106.133 encap udp udp_sport 13606 udp_dport 2600
ip l2tp add session tunnel_id 501 session_id 5001 peer_session_id 1001
ip link set l2tpeth0 up mtu 1488
ip addr add 10.42.1.2 peer 10.42.1.1 dev l2tpeth0
ip route add 10.2.80.0/24 via 10.42.1.1 dev l2tpeth0
```
