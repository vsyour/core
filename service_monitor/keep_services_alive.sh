#!/bin/bash

# ===========================
# 1. 基础配置与版本信息
# ===========================
VERSION="1.1" # 🚨 记得每次在 GitHub 更新时修改此值
REMOTE_URL="https://raw.githubusercontent.com/vsyour/core/refs/heads/main/service_monitor/keep_services_alive.sh"

SCRIPT_PATH=$(readlink -f "$0")
LOG_FILE="/var/log/service_monitor.log"

export LC_ALL=C
export LANG=C
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# ===========================
# 2. 核心函数定义
# ===========================

# 定义写日志函数
write_log() {
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# 检查并安装 dos2unix
ensure_dos2unix() {
    if ! command -v dos2unix >/dev/null 2>&1; then
        write_log "🔧 未检测到 dos2unix，准备自动安装..."
        
        # 判断是 Debian/Ubuntu 还是 CentOS/RHEL
        if command -v apt-get >/dev/null 2>&1; then
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -qq && apt-get install -y dos2unix >/dev/null 2>&1
        elif command -v yum >/dev/null 2>&1; then
            yum install -y dos2unix >/dev/null 2>&1
        else
            write_log "❌ 无法确定系统的包管理器，请手动安装 dos2unix。"
            return 1
        fi
        
        # 再次检查是否安装成功
        if command -v dos2unix >/dev/null 2>&1; then
            write_log "✅ dos2unix 安装成功。"
        else
            write_log "❌ dos2unix 安装失败，接下来的脚本更新可能会因格式问题报错。"
        fi
    fi
}

# 自动更新函数
check_update() {
    local tmp_file="/tmp/service_monitor_latest.sh"
    
    # 下载远程脚本
    if curl -sL --connect-timeout 10 -m 20 "$REMOTE_URL" -o "$tmp_file"; then
        
        # 🚨 关键步骤：先转换格式，再读取版本号和执行校验
        ensure_dos2unix
        if command -v dos2unix >/dev/null 2>&1; then
            dos2unix -q "$tmp_file"
        fi

        # 解析远程文件中的 VERSION 变量值
        local remote_version=$(grep "^VERSION=" "$tmp_file" | head -n 1 | cut -d'"' -f2)
        
        if [ -n "$remote_version" ] && [ "$remote_version" != "$VERSION" ]; then
            
            # 安全校验：确保文件合法且无语法错误
            if grep -q "^#!/bin/bash" "$tmp_file" && bash -n "$tmp_file"; then
                write_log "🔄 发现新版本 (v$VERSION -> v$remote_version)，正在更新..."
                
                # 覆盖当前脚本并赋权
                cat "$tmp_file" > "$SCRIPT_PATH"
                chmod +x "$SCRIPT_PATH"
                rm -f "$tmp_file"
                
                write_log "✅ 脚本更新完成，重启当前进程执行新版本..."
                
                # 重新执行新脚本
                exec bash "$SCRIPT_PATH" "$@"
            else
                write_log "❌ 下载的更新文件语法校验失败 (可能是格式或网络问题)，放弃更新。"
                rm -f "$tmp_file"
            fi
        else
            rm -f "$tmp_file"
        fi
    else
        write_log "⚠️ 无法连接获取更新信息，继续执行当前版本逻辑..."
    fi
}

# ===========================
# 3. 执行自更新检查
# ===========================
check_update


# ===========================
# 4. 业务监控逻辑
# ===========================

# --- 监控宝塔面板 (Bt-Panel) ---
if /etc/init.d/bt status | grep -q "Bt-Panel not running"; then
    write_log "🚨 检测到 Bt-Panel 未运行，尝试重启..."
    /etc/init.d/bt restart >> "$LOG_FILE" 2>&1
    sleep 2
    if /etc/init.d/bt status | grep -q "Bt-Panel not running"; then
        write_log "❌ Bt-Panel 重启失败，请人工检查。"
    else
        write_log "✅ Bt-Panel 已恢复运行。"
    fi
fi

# --- 监控 MySQL ---
if [ -f /etc/init.d/mysqld ]; then
    if /etc/init.d/mysqld status | grep -qE "not running|stopped" || ! pgrep -x "mysqld" > /dev/null; then
        write_log "🚨 检测到 MySQL 未运行，尝试重启..."
        /etc/init.d/mysqld restart >> "$LOG_FILE" 2>&1
        sleep 10
        if pgrep -x "mysqld" > /dev/null; then
             write_log "✅ MySQL 重启指令已执行，进程已恢复。"
        else
             write_log "❌ MySQL 重启尝试失败（或启动过慢），请检查错误日志。"
        fi
    fi
fi

# --- 监控 Nginx ---
if [ -f /etc/init.d/nginx ]; then
    if /etc/init.d/nginx status | grep -qE "not running|stopped" || ! pgrep -x "nginx" > /dev/null; then
        write_log "🚨 检测到 Nginx 未运行，尝试重启..."
        /etc/init.d/nginx restart >> "$LOG_FILE" 2>&1
        sleep 3
        if pgrep -x "nginx" > /dev/null; then
            write_log "✅ Nginx 重启成功，服务已恢复。"
        else
            write_log "❌ Nginx 重启失败，请检查配置文件：nginx -t"
        fi
    fi
fi
