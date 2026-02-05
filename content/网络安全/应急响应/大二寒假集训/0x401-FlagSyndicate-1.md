---
created: 2026-01-28
modified: 2026-01-28
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

# 步骤

## 1 步骤一

> [!info]
> 检材的桌面操作系统是什么? (例: windows)(全部小写)

给的是一个 `vmware` 的 `.vmdk` 虚拟磁盘，我们可以直接找一个虚拟机添加这块硬盘，也可以用 `winhex` 专业版打开为虚拟文件系统，或者用 `DiskGenius` 打开，或者是 `DisInternals Linux Reader`。

在虚拟磁盘中找到 `/etc/os-release` 文件。

![[0x401-FlagSyndicate-1-260128-170200.png]]

然后可以看到操作系统为 `openKylin`。

![[0x401-FlagSyndicate-1-260128-170502.png]]

## 2 步骤二

> [!info]
> 检材中, Admin 用户的登录密码是什么? (例: root123)

找到 `/etc/shadow`，提取出 `Admin` 账户的 `hash`，用 `john` 爆破

![[0x401-FlagSyndicate-1-260128-170924.png]]

```
$y$j9T$RbveVuu7tAeUPOLCzrOLd1$SYokL4B01azgKIIoXEr5zKWWohC3o7nUbqV0/Gni5o3
```

![[0x401-FlagSyndicate-1-260128-171604.png]]

```
sadrtdchampions
```

## 3 步骤三

> [!info]
> 机主访问过一个 CTF 比赛网站，这场 CTF 的名称是什么? (例: scuctf)

一开始是想着看看在某文件夹找找做题记录的，就是保存在本地的附件；不过没找到。

桌面找到一个 `elf` 文件，后面会用到。

![[0x401-FlagSyndicate-1-260129-164320.png]]

下载文件夹中是一个邮箱软件。

![[0x401-FlagSyndicate-1-260129-163725.png]]

前面说机主是访问过一个 `ctf` **网站**，那我们就看看浏览器的浏览记录；找到 `firefox` 的用户文件目录 `~/.mozilla/firefox/obo3j1ep.default-release/`，其中 `places.sqlite` 文件存储了浏览器的 *历史记录*、*书签* 等数据。

![[0x401-FlagSyndicate-1-260129-234306.png]]

我们打开 `moz_historyvisits` 表，会发现里面并没有记录 `url`，如下图；这其实很正常，只是关系型数据库的常见实践罢了；所有 `url` 数据其实统一存在 `moz_places` 中，然后 `moz_historyvisits` 表通过 `id` 主键关联到后者而已。

![[0x401-FlagSyndicate-1-260129-184842.png]]

我们在 `moz_places` 这张表中就能很容易找到一个 `http://umdctf.io/` 的 `url` 了，这个就是机主访问过的 `ctf` 比赛网站。

![[0x401-FlagSyndicate-1-260129-164117.png]]

```
umdctf
```

## 4 步骤四

> [!info]
> 计算机中存在一个通讯工具，请问该工具的名称是什么? (例: talk_tool)

步骤三的时候其实已经找到了两个，一个是 `commu_server`，一个是知名邮箱客户端 `thunderbird`。两个其实都能叫通讯工具，都试一下后就会发现是 `commu_server`。

## 5 步骤五

> [!info]
> 该通讯工具的监听端口是多少? (例: 1234)

用 `ida` 反编译一下，从伪代码中很容易看到是 `4398`

![[0x401-FlagSyndicate-1-260129-190636.png]]

```
4398
```

## 6 步骤六

> [!info]
> 机主一共通过该通讯工具接收了多少条消息? (例: 100)

这需要逆向分析一下这个通讯工具，看看它有没有保存什么日志文件之类的；

下面的每张图片我都用 *绿色* 的文字加了注释，仅看我图片中的分析就能知道反编译的伪代码的逻辑。

下面这张图是接收客户端连接后交给 `handle_client` 函数处理，具体看图片中加的批注。

![[0x401-FlagSyndicate-1-260129-193809.png]]

