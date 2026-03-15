---
created: 2026-02-24
modified: 2026-02-24
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

# 描述

> [!info]
> 应急响应工程师小王某人收到安全设备告警服务器被植入恶意文件，请上机排查
> 开放题目: 漏洞修复
> 
> 服务器场景操作系统 Windows
> 服务器账号密码 admin Aa123456
> 
> 参考 https://mp.weixin.qq.com/s/4UoIw-On-0taB8s0xtjkAw

# 步骤

## 1 步骤一 - 黑客 ID

> [!info]
> 找到黑客 ID 为多少,将黑客 ID 作为 FLAG 提交;

打开小皮面板部署的网站，可以看到已经被黑客修改了，从中得到黑客 ID

![[第九章-Where-1S-tHe-Hacker-260225-164419.png]]

```flag1
X123567X
```

## 2 步骤二 - 修改网站主页的时间

> [!info]
> 找到黑客在什么时间修改了网站主页,将黑客修改了网站主页的时间 作为 FLAG 提交（y-m-d-4:22:33）;

找到网站首页的源码文件，在文件属性中找到修改时间

![[第九章-Where-1S-tHe-Hacker-260225-164652.png]]

```flag2
2023-11-6-4:55:13
```

## 3 步骤三 - 第一个 webshell 文件名

> [!info]
> 找到黑客第一个 webshell 文件名是,将第一个 webshell 文件名 作为 FLAG 提交;

