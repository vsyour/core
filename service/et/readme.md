# download
```
https://github.com/vsyour/core/raw/refs/heads/main/service/et/cored
```


# Service
```
wget -O /usr/local/bin/cored https://github.com/vsyour/core/raw/refs/heads/main/service/et/cored
chmod +x /usr/local/bin/cored
tee /etc/systemd/system/cored.service > /dev/null <<EOF
[Unit]
Description=Cored Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/cored
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start cored
systemctl enable cored
systemctl status cored




```
