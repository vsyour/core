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
