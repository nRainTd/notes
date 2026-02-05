---
created: 2026-01-30
modified: 2026-01-30
tags:
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
> 前言：自 2017 年 WannaCry 勒索病毒爆发后，现如今勒索病毒层出不穷，黑客组织攻击手法和加密器开发手法也越来越变幻无常，勒索家族组织也越来越多，对于这种成本低、回报高的情况，越来越多人走向极端，当我们在实战中遇到勒索事件后应该怎么做？
常规排查方法三步走：
> 1. 排查 (确定勒索家族：包含勒索信，加密样本加密后缀、加密器等)，确定勒索家族后可定位此家族的一些特征以及后期数据恢复
> 2. 恢复 (寻找相关勒索家族加密器的解密器，尝试破解恢复，有些家族使用的是旧版本的加密器，这些加密器可能存在一些漏洞或使用了对称加密手法，可以寻找是否存在解密器进行数据恢复或手动进行逆向)，如没有找到加密器或很难搜到相关加密器的一些信息，则此加密器是最新变种加密器，需专业技术人员进行分析
> 3. 溯源 (单纯备份和数据恢复是不够的，溯源黑客攻击路径更重要，实战中可能会遇到上午数据恢复成功，下午或晚上又被利用漏洞进行二次勒索的情况)
> 所以在此环境中，我们会学习：勒索家族确定 ->数据恢复 ->溯源攻击路径
> 相关溯源分析报告已存放至桌面 训练环境介绍 - 必读 目录中，或可以等待 州弟学安全公众号/B 站开播 + 详细 WP 进行学习写溯源报告 + 汇报
> 注意：勒索加密原则上会加密所有可读、可运行文件等，但为了提高学习效率和简易程度，所以恢复了一部分文件作为线索，你可以仔细找找哦
> 版权作者：思而听 (山东) 网络科技有限公司、solar 应急响应团队、州弟学安全
> 特别注意：环境中的勒索家族全版本加密器已被 solar 应急响应团队 破解，勒索环境会做一个系列来帮助大家提高溯源分析的能力，尽情期待吧
> 系统：Windows server 2016
> 账号密码：administrator/Sierting789@
> 防勒索官网：http://应急响应.com(查询勒索家族及解密器搜索)
> WP：https://mp.weixin.qq.com/s/P0x6W7QhhPToJod8v-QI0g

# 步骤

## 1 步骤一

> [!info]
> 上机排查提交病毒家族的名称，可访问应急响应.com 确定家族名称，以 flag{xxx}提交 (大小写敏感)

远程登录到 `windows server` 机器上，看到很多加了 `.Live` 后缀的各种文件；如果打开桌面上的「财务」文件夹，会看到里面还有很多 `.Live` 后缀的各种文件；被加密的应该就是这些文件了。

![[实战Live勒索病毒溯源排查-260131-152549.png]]

我们随便找一个文件扔给题目给的 `应急响应.com` 的「在线病毒检测」中

![[实战Live勒索病毒溯源排查-260131-152826.png]]

查到是 `Live` 病毒家族

![[实战Live勒索病毒溯源排查-260131-152833.png]]

```
flag{Live}
```

## 2 步骤二

> [!info]
> 提交勒索病毒预留的 ID，以 flag{xxxxxx}进行提交

打开桌面上的 `FILE_RECOVERY_ID_170605242653` 文件，里面写了 `id` 就在文件名中

![[实战Live勒索病毒溯源排查-260131-153257.png]]

```
flag{170605242653}
```

## 3 步骤三

> [!info]
> 解密并提交桌面中 flag.txt.LIVE 的 flag，以 flag{xxxx}提交

去刚刚的网站下载恢复工具

![[实战Live勒索病毒溯源排查-260131-153808.png]]

提供了三个版本的工具，然后他提示了是 `1.0` 版本，如下图所示

![[实战Live勒索病毒溯源排查-260131-153811.png]]

