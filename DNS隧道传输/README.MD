# DNS隧道传输参考资料
```
https://www.henry404.com/henrys-blog/sui-dao-ying-yong/dns-sui-dao-chuan-shu
```

# 准备
```
假设你的域名是 example.com，VPS IP 是 1.2.3.4。
添加 A 记录:
  名称 (Name): ns1 (或者其他你喜欢的名字)
  类型 (Type): A
  值 (Value): 1.2.3.4 (你的 VPS IP)
作用：指定 DNS 服务器的物理地址。

添加 NS 记录:
  名称 (Name): tcp (这个将是你的隧道域名，如 tcp.example.com)
  类型 (Type): NS
  值 (Value): ns1.example.com (刚刚添加的 A 记录域名)
作用：告诉互联网，所有发往 *.tcp.example.com 的 DNS 请求，都由 ns1.example.com (即你的 VPS) 来解析。
```

# 服务端配置文件
```
# /etc/dns2tcpd.conf
# 监听地址：0.0.0.0 表示监听所有网卡接口
listen = 0.0.0.0

# 端口：必须是 53 (UDP)，因为 DNS 协议标准就是 53
port = 53

# 运行用户：出于安全考虑，不要用 root 运行，建议使用 nobody
user = nobody

# Chroot 目录：限制程序访问文件系统的范围，增加安全性
chroot = /tmp

# PID 文件路径
pid_file = /var/run/dns2tcpd.pid

# [重要] 隧道域名
# 必须和你 DNS 服务商处设置的 NS 记录一致
# 例如：你的 NS 记录是 tcp.abc.com -> vps_ip，这里就填 tcp.abc.com
domain = tcp.yourdomain.com

# [重要] 认证密码
# 客户端连接时必须提供此密码
key = ChangeMe123

# [核心] 资源映射
# 格式：资源名:目标IP:目标端口
# 最常用的是映射 SSH (127.0.0.1:22)
# 客户端连接时使用 -r ssh 即可连接到服务器的 SSH
resources = ssh:127.0.0.1:22,socks:127.0.0.1:1080
```



# 客户端连接命令
```
# 注意最后的 IP 是 127.0.0.1
dns2tcpc -z tcp.yourdomain.com -k 123456 -r ssh -l 8888 127.0.0.1


# 2. 连接隧道，开启代理
# -p 8888: 连接本地隧道端口
# -D 1080: 开启本地 1080 SOCKS 代理 (这才是给 curl 用的)
# -N: 不执行远程命令，只做转发 (挂住不退出)
# user: 换成你 VPS 的用户名
ssh -p 8888 -D 1080 -N user@127.0.0.1 &


# 通过 1080 代理访问外网
curl -v -x socks5h://127.0.0.1:1080 https://ipinfo.io
```



## 注意事项
```
# 必须设置为 yes，否则无法使用 -D 1080 做代理
AllowTcpForwarding yes

# 建议同时检查这一项，确保不是 no
PermitOpen any
```
