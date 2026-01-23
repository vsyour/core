# Cloudflare Tunnel 代理服务
```
【第896期】【Github系列】神器：cftun初体验（上：隧道模式）1，支持cloudflare匿名隧道2，支持web以外的TCP/UDP服务转发3，提供tun/隧道2种模式，支持不同的应用场景！
https://www.youtube.com/watch?v=9xeC4WWBokE

https://github.com/fmnx/cftun/blob/master/README_ZH.md

```

# 服务端
```
mkdir -p cftun && cd cftun && curl -L --progress-bar https://github.com/fmnx/cftun/releases/download/v2.1.4/cftun-linux-amd64 -o cftun-linux-amd64 && chmod +x cftun-linux-amd64 && printf '{ "server": { "token": "quick", "edge-ips": ["198.41.192.77:7844","198.41.197.78:7844","198.41.202.79:7844","198.41.207.80:7844"], "ha-conn": 4, "bind-address": "" } }\n' > config.json && ./cftun-linux-amd64

```
