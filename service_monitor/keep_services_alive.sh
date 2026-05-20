#!/bin/bash

# ===========================
# 1. Configuration & Version
# ===========================
VERSION="1.3"
REMOTE_URL="https://raw.githubusercontent.com/vsyour/core/refs/heads/main/service_monitor/keep_services_alive.sh"

SCRIPT_PATH=$(readlink -f "$0")
LOG_FILE="/var/log/service_monitor.log"

export LC_ALL=C
export LANG=C
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Logging function
write_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Auto-update function
check_update() {
    local tmp_file="/root/service_monitor_latest.sh"
    
    if curl -sL --connect-timeout 10 -m 20 "$REMOTE_URL" -o "$tmp_file"; then
        
        sed -i 's/\r//g' "$tmp_file" 2>/dev/null
        
        if [ -f "$tmp_file" ]; then
            local remote_version=$(grep "^VERSION=" "$tmp_file" | head -n 1 | cut -d'"' -f2)
            
            if [ -n "$remote_version" ] && [ "$remote_version" != "$VERSION" ]; then
                if grep -q "^#!/bin/bash" "$tmp_file" && bash -n "$tmp_file"; then
                    write_log "[Update] New version found (v$VERSION -> v$remote_version), updating..."
                    cat "$tmp_file" > "$SCRIPT_PATH"
                    chmod +x "$SCRIPT_PATH"
                    rm -f "$tmp_file"
                    write_log "[Success] Script updated, restarting process with new version..."
                    exec bash "$SCRIPT_PATH" "$@"
                else
                    write_log "[Error] Downloaded file has syntax errors, aborting update."
                    rm -f "$tmp_file"
                fi
            else
                rm -f "$tmp_file"
            fi
        fi
    else
        write_log "[Warning] Cannot connect to fetch update info, continuing with current version..."
    fi
}

check_update

# ===========================
# 2. Service Monitoring Logic
# ===========================

# --- Monitor Bt-Panel ---
if [ -f /etc/init.d/bt ]; then
    if /etc/init.d/bt status | grep -q "Bt-Panel not running"; then
        write_log "[Alert] Bt-Panel is not running, attempting restart..."
        /etc/init.d/bt restart >> "$LOG_FILE" 2>&1
        sleep 2
    fi
fi

# --- Monitor MySQL ---
if [ -f /etc/init.d/mysqld ]; then
    if /etc/init.d/mysqld status | grep -qE "not running|stopped" || ! pgrep -x "mysqld" > /dev/null; then
        write_log "[Alert] MySQL is not running, attempting restart..."
        /etc/init.d/mysqld restart >> "$LOG_FILE" 2>&1
        sleep 10
    fi
fi

# --- Monitor Nginx ---
if [ -f /etc/init.d/nginx ]; then
    if /etc/init.d/nginx status | grep -qE "not running|stopped" || ! pgrep -x "nginx" > /dev/null; then
        write_log "[Alert] Nginx is not running, attempting restart..."
        /etc/init.d/nginx restart >> "$LOG_FILE" 2>&1
        sleep 3
    fi
fi

# --- Monitor PHP-FPM ---
# Auto-detects and monitors all installed PHP versions in Bt-Panel
for php_script in /etc/init.d/php-fpm-*; do
    if [ -x "$php_script" ]; then
        php_version=$(basename "$php_script" | sed 's/php-fpm-//')
        
        if "$php_script" status | grep -qE "not running|stopped" || ! pgrep -f "php-fpm: master process.*$php_version" > /dev/null; then
            write_log "[Alert] PHP-FPM $php_version is not running, attempting restart..."
            "$php_script" restart >> "$LOG_FILE" 2>&1
            sleep 2
        fi
    fi
done