下面这两张图片是循环从客户端读取数据，然后分别生成两个随机数作为 `key` 和 `iv`，`cbc` 模式的 `aes` 加密数据后，将 `key / iv` 追加到加密数据末尾后用 `base64` 编码；具体步骤看两张图片中我加的注释。

![[0x401-FlagSyndicate-1-260129-194825.png]]

![[0x401-FlagSyndicate-1-260129-211649.png]]

下面这张图片是将上面的 `base64` 结果以 `[时间] base64` 的形式追加到 `/tmp/commu_log.txt` 中。

![[0x401-FlagSyndicate-1-260129-200712.png]]

那我们直接去读取 `/tmp/commu_log.txt` 即可

![[0x401-FlagSyndicate-1-260129-201040.png]]

一共六条记录

```
6
```

## 7 步骤七

> [!info]
> 机主通过该通讯工具接收了一个文件，接收到该文件的具体时间 (UTC+8) 是? (例: 1919-08-10_11:45:14)

从上图可以看出，只有一条特别长的记录，所以是那条；如果记录特别多的话，就要写个脚本去挨个解密内容后判断哪个是文件了，不过这里不用，所以解密的脚本就放到下一个步骤再写了。

![[0x401-FlagSyndicate-1-260129-201342.png]]

```
2025-10-29_14:57:42
```

## 8 步骤八

> [!info]
> 接收的文件的 MD5 是多少?

根据步骤六的分析我们可以知道，日志文件中每行 `base64` 解密后的后 `32` 位中藏有 `key` 和 `iv`；因此我们可以写个脚本，读取后 `32` 位的 `key / iv` 然后用它们解密前面的数据。

另外它 `aes` 用的 `CBC` 模式，如下图所示：

![[0x401-FlagSyndicate-1-260129-231333.png]]

我们写解密脚本如下：

```go
package main

import (
	"bufio"
	"crypto/aes"
	"crypto/cipher"
	"encoding/base64"
	"errors"
	"fmt"
	"os"
	"strings"
)

func main() {
	f, err := os.Open("./commu_log.txt")
	if err != nil {
		panic(err)
	}
	defer f.Close()
	s := bufio.NewScanner(f)
	for s.Scan() {
		line := s.Text()

		b64 := strings.Trim(strings.Split(line, "]")[1], " ")

		dest := make([]byte, len(b64))
		n, err := base64.StdEncoding.Decode(dest, []byte(b64))
		if err != nil {
			panic(err)
		}
		dest = dest[:n:n]

		cipherLen := len(dest) - 32
		cipherText := dest[:cipherLen:cipherLen]
		key := dest[cipherLen : cipherLen+16 : cipherLen+16]
		iv := dest[cipherLen+16:]

		res, err := AesDecrypt(cipherText, key, iv)
		if err != nil {
			fmt.Println("解密失败:", err)
		}
		fmt.Println(string(res) + "\n")
	}
}

func AesDecrypt(cipherText []byte, key []byte, iv []byte) (plainText []byte, err error) {
	b, err := aes.NewCipher(key)
	if err != nil {
		return
	}

	m := cipher.NewCBCDecrypter(b, iv)

	plainText = make([]byte, len(cipherText))
	m.CryptBlocks(plainText, cipherText)

	plainText, err = dePadding(plainText, m.BlockSize())
	return
}

func dePadding(text []byte, size int) ([]byte, error) {
	paddingLen := text[len(text)-1]
	if paddingLen > 0 && paddingLen <= byte(size) {
		return text[:len(text)-int(paddingLen)], nil
	}
	return nil, errors.New("Padding 不正确")
}
```

结果如下：

```
Hello, I'm your boss.

It's time to work.

I will give you the source code of the market system.

Now,you will receive a file called market.zip from the server.

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

All done! Please construct the website.
```

可以看到中间的文件部分是被 `base64` 编码过的，我们解解码后再 `md5` 一下即可。

![[0x401-FlagSyndicate-1-260129-231916.png]]

```
fe1829167aa8ed4f28d4651a7876a2e7
```
