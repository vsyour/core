# cloudflared
## client
```
# ech client
https://github.com/byJoey/ech-wk/releases
chmod +x ech-workers
chmod +x ECHWorkersGUI  # 如果使用 GUI

# start ech client
./ech-workers \
  -f your-worker.workers.dev:443 \
  -l 0.0.0.0:30001 \
  -token your-token \
  -ip saas.sin.fan \
  -dns dns.alidns.com/dns-query \
  -ech cloudflare-ech.com \
  -routing bypass_cn

# test
google-chrome --proxy-server="socks5://127.0.0.1:30001"
curl --socks5 127.0.0.1:30001 http://www.google.com

# set env
export ALL_PROXY=socks5://127.0.0.1:30001
export HTTP_PROXY=socks5://127.0.0.1:30001
export HTTPS_PROXY=socks5://127.0.0.1:30001
```

## server
### info
```
https://simi.studio/create-locally-managed-cloudflare-tunnel/
https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/local-management/create-local-tunnel/
https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/local-management/local-tunnel-terms/#default-cloudflared-directory

```


```
# download cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/download/2025.11.1/cloudflared-linux-amd64 -o cloudflared
chmod +x cloudflared

# login
cloudflared tunnel login
cloudflared tunnel create <NAME>
cloudflared tunnel list
cloudflared --config config.yml tunnel run fc69d070-711a-4b1a-be87-7769c944073b
cloudflared access tcp --hostname xxx.domain.com --url 127.0.0.1:20808



# create config file
tee "$(pwd)"/config.yml >/dev/null << EOF
tunnel: fc69d070-711a-4b1a-be87-7769c944073b
credentials-file: $(pwd)/fc69d070-711a-4b1a-be87-7769c944073b.json
ingress:
  - hostname: socks5.swings.one
    service: socks-proxy
    originRequest:
      ipRules:
        - prefix: 0.0.0.0/0
          allow: true
  - service: http://192.168.10.7:1080
    originRequest:
      noTLSVerify: true
EOF
```


# mullvad-browser

```
Creating a Mullvad account: https://mullvad.net/account/create
In the Mullvad VPN app: https://mullvad.net/en/download/vpn/linux
browser: https://mullvad.net/en/download/browser/linux

```

