# 参考视频
```
https://www.youtube.com/watch?v=aKW-Sgh41UU
```

# 服务端
```
modprobe tun
./vpncloud_2.3.0_static_amd64 -l 2600 -p 123 --ip 10.144.144.1 --claim 0.0.0.0/0

访问客户端背后网段：
ip r add 192.168.10.0/24 dev vpncloud0

防火墙设置：
iptables -t nat -A POSTROUTING -j MASQUERADE
sysctl -w net.ipv4.ip_forward=1 -p
```

# 客户端：
```
排除服务端公网IP，让其走默认网卡：
ip r add 57.129.106.133/32 via 192.168.10.1 dev eth0

./vpncloud_2.3.0_static_amd64 -c 57.129.106.133:2600 -p 123 --ip 10.144.144.2 --claim 192.168.10.0/24

添加默认路由，让VPN虚拟网卡接管IPV4流量：
ip r add default dev vpncloud0 metric 100

测试：
curl ip.me
```
