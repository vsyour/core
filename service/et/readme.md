# download
```
https://github.com/vsyour/core/raw/refs/heads/main/service/et/cored
```


# Service
```
wget -O /usr/sbin/cored https://github.com/vsyour/core/raw/refs/heads/main/service/et/cored
chmod +x /usr/sbin/cored

tee /etc/systemd/system/cored.service > /dev/null <<EOF
[Unit]
Description=Core Network Service
Documentation=Core Network Service
DefaultDependencies=no
After=network-pre.target
Before=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/cored --network-name 'ytmWLXky1lUhvoNT' --network-secret 'RVwVQber0QK9AKmF' --multi-thread --use-smoltcp --latency-first --enable-kcp-proxy -l tcp://0:11000 udp://0:11000 wg://0:11001 ws://0:11001 wss://0:11002
Restart=always
RestartSec=2
StartLimitIntervalSec=0
LimitNOFILE=1048576

User=root

[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload
systemctl start cored
systemctl enable cored
systemctl status cored

```

