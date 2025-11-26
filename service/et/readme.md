# download
```
https://github.com/vsyour/core/raw/refs/heads/main/service/et/cored
```


# Service
```
wget -O /usr/sbin/cored https://github.com/vsyour/core/raw/refs/heads/main/service/et/cored
chmod +x /usr/sbin/cored

cat /etc/systemd/system/cored.service > /dev/null <<EOF
[Unit]
Description=Cored Network Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/sbin/cored --network-name 'ytmWLXky1lUhvoNT' --network-secret 'RVwVQber0QK9AKmF' --multi-thread --use-smoltcp --latency-first --enable-kcp-proxy -l tcp://0:40000 udp://0:40000 wg://0:39999 ws://0:39999 wss://0:39998 -i 192.7.7.79/24
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

chmod a+x /etc/systemd/system/cored.service


systemctl daemon-reload
systemctl start cored
systemctl enable cored
systemctl status cored

```

