# 自动监控
1. 自动监控宝塔状态
2. 自动监控 mysql 状态
3. 自动监控 nginx 状态


# 执行命令
```
curl -sL 'https://raw.githubusercontent.com/vsyour/core/refs/heads/main/service_monitor/keep_services_alive.sh' -o /root/keep_services_alive.sh;
sed -i 's/\\r//g' /root/keep_services_alive.sh;
chmod +x /root/keep_services_alive.sh;
touch /var/log/service_monitor.log;
chmod 755 /var/log/service_monitor.log;
(crontab -l 2>/dev/null | grep -v 'keep_services_alive.sh' || true; echo '*/5 * * * * LC_ALL=C /root/keep_services_alive.sh >> /var/log/keep_services.log 2>&1') | crontab -;
systemctl restart cron 2>/dev/null || systemctl restart crond 2>/dev/null || service cron restart 2>/dev/null || service crond restart 2>/dev/null;crontab -l
```
