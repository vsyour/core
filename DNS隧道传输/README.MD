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

## 远端非53端口可以通过本地转发
```
# iptables 转发的方案
# 请将 <VPS_IP> 替换为你服务器的真实 IP 地址
# 逻辑：凡是发往 VPS UDP 53 的包，全部改写目标端口为 2319
sudo iptables -t nat -A OUTPUT -p udp -d <VPS_IP> --dport 53 -j DNAT --to-destination <VPS_IP>:2319

## 使用 socat 替代 iptables
# 解释：监听本地 UDP 53 端口，收到数据后，转发给 1.2.3.4 的 2319 端口
# & 符号表示在后台运行
socat UDP4-LISTEN:53,fork UDP4:1.2.3.4:2319 &
```





# 其他参考信息
##安装 
```
  Kali Linux (预装):                                                                                                                                                                              
  dns2tcpd --version                                                                                                                                                                              
  dns2tcpc --version                                                                                                                                                                              
                                                                                                                                                                                                  
  Debian/Ubuntu:                                                                                                                                                                                  
  sudo apt install dns2tcp                                                                                                                                                                        
                                                                                                                                                                                                  
  源码编译:                                                                                                                                                                                       
  git clone https://github.com/alex-sector/dns2tcp.git                                                                                                                                            
  cd dns2tcp                                                                                                                                                                                      
  ./configure && make                                                                                                                                                                             
  sudo make install                                                                                                                                                                               
```

## 服务端配置 (dns2tcpd)                                                                                                                                                                           
```
  1. 创建配置文件 /etc/dns2tcpd.conf:                                                                                                                                                             
  listen = 0.0.0.0                                                                                                                                                                                
  port = 53                                                                                                                                                                                       
  user = nobody                                                                                                                                                                                   
  chroot = /var/empty/dns2tcp                                                                                                                                                                     
                                                                                                                                                                                                  
  domain = yourdomain.com                                                                                                                                                                         
  resources = ssh:127.0.0.1:22, smtp:127.0.0.1:25, http:127.0.0.1:8080                                                                                                                            
                                                                                                                                                                                                  
  2. 启动服务端守护进程:                                                                                                                                                                          
  sudo dns2tcpd -F -f /etc/dns2tcpd.conf                                                                                                                                                          
```
## DNS记录配置                                                                                                                                                                                     
在您的域名DNS中添加以下记录：                                                                                                                                                                   
```
  # A记录指向隧道服务器                                                                                                                                                                           
  tunnel        IN  A  your.server.ip                                                                                                                                                             
                                                                                                                                                                                                  
  # NS记录委派子域                                                                                                                                                                                
  dnstunnel     IN  NS  tunnel.yourdomain.com                                                                                                                                                     
```

## 客户端使用 (dns2tcpc)                                                                                                                                                                                          
```
列出可用资源:
  dns2tcpc -z dnstunnel.yourdomain.com your.server.ip                                                                                                                                             
                                                                                                                                                                                                  
  连接SSH:                                                                                                                                                                                        
  dns2tcpc -z dnstunnel.yourdomain.com -r ssh your.server.ip                                                                                                                                      
                                                                                                                                                                                                  
  通过DNS隧道使用SSH:                                                                                                                                                                             
  # 本地启动dns2tcp客户端                                                                                                                                                                         
  dns2tcpc -z dnstunnel.yourdomain.com -l 8888 -r ssh your.server.ip &                                                                                                                            
                                                                                                                                                                                                  
  # 通过隧道SSH连接                                                                                                                                                                               
  ssh -p 8888 user@localhost                                                                                                                                                                      
                                                                                                                                                                                                  
  调试模式连接:                                                                                                                                                                                   
  dns2tcpc -z dnstunnel.yourdomain.com -r ssh -d your.server.ip                                                                                                                                   

```

## 常用资源配置
```
  resources = ssh:127.0.0.1:22,           # SSH隧道                                                                                                                                               
                smtp:127.0.0.1:25,        # SMTP/邮件                                                                                                                                             
                pop3:127.0.0.1:110,       # POP3                                                                                                                                                  
                http:127.0.0.1:3128,      # HTTP代理                                                                                                                                              
                https:127.0.0.1:8443      # HTTPS                                                                                                                                                 
                                                                                                                                                                                                  
  完整使用示例                                                                                                                                                                                    
                                                                                                                                                                                                  
  场景：绕过强制门户 + SSH隧道                                                                                                                                                                    
                                                                                                                                                                                                  
  # 1. 服务器端 (VPS)                                                                                                                                                                             
  sudo dns2tcpd -F -f /etc/dns2tcpd.conf                                                                                                                                                          
                                                                                                                                                                                                  
  # 2. 客户端 (被限制网络)                                                                                                                                                                        
  dns2tcpc -z dnstunnel.example.com -l 2222 -r ssh 1.2.3.4                                                                                                                                        
                                                                                                                                                                                                  
  # 3. 通过DNS隧道SSH                                                                                                                                                                             
  ssh -p 2222 user@localhost                                                                                                                                                                      
                                                                                                                                                                                                  
  检测DNS隧道流量                                                                                                                                                                                 
                                                                                                                                                                                                  
  # 捕获DNS TXT/KEY请求                                                                                                                                                                           
  tcpdump -i any -n 'port 53 and (txt or key)' -v                                                                                                                                                 
                                                                                                                                                                                                  
  # 子域名编码检测                                                                                                                                                                                
  tcpdump -i any -n 'port 53' -A | grep -E '^[0-9a-f]{32,}'                                                                                                                                       
 ```

## 性能参考                                                                                                                                                                                        
  ┌──────────┬────────────────────────────┐                                                                                                                                                       
  │   指标    │           典型值           │                                                                                                                                                       
  ├──────────┼────────────────────────────┤                                                                                                                                                       
  │ 吞吐量    │ 1-3 KB/s                   │                                                                                                                                                       
  ├──────────┼────────────────────────────┤                                                                                                                                                       
  │ 延迟      │ 100-500ms/包               │                                                                                                                                                       
  ├──────────┼────────────────────────────┤                                                                                                                                                       
  │ 适用场景  │ SSH、IRC；不适合大文件传输    │                                                                                                                                                       
  └──────────┴────────────────────────────┘                                                                                                                                                       
  ---                                                                                                                                                                                             
  ⚠️ 安全提醒：                                                                                                                                                                                   
  - dns2tcp默认无加密，建议配合SSH/VPN使用                                                                                                                                                        
  - 仅用于授权的安全测试和研究                                                                                                                                                                    
  - 流量特征明显，易被检测    