```
LIVE_Decrypto.exe -path C:\Users\Administrator\Desktop
```

![[实战Live勒索病毒溯源排查-260131-154233.png]]

恢复桌面的加密文件后，打开 `flag.txt`，看到 `flag`

![[实战Live勒索病毒溯源排查-260131-154306.png]]

```
flag{cf0971c1d17a03823c3db541ea3b4ec2}
```

## 4 步骤四

> [!info]
> 提交 Windows Defender 删除攻击者 C2 的时间，以 flag{2025.1.1_1:10}格式提交

> [!help]
> `C2(Command and Control)` 一般是指用来远控被攻击机的一系列机制，从收集的信息看，一般是指控制的通信机制或用于控制客户端的服务端；而这里肯定指的是客户端，也就是被攻击机上的木马程序，但我并没有搜到有用 `C2` 代指木马客户端的案例，这里对这一称呼存疑。

我们看一下，它的 `Windows Defender` 已经被关了。

![[实战Live勒索病毒溯源排查-260131-163529.png]]

我们手动从「设置」里打开它 (我一开始从开始菜单中找到 `Windows Defender` 程序打开后看不到任何历史记录，只有从「设置」里打开才能看到，这里不知到为什么)，查看一下历史记录，可以看到木马被删除的时间是 `2025/8/25 10:43`

![[实战Live勒索病毒溯源排查-260131-164512.png]]

```
flag{2025.8.25_10:43}
```

## 5 步骤五

> [!info]
> 提交攻击者关闭 Windows Defender 的时间，以 flag{2025.1.1_1:10}格式提交

`Wp` 中提供的是查找 `Windows Event Log` 的事件 `id` 为 `5001` 的记录，微软的文档中称这个事件代表 `Windows Defender` 病毒扫描被关闭。

> [!quote] https://learn.microsoft.com/zh-cn/defender-endpoint/troubleshoot-service-startup-problems #知识/Windows_Event_Log/ID/5001
> ![[实战Live勒索病毒溯源排查-260131-170828.png]]

去事件查看器 (`eventvwr.msc`) 的「应用程序和服务日志/Microsorf/Windows/Windows Defender/Operational」中查看这个事件 `id` 对应的时间，为 `2025/8/25 10:45`

![[实战Live勒索病毒溯源排查-260131-175717.png]]

```
flag{2025.8.25_10:45}
```

## 6 步骤六

> [!info]
> 提交攻击者上传 C2 的绝对路径，格式以 flag{C:\xxx\xxx}提交

直接搜一下之前被 `Windows Defender` 杀掉的 `Wq12D.exe`，在 `~\Download` 目录下找到了。

![[实战Live勒索病毒溯源排查-260131-175923.png]]

```
flag{C:\Users\Administrator\Downloads\Wq12D.exe}
```

## 7 步骤七

> [!info]
> 提交攻击者 C2 的 IP 外联地址，格式以 flag{xx.x.x.x}提交

把 `Wq12D.exe` 丢沙箱里面跑，发现对外访问了 `192.168.186.2`

![[实战Live勒索病毒溯源排查-260131-184534.png]]

```
flag{192.168.186.2}
```

## 8 步骤八

> [!info]
> 提交攻击者加密器绝对路径，格式以 flag{C:\xxx\xxx}提交

复现一下 `wp` 的思路，首先找到最早被加密的文件，时间是 `8/25 11:14`

![[实战Live勒索病毒溯源排查-260131-193359.png]]

而 `C2` 客户端是 `8/25 10:48` 被上传的，那就找一下在 `10:48~11:14` 之间的可执行文件，找到 `systime.exe`

![[实战Live勒索病毒溯源排查-260131-193526.png]]

放沙箱里检测一下，发现确实是一个木马文件。

![[实战Live勒索病毒溯源排查-260131-201039.png]]

```
flag{C:\Users\Administrator\Documents\systime.exe}
```

## 9 步骤九

