# tlscore
```
wget -O /usr/sbin/tlscore https://github.com/vsyour/core/raw/refs/heads/main/service/tlscore/tlscore
chmod +x /usr/sbin/tlscore

tee /etc/systemd/system/tlscore.service > /dev/null <<EOF
[Unit]
Description=tlscore Network Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/sbin/tlscore -l 192.7.7.1:39997 -p 'RVwVQber0QK9AKmF'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

chmod a+x /etc/systemd/system/tlscore.service


systemctl daemon-reload
systemctl start tlscore
systemctl enable tlscore
systemctl status tlscore

```
