#!/bin/bash

# ===========================
# 1. 基础配置与版本信息
# ===========================
VERSION="1.2" # 🚨 版本已升至 1.2
REMOTE_URL="https://raw.githubusercontent.com/vsyour/core/refs/heads/main/service_monitor/keep_services_alive.sh"

SCRIPT_PATH=$(readlink -f "$0")
LOG_FILE="/var/log/service_monitor.log"

export LC_ALL=C
export LANG=C
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# 写日志函数
write_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 自动更新函数 (已彻底剥离 dos2unix 依赖，避开 /tmp 目录)
check_update() {
    local tmp_file="/root/service_monitor_latest.sh" # 改到 /root 目录下
    
    if curl -sL --connect-timeout 10 -m 20 "$REMOTE_URL" -o "$tmp_file"; then
        
        # 使用 Linux 原生 sed 强力清除 Windows 回车符，比 dos2unix 更稳且无需安装
        sed -i 's/\r//g' "$tmp_file" 2>/dev/null
        
        # 确保文件确实存在，防止报错
        if [ -f "$tmp_file" ]; then
            local remote_version=$(grep "^VERSION=" "$tmp_file" | head -n 1 | cut -d'"' -f2)
            
            if [ -n "$remote_version" ] && [ "$remote_version" != "$VERSION" ]; then
                if grep -q "^#!/bin/bash" "$tmp_file" && bash -n "$tmp_file"; then
                    write_log "🔄 发现新版本 (v$VERSION -> v$remote_version)，正在更新..."
                    cat "$tmp_file" > "$SCRIPT_PATH"
                    chmod +x "$SCRIPT_PATH"
                    rm -f "$tmp_file"
                    write_log "✅ 脚本更新完成，重启当前进程执行新版本..."
                    exec bash "$SCRIPT_PATH" "$@"
                else
                    write_log "❌ 下载的文件语法错误，放弃更新。"
                    rm -f "$tmp_file"
                fi
            else
                rm -f "$tmp_file"
            fi
        fi
    else
        write_log "⚠️ 无法连接获取更新信息，继续执行当前版本..."
    fi
}

check_update

# ===========================
# 2. 业务监控逻辑
# ===========================
# --- 监控宝塔面板 (Bt-Panel) ---
if [ -f /etc/init.d/bt ]; then
    if /etc/init.d/bt status | grep -q "Bt-Panel not running"; then
        write_log "🚨 检测到 Bt-Panel 未运行，尝试重启..."
        /etc/init.d/bt restart >> "$LOG_FILE" 2>&1
        sleep 2
    fi
fi

# --- 监控 MySQL ---
if [ -f /etc/init.d/mysqld ]; then
    if /etc/init.d/mysqld status | grep -qE "not running|stopped" || ! pgrep -x "mysqld" > /dev/null; then
        write_log "🚨 检测到 MySQL 未运行，尝试重启..."
        /etc/init.d/mysqld restart >> "$LOG_FILE" 2>&1
        sleep 10
    fi
fi

# --- 监控 Nginx ---
if [ -f /etc/init.d/nginx ]; then
    if /etc/init.d/nginx status | grep -qE "not running|stopped" || ! pgrep -x "nginx" > /dev/null; then
        write_log "🚨 检测到 Nginx 未运行，尝试重启..."
        /etc/init.d/nginx restart >> "$LOG_FILE" 2>&1
        sleep 3
    fi
fi
