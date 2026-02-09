---
created: 2026-02-06
modified: 2026-02-06
tags:
  - CTF/Misc/流量分析/CobaltStrike
---

```table-of-contents
title: 
style: nestedList # TOC style (nestedList|nestedOrderedList|inlineFirstLevel)
minLevel: 0 # Include headings from the specified level
maxLevel: 0 # Include headings up to the specified level
include: 
exclude: 
includeLinks: true # Make headings clickable
hideWhenEmpty: false # Hide TOC if no headings are found
debugInConsole: false # Print debug info in Obsidian console
```

## 1 概述

> [!cite] [Software for Adversary Simulations and Red Team Operations](https://www.cobaltstrike.com/)
> Adversary Simulations and Red Team Operations are security assessments that replicate the tactics and techniques of an advanced adversary in a network. While penetration tests focus on unpatched vulnerabilities and misconfigurations, these assessments benefit security operations and incident response.

CobaltStrike 是一款商业化 (但实际上用破解版的居多) 渗透测试工具，是专为 Red Team Operations 设计的对抗模拟平台，用于模拟高级持续性威胁（APT）攻击。

它更偏向于后渗透阶段使用，而前期的漏洞扫描和利用漏洞“打进去”的过程一般不是靠的 CobaltStrike。

它提供了团队协作 (多个客户端连接到 `TeamServer`)、持久化控制、流量隐蔽、横移以及一系列后渗透工具集 (屏幕截图、键盘记录、录音、文件浏览、Mimikatz 抓取密码、提权等)。

## 2 架构

CobaltStrike 需要关注 `Stager`(阶段加载器)、`Beacon`(植入体)、`TeamServer`(C2 服务器) 和 `Client`(攻击者使用的客户端) 这四个东西，其中后三个组成了 `CobaltStrike` 的整体架构，而第一个 `Stager` 则主要负责从 `TeamServer` 拉取并反射加载 `Beacon`，不算做架构的一部分 (甚至在 `Stagerless` 模式下都不需要它，而是由 `Beacon` 自己加载自己)。

随便花了个简图如下 (更详细的图想象不出来)

![[CobaltStrike流量分析总结-260208-132053.png]]

## 3 通信流程

CobaltStrike 支持 `TCP`、`HTTP`、`HTTPS`、`DNS`、`SMB` 等多种 `C2` 通信方式，这里只讨论 `HTTP` 的通信方式。

这里以带 `Stager` 阶段加载器的模式为例：
1. 攻击者通过漏洞利用等方式把 `Stager` 运行在目标上，`Stager` 首先会发送一个 `GET` 请求去拉取 `Beacon` 本体；这个请求的路径经 `checksum8` 计算后的结果为 `92`(32 位) 或 `93`(64 位)，比如 `/FJwV`；
2. `Beacon` 被 `Stager` 反射加载后，第一次会向 `TeamServer` 发送一个心跳包，包含了主机名、用户名、载体进程名、操作系统版本、cpu 架构、`raw_key` 密钥等元信息，并用 `Beacon` 中嵌入的 `rsa` 公钥加密；元信息一般放在 `Cookie` 头部中，为 `base64` 编码形式，`GET` 请求，路径可能长这样：`/en_US/all.js`；
3. `TeamServer` 在收到第一次心跳，用 `rsa` 私钥解密元数据，并且 `TeamServer` 和 `Beacon` 双方都用 `raw_key` 派生出 `aes_key`(用于对称加密) 和 `hmac_key`(用于签名防篡改)；之后 `Beacon` 会进入睡眠 (一般是 `60s`)；
4. 睡眠完成后，`Beacon` 会再发送新的心跳包请求任务；如果 `TeamServer` 有任务分配 (`client` 执行的命令、`TeamServer` 自己的自动任务等)，就会响应 `aes` 加密的任务；如果没有，就返回一个空包；
5. `Beacon` 收到响应的任务后，执行它会把结果以 `POST` 请求的方式 `aes` 加密传输回去，从 `TeamServer` 看，结果的响应是异步的；该类用于返回结果的 `POST` 请求的路径一般是 `/submit.php?id=xxxx`；
6. `TeamServer` 收到命令结果后用 `aes` 解密，回显明文、记录日志；然后等待下一个心跳包。

下面是很多文章都有放的图，但不是特别漂亮，不过我也没多少空重画一张，还是放上去了。(下图复制自 [这里](https://lexsd6.github.io/2025/04/27/CobaltStrike%E6%B5%81%E9%87%8F%E5%88%86%E6%9E%90-%E7%8E%84%E6%9C%BA%E9%9D%B6%E5%9C%BA/))

![[CobaltStrike流量分析总结-260208-141426.png]]

## 4 HTTP 流量特征

### 4.1 `checksum8` 算法特征

CobaltStrike 的 `Stager` 拉取 `Beacon` 本体的请求的路径符合 `checksum8` 算法计算后结果为 `92`(32 位) 或 `93`(64 位) 的特征，比如 `/FJwV`；

所谓 `checksum8` 算法，就是把所有字符的 `ascii` 码求和再模 `256`。

这里直接复制看的 [文章](https://xz.aliyun.com/news/18517) 给的计算过程了

```
70 (F) + 74 (J) + 119 (w) + 86 (V) = 349
349 % 256 = 93
```

### 4.2 特定 `url` 路径

> [!quote] https://xz.aliyun.com/news/18517
> 未修改的 CobaltStrike 常出现特定 URL 路径如 
> + `/submit.php?id=xxx`
> + `/en_US/all.js`
> + `/pixel.gif`
> + `/q.cgi`
> + 还有前面的 `checksum8` 特征

## 5 解密流量包

### 5.1 `Beacon` 配置提取

从 `Stager` 向 `TeamServer` 拉取的 `Beacon` 本体中，我们能提取出 `payload type`、`rsa public key`、`get_uri`(`/en_US/all.js`)、`post_uri`(`/submit.php`)、`useragent`、`server`、`port`、`spawnto_x64`(`%windir%\\sysnative\\rundll32.exe`) 等一系列信息。

提取方法是先从流量包中找到 `Stager` 向 `TeamServer` 请求的响应，保存响应体到文件，然后用下面这个脚本解析：

> [!cite] 
> https://github.com/DidierStevens/DidierStevensSuite/blob/master/1768.py

使用方法：

```bash
python .\1768.py .\FJwV
```

实例：[[CobaltStrike流量分析#3 步骤三 - payload 名字]]

### 5.2 `Beacon` 发送的元信息解密 (获取 raw_key)

#### 5.2.1 获取 `rsa` 私钥

##### 方法一：从 `.cobaltstrike.beacon_keys` 提取私钥

如果能溯源反制部署有 `TeamServer` 的服务器，或者通过其他方法，总之能弄到 `Cobalt_Strike` 程序目录下的 `.cobaltstrike.beacon_keys`，我们就能想办法从里面读取出 `rsa` 私钥；

这个文件本质上是 `java` 的序列化数据，我们可以在 `python` 中用 `javaobj` 库读取，脚本如下：

> [!cite]
> https://github.com/Slzdude/cs-scripts/blob/master/parse_beacon_keys.py

实例：[[CobaltStrike流量分析#4.2.2 方法一：从 `.cobaltstrike.beacon_keys` 提取私钥]]

##### 方法二：rsa 分解 n 计算私钥

如果没法读到 `.cobaltstrike.beacon_keys` 文件，我们还可以利用从 `beacon` 本体解析出的 `rsa` 公钥，提取出 `e` 和 `n`；然后用 `yafu` 等手段因数分解 `n` 得到 `p` 和 `q`，进而用 `q p n e` 解出 `e`，从而得到私钥 `(e, n)`。

实例：[[CobaltStrike流量分析#方法二：rsa 分解 n 计算私钥]]

#### 5.2.2 用私钥解密元数据获取 raw_key

`Beacon` 向 `TeamServer` 发送的第一个心跳包的用 `rsa` 公钥加密的元数据 (通常在 `Cookie` 头部中以 `base64` 编码) 中包含 `raw_key`，我们可以用获取到的私钥结合下面的脚本去解密元数据，得到它。

> [!cite]
> https://github.com/DidierStevens/DidierStevensSuite/blob/master/cs-decrypt-metadata.py

用法：

```bash
python cs-decrypt-metadata.py -p <十六进制私钥> <base64编码后的 rsa 加密元数据>
```

实例：[[CobaltStrike流量分析#4.2.2 用私钥解密加密元数据得到 `raw_key`]]

#### 5.2.3 解密流量包

根据 [这篇文章](https://www.cnblogs.com/blue-red/p/19022396) 的标题 5 所说，后续 `Beacon` 的 `GET` 请求的 `Cookie` 中的数据还是用的 `rsa` 公钥加密 (并且每份数据中都有 `raw_key`，题外话，因为前面我们已经获得了)，然后默认只有 `POST` 请求 (异步发送结果的请求) 和来自 `TeamServer` 的响应包 (分配任务的包) 会用 `aes` 密钥对称加密；

解密流量的话，我们主要就是解密后者用 `aes` 对称加密的数据 (因为 `GET` 请求一般是心跳包)。

之前得到 `raw_key`(同时也相当于得到了 `aes_key` 和 `hmac_key`) 后，我们就可以用脚本解密我们前面界定的流量包了：

![[CobaltStrike流量分析#4.2.3 解密流量包]]

## 6 TeamServer 的日志结构 (以某 4.5 版本为例)

### 6.1 目录结构与各文件作用

`TeamServer` 的日志一般在 `Cobalt_Strike` 目录下的 `logs` 文件夹中 (`logs` 一般和 `cobaltstrike.jar` 在同一个文件夹)；

`logs/` 下是 `YYMMDD` 形式的一个个目录，一个日期的日志保存在一个 `logs/YYMMDD/` 文件夹中；图示如下：

```
Cobalt_Strike_4.5/
├── teamserver
├── cobaltstrike.jar
├── ......
├── ......
└── logs/
    ├── YYMMDD/                  <-- 日期文件夹
    │   ├── events.log           <-- 全局事件日志
    │   ├── weblog.log           <-- Web 访问日志
    │   ├── downloads.log        <-- 文件下载记录
    │   ├── <x.x.x.x>/           <-- 被攻击目标内网 IP 文件夹
    │   │   ├── beacon_<id>.log  <-- 与特定 Beacon ID 的交互日志
    │   │   ├── keystrokes/      <-- 键盘记录
    │   │   ├── screenshots.log  <-- 截屏记录
    │   │   ├── screenshots/     <-- 截屏内容
    │   ├── <y.y.y.y>/           <-- 另一个目标 IP
    │   └── unknown/             <-- 未知 IP
    └── YYMMDD/                  <-- 另一天日志
```

---

在每个 `logs/YYMMDD/` 下，
1. `events.log` 是全局事件记录，包括操作员登录登出记录、`Beacon` 上线记录、监听器添加移除记录等
2. `weblog_<port>.log` 记录了 `cs` 在端口 `<port>` 开的 `web` 服务的日志，比如 `Stager` 下载 `Beacon` 的 `GET` 请求记录就会被记录在 `weblog_<port>.log` 中
3. `downloads.log` 是从被攻击目标下载文件的记录
4. `<被攻击机的内网ip>/` 目录则是特定与被攻击目标的日志

---

在每个 `logs/YYMMDD/<内网ip>/` 下，
1. `beacon_<id>.log` 是与 `Beacon` 的交互日志，包括 `Beacon` 传回的被攻击目标的元数据记录、操作员执行命令的记录、命令的回显记录等，格式为 `[日期/月份] [时间] [时区] [标记] [附加信息] 内容`，例如 `02/12 11:51:15 UTC [input] <xiaole> shell whoami` 就是操作员 `xiaole` 执行了 `shell whoami` 命令。
2. `keystrokes/` 文件夹 (有些版本可能是 `keystrokes.txt/keystrokes.log` 文件) 中记录了被攻击目标的键盘输入记录
3. `screenshots.log` 中记录了截屏记录
4. `screenshots/` 中是截到的具体图片

### 6.2 查看各文件详细内容

#### 6.2.1 `event.log`

##### 作用

记录：
1. 操作员的登录登出日志
2. 被攻击目标 (`Beacon`) 的上线、下线、提权日志
3. 其他一些公告性质的日志

##### 格式

没找到或归纳出比较靠谱的格式规范，这里直接贴具体的内容长啥样了

```
02/12 09:09:26 UTC *** xiaole (192.168.31.59) joined
02/12 09:10:30 UTC *** xiaole quit
02/12 09:11:04 UTC *** xiaole (192.168.31.59) joined
02/12 09:11:18 UTC *** xiaole quit
02/12 11:30:25 UTC *** xiaole (192.168.31.59) joined
02/12 11:32:03 UTC *** initial beacon from Administrator *@192.168.113.149 (WIN-8FC6TKPDPOR)
02/12 11:38:16 UTC *** initial beacon from Administrator *@192.168.113.149 (WIN-8FC6TKPDPOR)
02/12 11:50:57 UTC *** initial beacon from Administrator *@192.168.113.149 (WIN-8FC6TKPDPOR)
02/12 11:54:05 UTC *** initial beacon from SYSTEM *@192.168.113.149 (WIN-8FC6TKPDPOR)
02/12 12:12:52 UTC *** initial beacon from Administrator *@192.168.113.149 (WIN-8FC6TKPDPOR)
02/12 13:45:48 UTC *** xiaole quit
02/12 13:46:15 UTC *** xiaole quit
02/12 13:46:17 UTC *** xiaole (192.168.31.59) joined
```

#### 6.2.2 `weblog_<port>.log`

##### 1.2.3 作用

`cs` 在端口 `<port>` 开的 `web` 服务的日志

##### 内容

```
192.168.31.76 unknown unknown [02/12 02:48:35 UTC] "GET /f6oR/" 200 265799 "beacon beacon stager x64" "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0; MASP)"
192.168.31.76 unknown unknown [02/12 02:49:29 UTC] "GET /f6oR/" 200 265799 "beacon beacon stager x64" "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0; MASP)"
192.168.31.76 unknown unknown [02/12 02:49:54 UTC] "GET /f6oR/" 200 265799 "beacon beacon stager x64" "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0; MASP)"
192.168.31.76 unknown unknown [02/12 02:52:09 UTC] "GET /f6oR/" 200 265799 "beacon beacon stager x64" "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0; MASP)"
192.168.31.92 unknown unknown [02/12 11:32:03 UTC] "GET /FJwV/" 200 265799 "beacon beacon stager x64" "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0; MANM)"
192.168.31.92 unknown unknown [02/12 11:38:16 UTC] "GET /FJwV/" 200 265799 "beacon beacon stager x64" "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0; MANM)"
192.168.31.92 unknown unknown [02/12 11:50:57 UTC] "GET /FJwV/" 200 265799 "beacon beacon stager x64" "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0; MANM)"
192.168.31.92 unknown unknown [02/12 11:54:05 UTC] "GET /FJwV/" 200 265799 "beacon beacon stager x64" "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0; MANM)"
192.168.31.92 unknown unknown [02/12 12:12:52 UTC] "GET /FJwV/" 200 265799 "beacon beacon stager x64" "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0; MANM)"
```

#### 6.2.3 `downloads.log`

##### 作用

从被攻击目标下载文件的记录

##### 1.2.4 内容

```
02/10 11:35:25 UTC	192.168.31.254	1186257552	38	/Users/xiaole/Desktop/win11data/tools/Cobalt_Strike_4.5/Cobalt_Strike_4.5/downloads/18d00cf59	flag.txt	C:\Users\Administrator\Desktop\
```

```
02/12 12:15:46 UTC	192.168.113.149	1603726794	9293	/opt/Cobalt_Strike_4.5/Cobalt_Strike_4.5/downloads/16b48285a	xxx服务器运维信息.xlsx	C:\Users\Administrator\Desktop\
```

#### 6.2.4 `beacon_<id>.log`

##### 作用

记录：
1. `Beacon` 第一次上线时向 `TeamServer` 发送的被攻击目标的元数据 (主机名、用户名、载体进程名、操作系统版本、cpu 架构、`aes` 密钥等)
2. 操作员输入的命令
3. `TeamServer` 向 `Beacon` 分发的任务 (自动分发的任务或将操作员命令打包后的任务)
4. 执行的命令的结果
5. 错误信息
6. 等等

##### 格式

```
[日期/月份] [时间] [时区] [标记] [附加信息] 内容
02/10 11:12:41 UTC [input] <xiaole> sleep 1
```

其中，标记分为：
1. `[metadata]` 元数据
2. `[input]` 操作员输入的命令
3. `[task]` `TeamServer` 向 `Beacon` 分发任务
4. `[checkin]` 记录 Beacon 回传心跳的时间以及数据包大小。
5. `[output]` 命令执行结果，通常紧跟在 `[checkin]` 之后。
6. `[error]` 错误信息

##### 内容

```
02/10 11:12:36 UTC [metadata] 192.168.31.92 <- 192.168.31.92; computer: DESKTOP-VP6QROM; user: xiaole; process: artifact.exe; pid: 4832; os: Windows; version: 6.2; build: 9200; beacon arch: x64 (x64)
02/10 11:12:33 UTC [task] <T1029> Tasked beacon to become interactive
02/10 11:12:41 UTC [input] <xiaole> sleep 1
02/10 11:12:41 UTC [task] <T1029> Tasked beacon to sleep for 1s
02/10 11:13:33 UTC [checkin] host called home, sent: 32 bytes
02/10 11:13:39 UTC [input] <xiaole> shell whoami
02/10 11:13:39 UTC [task] <T1059> Tasked beacon to run: whoami
02/10 11:13:40 UTC [checkin] host called home, sent: 37 bytes
02/10 11:13:40 UTC [output]
received output:
desktop-vp6qrom\xiaole


02/10 11:13:52 UTC [task] <T1003, T1055, T1093> Tasked beacon to run mimikatz's sekurlsa::logonpasswords command
02/10 11:13:53 UTC [checkin] host called home, sent: 788090 bytes
02/10 11:13:54 UTC [output]
received output:
ERROR kuhl_m_sekurlsa_acquireLSA ; Handle on memory (0x00000005)


02/10 11:14:27 UTC [task] <> cd C:\Users\Public\
02/10 11:14:27 UTC [task] <T1059> Tasked beacon to run: LsassDump.exe
02/10 11:14:27 UTC [task] <T1059> Tasked beacon to run: taskkill -f /im LsassDump.exe & del /f /s /q LsassDump.exe
02/10 11:14:27 UTC [checkin] host called home, sent: 144 bytes
02/10 11:14:27 UTC [error] could not spawn LsassDump.exe: 2
02/10 11:14:27 UTC [output]
received output:
错误: 没有找到进程 "LsassDump.exe"。
找不到 C:\Users\Public\LsassDump.exe


02/10 11:15:12 UTC [output]
9=========== Krbtgt hash ==========

02/10 11:15:29 UTC [output]
9=========== Mimikatz Kerberos Credentials ==========

02/10 11:15:30 UTC [task] <T1003, T1055, T1093> Tasked beacon to run mimikatz's sekurlsa::kerberos command
02/10 11:15:30 UTC [checkin] host called home, sent: 788084 bytes
02/10 11:15:31 UTC [output]
received output:
ERROR kuhl_m_sekurlsa_acquireLSA ; Handle on memory (0x00000005)


02/10 11:16:45 UTC [task] <T1003, T1055, T1093> Tasked beacon to run mimikatz's sekurlsa::wdigest command
02/10 11:16:46 UTC [checkin] host called home, sent: 788083 bytes
02/10 11:16:47 UTC [output]
received output:
ERROR kuhl_m_sekurlsa_acquireLSA ; Handle on memory (0x00000005)


02/10 11:16:53 UTC [task] <T1003, T1055, T1093> Tasked beacon to run mimikatz's sekurlsa::msv command
02/10 11:16:54 UTC [checkin] host called home, sent: 788079 bytes
02/10 11:16:55 UTC [output]
received output:
ERROR kuhl_m_sekurlsa_acquireLSA ; Handle on memory (0x00000005)


02/10 11:17:34 UTC [checkin] host called home, sent: 12 bytes
02/10 11:18:03 UTC [task] <T1003, T1055, T1093> Tasked beacon to run mimikatz's sekurlsa::credman command
02/10 11:18:04 UTC [checkin] host called home, sent: 788083 bytes
02/10 11:18:05 UTC [output]
received output:
ERROR kuhl_m_sekurlsa_acquireLSA ; Handle on memory (0x00000005)


02/10 11:18:22 UTC [task] <T1003, T1055, T1093> Tasked beacon to run mimikatz's sekurlsa::dpapi command
02/10 11:18:23 UTC [checkin] host called home, sent: 788081 bytes
02/10 11:18:24 UTC [output]
received output:
ERROR kuhl_m_sekurlsa_acquireLSA ; Handle on memory (0x00000005)


02/10 11:19:17 UTC [output]
9=========== SweetPotato（MS16-075） ==========

02/10 11:19:23 UTC [task] <> Task Beacon to run windows/beacon_http/reverse_http (192.168.31.59:80) SweetPotato (ms16-075)
02/10 11:19:24 UTC [checkin] host called home, sent: 892553 bytes
02/10 11:19:25 UTC [output]
received output:
[+] SweetPotato by @_EthicalChaos_,fixed by 2020/4/16

[=] Your version of Windows fixes DCOM interception forcing BITS to perform WinRM intercept


02/10 11:19:43 UTC [input] <xiaole> shell tasklist /scv
02/10 11:19:43 UTC [task] <T1059> Tasked beacon to run: tasklist /scv
02/10 11:19:43 UTC [checkin] host called home, sent: 44 bytes
02/10 11:19:44 UTC [output]
received output:
错误: 无效参数/选项 - '/scv'。
键入 "TASKLIST /?" 以了解用法。


02/10 11:19:46 UTC [input] <xiaole> shell tasklist /svc
02/10 11:19:46 UTC [task] <T1059> Tasked beacon to run: tasklist /svc
02/10 11:19:47 UTC [checkin] host called home, sent: 44 bytes
02/10 11:19:47 UTC [output]
received output:

映像名称                       PID 服务                                        
========================= ======== ============================================
System Idle Process              0 暂缺
System                           4 暂缺
Registry                       172 暂缺
lsass.exe                      764 EFS, KeyIso, SamSs, VaultSvc   
...... 此处省略 ......
svchost.exe                   1668 TermService 
svchost.exe                   1676 lmhosts
svchost.exe                   1772 EventLog
...... 此处省略 .....


02/10 11:19:59 UTC [input] <xiaole> shell systeminfo
02/10 11:19:59 UTC [task] <T1059> Tasked beacon to run: systeminfo
02/10 11:19:59 UTC [checkin] host called home, sent: 41 bytes
02/10 11:20:02 UTC [output]
received output:

主机名:           DESKTOP-VP6QROM
OS 名称:          Microsoft Windows 10 专业版
OS 版本:          10.0.19045 暂缺 Build 19045
OS 制造商:        Microsoft Corporation
OS 配置:          独立工作站
OS 构建类型:      Multiprocessor Free
注册的所有人:     xiaole
注册的组织:       暂缺
产品 ID:          00331-10000-00001-AA725
初始安装日期:     2024/5/26, 17:16:06
系统启动时间:     2025/2/10, 0:08:41
系统制造商:       HP
系统型号:         HP Pavilion Gaming Laptop 15-dk1xxx
系统类型:         x64-based PC
处理器:           安装了 1 个处理器。
                  [01]: Intel64 Family 6 Model 165 Stepping 2 GenuineIntel ~2208 Mhz
BIOS 版本:        Insyde F.46, 2023/10/4
Windows 目录:     C:\Windows
系统目录:         C:\Windows\system32
启动设备:         \Device\HarddiskVolume3
系统区域设置:     zh-cn;中文(中国)
输入法区域设置:   zh-cn;中文(中国)
时区:             (UTC+08:00) 北京，重庆，香港特别行政区，乌鲁木齐
物理内存总量:     32,543 MB
可用的物理内存:   27,046 MB
虚拟内存: 最大值: 37,407 MB
虚拟内存: 可用:   31,773 MB
虚拟内存: 使用中: 5,634 MB
页面文件位置:     C:\pagefile.sys
域:               WORKGROUP
登录服务器:       \\DESKTOP-VP6QROM
修补程序:         安装了 23 个修补程序。
                  [01]: KB5049621
                  [02]: KB5034468
                  [03]: KB4562830
                  ......
网卡:             安装了 6 个 NIC。
                  [01]: Intel(R) Wi-Fi 6 AX201 160MHz
                      连接名:      WLAN
                      启用 DHCP:   是
                      DHCP 服务器: 192.168.31.1
                      IP 地址
                        [01]: 192.168.31.92
                        [02]: fe80::25e5:442e:e3bb:50b8
                  [02]: Realtek Gaming GbE Family Controller
                      连接名:      以太网
                      状态:        媒体连接已中断
                  [03]: VMware Virtual Ethernet Adapter for VMnet1
                      连接名:      VMware Network Adapter VMnet1
                      启用 DHCP:   是
                      DHCP 服务器: 192.168.203.254
                      IP 地址
                        [01]: 192.168.203.1
                        [02]: fe80::762a:2e0:71d7:2ec1
                  [04]: VMware Virtual Ethernet Adapter for VMnet8
                      连接名:      VMware Network Adapter VMnet8
                      启用 DHCP:   是
                      DHCP 服务器: 192.168.113.254
                      IP 地址
                        [01]: 192.168.113.1
                        [02]: fe80::da95:b7e7:9d23:e925
                  [05]: VMware Virtual Ethernet Adapter for VMnet18
                      连接名:      VMware Network Adapter VMnet18
                      启用 DHCP:   否
                      IP 地址
                        [01]: 10.0.20.1
                        [02]: fe80::1b67:4e71:4e25:ca40
                  [06]: VMware Virtual Ethernet Adapter for VMnet19
                      连接名:      VMware Network Adapter VMnet19
                      启用 DHCP:   否
                      IP 地址
                        [01]: 10.0.10.1
                        [02]: fe80::38e4:1ae7:b69c:a85a
Hyper-V 要求:     虚拟机监视器模式扩展: 是
                  固件中已启用虚拟化: 是
                  二级地址转换: 是
                  数据执行保护可用: 是


02/10 11:20:54 UTC [output]
9=========== CVE-2020-0796（KB4551762） ==========

02/10 11:20:58 UTC [error] This exploit only supports Windows 10 versions 1903 - 1909
02/10 11:22:33 UTC [input] <xiaole> hashdump
02/10 11:22:33 UTC [error] hashdump error: this command requires administrator privileges
02/10 11:22:48 UTC [input] <xiaole> shell whoami
02/10 11:22:48 UTC [task] <T1059> Tasked beacon to run: whoami
02/10 11:22:49 UTC [checkin] host called home, sent: 37 bytes
02/10 11:22:49 UTC [output]
received output:
desktop-vp6qrom\xiaole


02/10 11:23:24 UTC [input] <xiaole> exit
```

#### 6.2.5 `keystrokes/`

##### 作用

记录被攻击目标的键盘输入记录

##### 内容

![[CobaltStrike流量分析总结-260207-160928.png]]

```
02/11 09:41:37 UTC Received keystrokes from Administrator in desktop 1



QQ
=======
123
02/11 09:41:47 UTC Received keystrokes from Administrator in desktop 1

45678

QQEdit
=======
ojN@jjz
02/11 09:41:56 UTC Received keystrokes from Administrator in desktop 1

lxxyrsjwphdvht[control][ctrl]frdp
02/11 09:42:07 UTC Received keystrokes from Administrator in desktop 1

bnzlxjvhtf
02/11 09:42:17 UTC Received keystrokes from Administrator in desktop 1

rdpbnzlxjv
02/11 09:42:27 UTC Received keystrokes from Administrator in desktop 1

htfrdp6666
02/11 09:42:37 UTC Received keystrokes from Administrator in desktop 1

6666666622
02/11 09:42:47 UTC Received keystrokes from Administrator in desktop 1

2222222222
02/11 09:42:57 UTC Received keystrokes from Administrator in desktop 1

2222222222
02/11 09:43:07 UTC Received keystrokes from Administrator in desktop 1

2222222222
02/11 09:43:17 UTC Received keystrokes from Administrator in desktop 1

2222222

"
=======
noet

02/11 09:43:27 UTC Received keystrokes from Administrator in desktop 1




�� - ��,
=======
[control][ctrl]
02/11 09:47:26 UTC Received keystrokes from Administrator in desktop 1



�~u - Google Chrome
=======
xj[caps lock][caps lock][backspace][backspace][backspace][backspace][backspace][backspace]
02/11 09:47:36 UTC Received keystrokes from Administrator in desktop 1

[caps lock][caps lock]xj.edisec.net


xj.edisec.net - Google Chrome
=======
[control][ctrl]

xj.edisec.net/signin?redirect=%2F - Google Chrome
=======
[pause]
02/11 09:47:56 UTC Received keystrokes from Administrator in desktop 1



Program Manager
=======
[control][ctrl]
```

#### 6.2.6 `screenshots.log` 和 `screenshots/`

##### 作用

截屏记录和截到的图片

##### 内容

![[CobaltStrike流量分析总结-260207-161426.png]]

```
02/12 12:17:35 UTC	WIN-8FC6TKPDPOR	1	Administrator	screen_cd5a0ca5_1603726794.jpg	新标签页 - Google Chrome
```

## 7 参考资料

> [!cite]
> + https://lexsd6.github.io/2025/04/27/CobaltStrike%E6%B5%81%E9%87%8F%E5%88%86%E6%9E%90-%E7%8E%84%E6%9C%BA%E9%9D%B6%E5%9C%BA/
> + https://www.cnblogs.com/blue-red/p/19022396
> + https://nnnpc.github.io/2024/04/16/CS%E6%B5%81%E9%87%8F%E6%B5%85%E6%9E%90/
> + https://blog.csdn.net/m0_73812072/article/details/157097982
> + https://xz.aliyun.com/news/18517
> + https://www.freebuf.com/articles/463226.html
> + https://mp.weixin.qq.com/s/3oBLKoNncmQt6kxfVkijlA
> + https://xj.edisec.net/challenges/114
> + `gemini`、`grok`、`claude-opus`
