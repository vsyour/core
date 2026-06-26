```

#!/bin/bash

# 你的 GitHub Raw 开关地址
CONTROL_URL="https://gist.githubusercontent.com/你的用户名/xxxx/raw/sync_switch.txt"

while true; do
    # 去 GitHub 拉取这个值。设置 10 秒超时防卡死，并删掉多余的空格或换行符
    SYNC_FLAG=$(curl -s --max-time 10 "$CONTROL_URL" | tr -d '[:space:]')

    # 判断：如果取到的值严格等于 0，则执行同步
    if [ "$SYNC_FLAG" = "0" ]; then
        rsync -rvzc -e "ssh -p 10022" /root/next-terminal/pro_pg/data/recordings/ syncuser@101.47.10.15:/home/debian/bak/next-terminal/pro_pg/data/recordings/ > /dev/null 2>&1
    fi

    # 无论是否同步，都休息 2 小时 (7200 秒)
    sleep 7200
done

```
