# usque 组网
## 下载
```
https://github.com/Diniboy1123/usque/releases
https://github.com/Diniboy1123/usque/releases/download/v2.0.1/usque_2.0.1_linux_amd64.zip
https://github.com/Diniboy1123/usque/releases/download/v2.0.1/usque_2.0.1_windows_amd64.zip
```

## socks5/http本地代理
```
https://www.youtube.com/watch?v=O-txc33VVnU
解决方案1：跟上-6参数
解决方案2：修改config.json中的endpoint_v4为endpoint_v6的值
```

## 接入ZeroTrust平台
```
https://www.youtube.com/watch?v=H8iS2NZD6LA

https://dash.cloudflare.com/one/
找到 "团队域" 下面的名字
--> https://"团队域"/warp

Visit https://<team-domain>/warp and complete the authentication process.
Obtain the team token from the success page's source code, or execute the following command in the browser console:
控制台输入: console.log(document.querySelector("meta[http-equiv='refresh']").content.split("=")[2])
./usque register --jwt <jwt>
```
