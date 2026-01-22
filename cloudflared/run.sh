#!/bin/bash

# ================= 1. 全局配置 =================
# 脚本遇到错误立即退出，未定义的变量报错
set -u

# --- 代理配置 ---
PROXY_BIN="./ech-workers"
PROXY_LOG="ech-workers.log"
PROXY_URL="https://github.com/byJoey/ech-wk/releases/download/v1.4/ECHWorkers-linux-amd64.tar.gz"
PROXY_TAR="ECHWorkers-linux-amd64.tar.gz"

PROXY_PORT="30005"
PROXY_HOST="127.0.0.1"
PROXY_ADDR="0.0.0.0"
PROXY_ARGS="-f ech.autobots.eu.org:443 -l ${PROXY_ADDR}:${PROXY_PORT} -token admin -ip saas.sin.fan -dns dns.alidns.com/dns-query -ech cloudflare-ech.com"

# --- 浏览器配置 (15.0.4) ---
MB_VERSION="15.0.4"
MB_DIR="mullvad-browser"
MB_FILENAME="mullvad-browser-linux-x86_64-${MB_VERSION}.tar.xz"
MB_URL="https://github.com/mullvad/mullvad-browser/releases/download/${MB_VERSION}/${MB_FILENAME}"
MB_EXEC="${MB_DIR}/Browser/start-mullvad-browser"

# --- 颜色输出 ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ================= 2. 工具函数 =================

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERR]${NC} $1"; }

# 检查必要依赖
check_dependencies() {
    local deps=("curl" "tar" "pkill" "pgrep")
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "系统缺少必要命令: $cmd"
            exit 1
        fi
    done
}

# 检查代理连通性
check_proxy_connection() {
    # -s: Silent, -f: Fail fast, --connect-timeout: 3s
    curl -s -f --socks5 "${PROXY_HOST}:${PROXY_PORT}" https://ip.me --connect-timeout 3
}

# ================= 3. 核心流程 =================

# --- 阶段 A: 准备代理程序 ---
ensure_proxy_binary() {
    if [ ! -f "$PROXY_BIN" ]; then
        log_warn "未找到代理程序，开始下载..."
        
        if curl -# -L -o "$PROXY_TAR" "$PROXY_URL"; then
            tar -xf "$PROXY_TAR"
            rm "$PROXY_TAR"

            # 兼容性重命名
            [ -f "ECHWorkers-linux-amd64" ] && mv "ECHWorkers-linux-amd64" "$PROXY_BIN"

            if [ -f "$PROXY_BIN" ]; then
                chmod +x "$PROXY_BIN"
                log_success "代理程序安装成功"
            else
                log_error "解压失败，未找到 $PROXY_BIN"
                exit 1
            fi
        else
            log_error "代理程序下载失败"
            exit 1
        fi
    else
        chmod +x "$PROXY_BIN"
    fi
}

# --- 阶段 B: 启动与健康检查 ---
start_proxy_service() {
    # 1. 快速检查是否已经通了
    local current_ip
    current_ip=$(check_proxy_connection)
    
    if [ $? -eq 0 ] && [ -n "$current_ip" ]; then
        log_success "代理已在运行 (出口IP: $current_ip)"
        return 0
    fi

    # 2. 清理僵尸进程
    if pgrep -f "$PROXY_BIN.*-l ${PROXY_ADDR}:${PROXY_PORT}" > /dev/null; then
        log_warn "代理端口不通但进程存在，重启中..."
        pkill -f "$PROXY_BIN.*-l ${PROXY_ADDR}:${PROXY_PORT}"
        sleep 1
    fi

    # 3. 启动 (重置日志)
    log_info "启动代理服务..."
    echo "--- New Session $(date) ---" > "$PROXY_LOG"
    nohup $PROXY_BIN $PROXY_ARGS >> "$PROXY_LOG" 2>&1 &

    # 4. 循环检查
    log_info "等待端口就绪..."
    for i in {1..10}; do
        current_ip=$(check_proxy_connection)
        if [ $? -eq 0 ] && [ -n "$current_ip" ]; then
            log_success "代理启动成功 (出口IP: $current_ip)"
            return 0
        fi
        sleep 2
    done

    log_error "代理启动超时，请查看 $PROXY_LOG"
    exit 1
}

# --- 阶段 C: 准备浏览器 ---
ensure_browser_installed() {
    if [ -f "$MB_EXEC" ]; then
        log_success "浏览器已安装 (v$MB_VERSION)"
        return 0
    fi

    log_info "开始下载浏览器 (v$MB_VERSION)..."
    
    # 清理残余
    [ -d "$MB_DIR" ] && rm -rf "$MB_DIR"
    rm -f "browser.tar.xz"

    # 通过代理下载
    if curl -# -x "http://${PROXY_HOST}:${PROXY_PORT}" -f -L -o "browser.tar.xz" "$MB_URL"; then
        log_info "解压中..."
        tar -xf "browser.tar.xz"
        rm "browser.tar.xz"
        log_success "浏览器安装完成"
    else
        rm -f "browser.tar.xz"
        log_error "浏览器下载失败，请检查网络"
        exit 1
    fi
}

# --- 阶段 D: 注入配置 ---
configure_browser_proxy() {
    local pref_dir="${MB_DIR}/Browser/defaults/pref"
    local cfg_file="${MB_DIR}/Browser/mullvad.cfg"
    local autoconfig_file="${pref_dir}/autoconfig.js"

    # 清理冲突配置
    rm -f "${MB_DIR}/Browser/distribution/policies.json"
    find "${MB_DIR}/Browser" -name "user.js" -type f -delete

    log_info "应用代理配置 (非锁定模式)..."

    mkdir -p "$pref_dir"
    
    # 写入引导文件
    echo 'pref("general.config.filename", "mullvad.cfg");' > "$autoconfig_file"
    echo 'pref("general.config.obscure_value", 0);' >> "$autoconfig_file"
    echo 'pref("general.config.sandbox_enabled", false);' >> "$autoconfig_file"

    # 写入代理配置
    cat > "$cfg_file" <<EOF
// Auto-generated proxy config
try {
    pref("network.proxy.type", 1);
    pref("network.proxy.socks", "${PROXY_HOST}");
    pref("network.proxy.socks_port", ${PROXY_PORT});
    pref("network.proxy.socks_version", 5);
    pref("network.proxy.socks_remote_dns", true);
    pref("network.proxy.no_proxies_on", "localhost, 127.0.0.1");
    pref("network.proxy.share_proxy_settings", false);
} catch(e) { displayError("Config Error", e); }
EOF

    if [ -f "$cfg_file" ]; then
        log_success "配置注入完成"
    else
        log_error "配置写入失败"
        exit 1
    fi
}

# --- 阶段 E: 启动 ---
launch_browser() {
    log_info "启动 Mullvad Browser..."
    cd "$MB_DIR" || exit
    
    export ALL_PROXY="socks5://${PROXY_HOST}:${PROXY_PORT}"
    
    ./Browser/start-mullvad-browser --detach
    log_success "全部完成！"
}

# ================= 4. 主入口 =================

main() {
    check_dependencies
    ensure_proxy_binary
    start_proxy_service
    ensure_browser_installed
    configure_browser_proxy
    launch_browser
}

# 执行主函数
main
