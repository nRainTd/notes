---
created: 2026-02-27
modified: 2026-02-27
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
> 描述同 part1
> 参考：https://mp.weixin.qq.com/s/xkHNm7AN4BCpQIr9thIS7A

# 步骤

## 1 步骤一

> [!info]
> 最早的 WebShell 落地时间是 (时间格式统一为：2022/12/12/2:22:22);

用 `d_safe` 扫描 `web` 目录，扫到一堆 `webshell`；按时间排序找到最早的

![[part2-第九章-Where-1S-tHe-Hacker-260228-165651.png]]

```flag1
2023/11/11/0:30:07
```

## 2 步骤二

> [!info]
> 黑客最早的 WebShell 密码是多少，将 WebShell 密码作为 Flag 值提交;

![[part2-第九章-Where-1S-tHe-Hacker-260228-165827.png]]

```flag2
pass
```

## 3 步骤三

> [!info]
> CobaltStrike 木马的文件名和落地时间是？

用 `d-eyes de fs -p C:\` 扫描，扫到 `C:\Windows\Temp\huorong.exe`

![[part2-第九章-Where-1S-tHe-Hacker-260301-140845.png]]

放云沙箱中，是木马

![[part2-第九章-Where-1S-tHe-Hacker-260301-141138.png]]

找到文件位置，查看创建时间

![[part2-第九章-Where-1S-tHe-Hacker-260301-141110.png]]

```flag3
huorong.exe,2023/11/15/7:45:47
```

## 4 步骤四

> [!info]
> CobaltStrike 木马被添加进计划任务的时间是

用火绒剑看一下计划任务，其中，安全状态为「未知文件」的计划任务，文件路径就是刚刚的木马

![[part2-第九章-Where-1S-tHe-Hacker-260301-135343.png]]

去找一下这项计划任务的创建时间

![[part2-第九章-Where-1S-tHe-Hacker-260301-140048.png|650]]

```flag4
2023/11/15/8:02:20
```

## 5 步骤五

> [!info]
> 黑客启用并添加进管理员组的用户与时间是 答案格式：Username,2022/12/12/2:22:22

`net user` 命令看一下有哪些用户，然后再用如 `net user Guest` 看一下每个用户的本地组，可以看到 `Guest` 居然属于 `Administrators` 组，有管理员权限；因此这大概就是黑客添加的。

![[part2-第九章-Where-1S-tHe-Hacker-260301-132620.png]]

去事件查看器搜索 `4732` 事件 ID，找到添加 `Guest` 进管理员组的时间。

![[part2-第九章-Where-1S-tHe-Hacker-260301-133203.png]]

```flag5
Guest,2023/11/11/0:45:59
```

## 6 步骤六

> [!info]
> 5.攻击者使用弱口令登录 ftp 的时间是

打开小皮面板，它有一个 `ftp` 服务的选项

![[part2-第九章-Where-1S-tHe-Hacker-260301-134344.png]]

然后我们可以看一下他配置的用户名和密码

![[part2-第九章-Where-1S-tHe-Hacker-260301-142536.png]]

这里用的 `ftp` 服务器是开源的 `FileZilla Server`，它在小皮中的日志在下面的位置

![[part2-第九章-Where-1S-tHe-Hacker-260301-142009.png]]

找到这段日志，可以看到先是尝试登录匿名用户失败，然后再用弱口令登录了 `ftp` 用户，弱口令长度和之前我们看到的一致，并且登录成功了

![[part2-第九章-Where-1S-tHe-Hacker-260301-142827.png]]

```flag6
2023/11/11/1:08:54
```

## 7 步骤六

> [!info]
> 6.攻击者使用弱口令登录 web 管理员的时间是

小皮面板有两个反向代理，其中 `nginx` 的日志是空的

![[part2-第九章-Where-1S-tHe-Hacker-260301-143619.png]]

而 `apache` 的日志则有记录，说明是用的 `apache`，我们导出它的日志，以待分析

![[part2-第九章-Where-1S-tHe-Hacker-260301-143629.png]]

然后我们看到它的 `web` 目录是有一个 `admin.php` 的

![[part2-第九章-Where-1S-tHe-Hacker-260301-143604.png]]

访问，看到它的登录表单的提交地址是 `/index.php?mod=mobile&act=public&do=login`

![[part2-第九章-Where-1S-tHe-Hacker-260301-144201.png]]

我们用弱口令登录，发现登录成功后会跳转到 `/index.php?mod=site&act=manager&do=store&op=display`

![[part2-第九章-Where-1S-tHe-Hacker-260301-144853.png]]

基于上面的特征，我们先在日志中搜索表单的提交路由，可以看到有明显的爆破痕迹，然后最后一条记录有两个 `302` 跳转到了我们上面尝试登录成功后的路由，说明这条就是爆破成功的记录

![[part2-第九章-Where-1S-tHe-Hacker-260301-145101.png]]

```flag7
2023/11/15/7:38:31
```