用 `D盾` 扫描一下 `C:\phpstudy_pro\www\` 目录，扫到三个后门，根据修改时间判断第一个 `webshell` 应该是 `SystemConfig.php`

![[第九章-Where-1S-tHe-Hacker-260225-165616.png]]

```flag3
SystemConfig.php
```

## 4 步骤四 - 第二个 webshell 文件名

> [!info]
> 找到黑客第二个 webshell 文件名是,将第二个 webshell 文件名 作为 FLAG 提交;

根据修改时间，第二个 `Webshell` 是 `syscon.php`

![[第九章-Where-1S-tHe-Hacker-260225-165643.png]]

```flag4
syscon.php
```

## 5 步骤五 - 第二个 webshell 连接密码

> [!info]
> 找到黑客第二个 webshell 的连接密码是, 将第二个 webshell 的连接密码作为 FLAG 提交;

打开第二个 `webshell` 文件，找到连接密码

![[第九章-Where-1S-tHe-Hacker-260225-165738.png]]

```flag5
pass
```

## 6 步骤六 - 新建隐藏账户名字

> [!info]
> 找到黑客新建的隐藏账户, 将新建的隐藏账户名字作为 FLAG 提交;

一种方法是用 `D-safe` 的克隆检测，检测到隐藏账号 `admin$`

![[第九章-Where-1S-tHe-Hacker-260225-170427.png]]

另一种方法是去 `\HKEY_LOCAL_MACHINE\SAM\SAM\Domains\Account\Users\Names\` 中找；

注意这里需要「右键 SAM」然后选择「权限」选项，给我们加上读取权限，否则「SAM」是空白。

![[第九章-Where-1S-tHe-Hacker-260225-170826.png]]

加上权限后，刷新一下

![[第九章-Where-1S-tHe-Hacker-260225-170902.png]]

然后就能在 `Names` 中看到明显的隐藏账户 `admin$`

![[第九章-Where-1S-tHe-Hacker-260225-170944.png]]

## 7 步骤七 - 创建隐藏账户时间

> [!info]
> 找到黑客隐藏账户创建时间是,将隐藏账户创建时间是 作为 FLAG 提交（答案格式：2024/12/3 9:16:23）;

看 `wp` 是用 `net user admin$` 输出 `admin$` 用户的信息，然后查看「上次设置密码」时间的；不过这种方法从语义上讲并不准确。

![[第九章-Where-1S-tHe-Hacker-260225-190903.png]]

因此我们在事件查看器中找到「创建用户账户」的事件。

「win+r」输入 `eventvwr` 打开事件查看器，如下面「事件 ID 表」所示，找到 `4720` `id`；

> [!tip] #知识/Windows/Windows_Event_Log/ID/事件ID表
> https://learn.microsoft.com/zh-cn/windows-server/identity/ad-ds/plan/appendix-l--events-to-monitor

![[第九章-Where-1S-tHe-Hacker-260225-204331.png]]

![[第九章-Where-1S-tHe-Hacker-260225-204901.png]]

```flag7
2023/11/6 4:45:34
```

## 8 步骤八 - 添加隐藏账户进管理员组的时间

> [!info]
> 找到黑客添加隐藏账户进管理员组的时间,将添加隐藏账户进管理员组的时间 作为 FLAG 提交（答案格式：2024/12/3 9:16:23）;

#知识/Windows/Windows_Event_Log/4732
这里我们找一下 `4732` 事件 `ID`，即「向已启用安全性的本地组中添加了成员」；这里的「已启用安全性」是指用于分配权限的组，相应的，「未启用安全性」的组就是仅用于通信的组；而本地组指的是像 `Administrators` 这种每台计算机都存在同名的组，仅在创建它的那台计算机上有效；而全局组则是域中共享的组，在域中的多台计算机间都有效。
#知识/Windows/用户组/启用安全性 #知识/Windows/用户组/本地组全局组

![[第九章-Where-1S-tHe-Hacker-260225-232900.png]]

![[第九章-Where-1S-tHe-Hacker-260225-233007.png]]

```flag8
2023/11/6 4:46:07
```

## 9 步骤九 - 读取文件中保留的密钥的时间

> [!info]
> 找到黑客在什么时间从文件中读取保留的密钥,将读取保留的密钥的时间 作为 FLAG 提交（答案格式：2024/12/3 9:16:23）;

#知识/Windows/Windows_Event_Log/ID/5058 事件 `5058` 是对包含加密密钥的文件执行操作时 (如读取、写入、删除等) 产生的。

![[第九章-Where-1S-tHe-Hacker-260227-165305.png]]

我们筛选一下之前隐藏账户创建时间附近的 `5058` 事件

![[第九章-Where-1S-tHe-Hacker-260227-152212.png]]

然后找到了这个以系统权限读取文件中保留密钥的日志

![[第九章-Where-1S-tHe-Hacker-260227-154044.png]]

```flag9
2023/11/6 4:46:58
```

## 10 步骤十 - 通过哈希传递攻击登录的时间

> [!info]
> 找到黑客通过隐藏账户通过 (PTH) 哈希传递攻击登录的时间是,将 (PTH) 哈希传递攻击登录的时间 作为 FLAG 提交;

> [!quote] [引用自](https://waynejoons.icu/posts/Xuanji-CTF-Where-1S-tHe-Hacker/#%E6%AD%A5%E9%AA%A4-10)
> 哈希传递攻击指的是攻击者无需知道用户的明文密码，只需窃取密码的哈希值（Hash），就能冒充该用户登录到网络中的其他系统。
> 
> 这里我们聚焦于 NtLmSsp（NT LAN Manager Security Support Provider），它用于处理 NTLM 协议的身份验证，我们去筛选登录事件，找到登录进程为 NtLmSsp 的即可，对应的事件 ID 为 4624

wp 截图给的是在 `eventvwr.msc` 中找到的，但由于 `4624` 登录事件很多，其实很难筛选到目标的；所以这里我们先把简单筛选出的 `4624` 日志导出为文件，然后再用 `FullEventLogView` 打开，然后进一步筛选 `NtLmSsp` 关键词，然后就能看到第一个日志就是了。

![[第九章-Where-1S-tHe-Hacker-260227-160902.png]]

```flag10
2023/11/6 4:47:28
```

## 11 步骤十一 - 上传的两个 CobaltStrike 木马文件名

> [!info]
> 找到黑客上传的两个 CobaltStrike 木马文件名,将上传的两个 CobaltStrike 木马文件名 作为 FLAG 提交（答案格式："A.exe,B.exe"）;

由于 `windows defender` 会自动检测到木马并隔离了，所以这里我们先要把木马恢复过来 (其实这里已经得到答案了)。

![[第九章-Where-1S-tHe-Hacker-260227-163000.png]]

![[第九章-Where-1S-tHe-Hacker-260227-163013.png]]

用 `D-Eyes` 扫描 `d-eyes.exe detect fs -p C:\`；结果如下，除了之前找到的三个 `webshell` 之外，剩下的两个就是木马文件了，分别是 `SystemTemp.exe,SysnomT.exe`；而且它的 `Rist Description` 也表明了是 `CobaltStrike`

![[第九章-Where-1S-tHe-Hacker-260227-170644.png]]

放沙箱里检测一下，也检测出是 `cs`

![[第九章-Where-1S-tHe-Hacker-260227-171837.png]]

![[第九章-Where-1S-tHe-Hacker-260227-171932.png]]

```flag11
SystemTemp.exe,SysnomT.exe
```