> [!info]
> 溯源黑客攻击路径，利用的哪个漏洞并推测验证，提交此业务运行文件的绝对路径，如：flag{C:\xxx\xxx\xxx} 注：此处需具备一些渗透思维和文件特征识别能力

用 `netstat -ano` 看一下监听的端口

![[实战Live勒索病毒溯源排查-260201-153007.png]]

其中，`21` 是 `frp`、`3306` 是 `mysql`、`3389` 是 `rdp`、`12333` 是 `web` 服务，我们首先重点看最容易的 `web` 服务。

![[实战Live勒索病毒溯源排查-260201-153741.png]]

`12333` 是一个「若依」后台管理系统，访问后它默认填充的账号密码登录不进去。

![[实战Live勒索病毒溯源排查-260201-154058.png]]

仅仅在前端这边暂时没找到可以确定版本的地方，只有一个 `Copyright © 2018-2021 ruoyi.vip All Rights Reserved.`，可以判断是「若依」`2018-2021` 年的版本，去官网的更新日志找到版本区间如下图 (`v4.6.0~v4.7.2`)：

![[实战Live勒索病毒溯源排查-260201-154935.png]]

![[实战Live勒索病毒溯源排查-260201-154839.png]]

去机器上搜一下 `ruoyi`，就会发现版本是 `4.7.1`，但再仔细看一下的话，会发现这个 `4.7.1` 的版本是其他几个被 `.Live` 加密的 `jar` 包的，而实际我们访问的站点是运行的 `ruoyi-admin.jar`，这个没有标出版本。

![[实战Live勒索病毒溯源排查-260201-160028.png]]

把这个 `ruoyi-admin.jar` 下载下来，打开查看 `application.yml` 中的信息，显示是 `4.7.1` 版本

![[实战Live勒索病毒溯源排查-260201-170156.png]]

倒是在官网的历史漏洞中找到两个漏洞，但看我下载下来的那个 `jar` 包中的 `pom.xml` 中并没有这两个漏洞的组件。

![[实战Live勒索病毒溯源排查-260201-170549.png]]

在它 `jar` 包中的文件 `main.html` 中搜到 `shiro` 的版本应该是 `v1.8.0`

![[实战Live勒索病毒溯源排查-260201-171831.png]]

网上能够找到对 `shiro 1.8.0` 漏洞的复现，并且提到了 `shiro 1.4.2` 之后加密模式由 `AES-CBC` 换成了 `AES-GCM`。

![[实战Live勒索病毒溯源排查-260201-172436.png]]

基于这些信息，去 `shiro` 综合利用工具中测试一下，成功爆破出密钥并发现利用链。

![[实战Live勒索病毒溯源排查-260201-172527.png]]

尝试执行 `whoami` 命令，成功，证明有 `shiro` 的漏洞。

![[实战Live勒索病毒溯源排查-260201-172540.png]]

那么攻击者大概就是利用的这个漏洞。

```
flag{E:\ruoyi\ruoyi-admin.jar}
```

---

#CTF/应急响应/Windows/rdp登录检测

我看 `wp` 中是有一步测试 `3389` 攻击者有没有通过 `rdp` 登录的，用的是查看「Windows Event Log」的事件 ID `4624`(An account was successfully logged on.)，看有没有登录类型 `3`(网络登录) 的方法，这里记录一下这种方法。

用「事件查看器」或 `FullEventLogView` 筛选出事件 ID 为 `4624` 的事件，找一找那段时间附近有没有登录类型为 `3`(网络登录) 的记录，发现没有；说明攻击者可能没有通过 `rdp` 登录过。

![[实战Live勒索病毒溯源排查-260201-172935.png]]

> [!note] #知识/Windows_Event_Log/ID/4624
> https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/auditing/event-4624
> 
> 表示成功登录 `Windows` 账户，它的不同登录类型的含义如下：
> ![[实战Live勒索病毒溯源排查-260201-174849.png]]
