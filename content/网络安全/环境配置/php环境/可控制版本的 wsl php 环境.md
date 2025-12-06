---
创建: 2025-09-01
tags:
  - CTF/Web/环境配置/linux_php环境
---

# 目录  ^toc

- [[#目录  ^toc|目录]]
- [[#概述|概述]]
- [[#php cli 的版本控制|php cli 的版本控制]]
	- [[#1 添加 `ppa:ondrej/php` 仓库|1 添加 `ppa:ondrej/php` 仓库]]
	- [[#2 安装 php|2 安装 php]]
		- [[#2.1 安装本体|2.1 安装本体]]
		- [[#2.2 安装插件|2.2 安装插件]]
			- [[#2.2.1 查看拓展|2.2.1 查看拓展]]
				- [[#查看已安装的外部拓展|查看已安装的外部拓展]]
				- [[#查看已启用拓展|查看已启用拓展]]
			- [[#2.2.2 安装拓展到某个php版本|2.2.2 安装拓展到某个php版本]]
	- [[#3 使用 `update-alternatives` 管理版本|3 使用 `update-alternatives` 管理版本]]
		- [[#3.1 查看已安装软件版本|3.1 查看已安装软件版本]]
		- [[#3.2 注册软件版本|3.2 注册软件版本]]
		- [[#3.3 查看已注册版本|3.3 查看已注册版本]]
		- [[#3.4 切换版本|3.4 切换版本]]
			- [[#3.4.1 交互式切换|3.4.1 交互式切换]]
			- [[#3.4.2 非交互切换|3.4.2 非交互切换]]
		- [[#3.5 清除软链接|3.5 清除软链接]]
			- [[#3.5.1 清除特定版本|3.5.1 清除特定版本]]
			- [[#3.5.2 清除全部|3.5.2 清除全部]]
- [[#apache2 php 版本控制|apache2 php 版本控制]]
	- [[#1 问题|1 问题]]
	- [[#2 `mod_php` 切换版本|2 `mod_php` 切换版本]]
		- [[#2.1 安装|2.1 安装]]
		- [[#2.2 配置文件|2.2 配置文件]]
		- [[#2.3 切换版本|2.3 切换版本]]
			- [[#2.3.1 先禁用旧版本 `mod_php`|2.3.1 先禁用旧版本 `mod_php`]]
			- [[#2.3.2 再启用新版本 `mod_php`|2.3.2 再启用新版本 `mod_php`]]
			- [[#2.3.3 重启 `apache`|2.3.3 重启 `apache`]]
	- [[#3 `php_fpm` 切换版本|3 `php_fpm` 切换版本]]
		- [[#3.1 安装|3.1 安装]]
		- [[#3.2 启动 `php-fpm` 常驻|3.2 启动 `php-fpm` 常驻]]
		- [[#3.3 在 `apache` 启用|3.3 在 `apache` 启用]]
			- [[#3.3.1 启用 `proxy_fcgi` 模块|3.3.1 启用 `proxy_fcgi` 模块]]
			- [[#3.3.2 启用 `setenvif` 模块|3.3.2 启用 `setenvif` 模块]]
			- [[#3.3.3 启用 `php8.4-fpm.conf` 配置|3.3.3 启用 `php8.4-fpm.conf` 配置]]
			- [[#3.3.4 重启 `apache`|3.3.4 重启 `apache`]]
		- [[#3.4 切换版本|3.4 切换版本]]
			- [[#3.4.1 关闭旧的 `phpx.x-fpm`|3.4.1 关闭旧的 `phpx.x-fpm`]]
			- [[#3.4.2 启动新的 `phpx.x-fpm`|3.4.2 启动新的 `phpx.x-fpm`]]
			- [[#3.4.3 停用旧的 `phpx.x-fpm.conf`|3.4.3 停用旧的 `phpx.x-fpm.conf`]]
			- [[#3.4.4 启用新的 `phpx.x-fpm.conf`|3.4.4 启用新的 `phpx.x-fpm.conf`]]
			- [[#3.4.5 重启 `apache`|3.4.5 重启 `apache`]]
- [[#总结|总结]]



# 概述
为了平时测试的时候能模拟一些只有在 `linux` 上才好模拟的 php 环境，遂在我的 ubuntu wsl 上配置了一下可以切换版本的 php 后端环境。

# php cli 的版本控制
版本控制工具采用 `update-alternatives`，这个是 `debian` 系发行版使用的通用的软件版本控制工具，通过软链接的方式实现版本切换(因此它也只能控制命令行中的版本)

## 1 添加 `ppa:ondrej/php` 仓库
官方给的多版本方案中，需要添加 `ppa` 软件仓库，以保证能下载到旧版的 `php`
![[Pasted image 20250901120516.png]]

> [!info] [什么是 PPA](https://www.cnblogs.com/JasonCeng/p/14165842.html)
> PPA 是 Personal Package Archives 首字母简写。翻译为中文意思是：个人软件包文档。
> 它允许用户建立自己的软件仓库，通过 Launchpad 进行编译并发布为 2 进制软件包，作为 apt-get 源供其他用户下载和更新。
> ![[Pasted image 20250901120759.png]]

## 2 安装 php
### 2.1 安装本体
比如要安装 `php8.4` 版本，执行：
```shell
sudo apt install php8.4
```

### 2.2 安装插件
#### 2.2.1 查看拓展
##### 查看已安装的外部拓展
这个只能查看外部拓展，看不到 `php` 核心自带的静态拓展
```shell
ls /etc/php/8.4/mods-available/
```

![[Pasted image 20250901123600.png]]

##### 查看已启用拓展
```shell
php -m
```

![[Pasted image 20250901122336.png]]

#### 2.2.2 安装拓展到某个php版本
> Ubuntu 官方 PHP 包使用 `phpX.Y-xxx` 的命名方式

比如想在 `php8.4` 上安装 `xdebug` 拓展，执行：
```shell
sudo apt install php8.4-xdebug
```

## 3 使用 `update-alternatives` 管理版本
### 3.1 查看已安装软件版本
```shell
ls /usr/bin/php*
```

![[Pasted image 20250901124201.png]]

### 3.2 注册软件版本
语法：
```shell
sudo update-alternatives --install 链接目标路径 名称标识 可执行文件路径 优先级
```

其中，
1. **链接目标路径**一般是单版本情况下**命令的路径**，比如 `php` 是 `/usr/bin/php`
2. **名称标识**是提供给 `update-alternatives` 用于将多个软件版本归为同一个软件组的。比如 `php8.4` `php7.3` 都被归为 `php` 名称标识下；而 `java` 各个版本被归为 `java` 名称标识下
3. **可执行文件路径**顾名思义
4. **优先级**规定了自动模式下谁被选中

比如要注册 `php8.4` 和 `php7.3`，执行
```shell
sudo update-alternatives --install /usr/bin/php php /usr/bin/php8.4 84
sudo update-alternatives --install /usr/bin/php php /usr/bin/php7.3 73
```

然后自动模式下，优先级更高的 `8.4` 版本就会被使用

> 一般安装完一个版本后，这个版本会被自动注册到 `update-alternatives`，所以不用手动执行

### 3.3 查看已注册版本
```shell
sudo update-alternatives --display php
```

![[Pasted image 20250901125207.png]]

### 3.4 切换版本
#### 3.4.1 交互式切换
```shell
sudo update-alternatives --config php
```

![[Pasted image 20250901125403.png]]

![[Pasted image 20250901125552.png]]

#### 3.4.2 非交互切换
```shell
sudo update-alternatives --set php /usr/bin/php7.3
```

![[Pasted image 20250901125647.png]]

### 3.5 清除软链接
#### 3.5.1 清除特定版本
```shell
sudo update-alternatives --remove php /usr/bin/php5.6
```

![[Pasted image 20250901173504.png]]

#### 3.5.2 清除全部
```shell
sudo update-alternatives --remove-all php
```

![[Pasted image 20250901173620.png]]

# apache2 php 版本控制
## 1 问题
`update-alternatives` 的原理是创建到特定版本的可执行文件的符号链接，这就使得它的版本控制只对命令行执行 `php 1.php` 之类的有效。

问题是 `apache2` 这种 `http` 服务器并不是把数据交给 `php-cli` 处理的，而是通过 `mod_php` 、`php-fpm(fastCGI)`、`php-cgi` 等 `sapi` 与 php 交互的。

## 2 `mod_php` 切换版本
### 2.1 安装
一般执行 `apt install phpx.x` 是就已经自动安装了 `mod_php`。

如果没安装，执行：
```shell
sudo apt install libapache2-mod-php8.3
```

### 2.2 配置文件
`mod_php` 的配置文件在 `/etc/apache2/mods-available/phpx.x.conf`，是在某个版本的 `mod_php` 安装后自动写入的；其中默认配置了启用 `mod_php` 的配置
```apache
<FilesMatch ".+\.phps$">
    SetHandler application/x-httpd-php-source
    # Deny access to raw php sources by default
    # To re-enable it's recommended to enable access to the files
    # only in specific virtual host or directory
    Require all denied
</FilesMatch>
```

如果想启用配置，只需 `ln /etc/apache2/mods-available/phpx.x.conf /etc/apache2/mods-enabled/phpx.x.conf` 即可，这也是下面的 `a2enmod` 命令实际做的事情。

### 2.3 切换版本
#### 2.3.1 先禁用旧版本 `mod_php`
```shell
sudo a2dismod php7.3
```

#### 2.3.2 再启用新版本 `mod_php`
```shell
sudo a2enmod php8.4
```

#### 2.3.3 重启 `apache`
```shell
sudo service apache2 restart

// 检查是否成功
systemctl status apache2.service
```

## 3 `php_fpm` 切换版本
### 3.1 安装
```shell
sudo apt install php8.4-fpm
```

安装完成后，它也提示了在 `apache` 启用的方式。
![[可控制版本的_ubuntu_php_环境-250907-192739.png]]

### 3.2 启动 `php-fpm` 常驻
设置开机自启并立即启动
```shell
sudo systemctl enable --now php8.4-fpm
```

### 3.3 在 `apache` 启用
先把原来开的 `mod_php` 关了
```shell
a2dismod php7.3
```

#### 3.3.1 启用 `proxy_fcgi` 模块
然后启动 `proxy_fcgi` 模块
```shell
a2enmod proxy_fcgi
```

#### 3.3.2 启用 `setenvif` 模块
```shell
a2enmod setenvif
```

这个主要是为了配合这个配置中的 `SetEnvIfNoCase ^Authorization$ "(.+)" HTTP_AUTHORIZATION=$1`：
```shell
root@nRainTd:/etc/apache2/conf-enabled# cat /etc/apache2/conf-enabled/php8.4-fpm.conf 
# Redirect to local php-fpm if mod_php is not available
<IfModule !mod_php8.c>
<IfModule proxy_fcgi_module>
    # Enable http authorization headers
    <IfModule setenvif_module>
    SetEnvIfNoCase ^Authorization$ "(.+)" HTTP_AUTHORIZATION=$1
    </IfModule>

    # Using (?:pattern) instead of (pattern) is a small optimization that
    # avoid capturing the matching pattern (as $1) which isn't used here
    <FilesMatch ".+\.ph(?:ar|p|tml)$">
        SetHandler "proxy:unix:/run/php/php8.4-fpm.sock|fcgi://localhost"
    </FilesMatch>
# The default configuration works for most of the installation, however it could
# be improved in various ways. One simple improvement is to not pass files that
# doesn't exist to the handler as shown below, for more configuration examples
# see https://wiki.apache.org/httpd/PHP-FPM
#    <FilesMatch ".+\.ph(?:ar|p|tml)$">
#        <If "-f %{REQUEST_FILENAME}">
#            SetHandler "proxy:unix:/run/php/php8.4-fpm.sock|fcgi://localhost"
#        </If>
#    </FilesMatch>
    <FilesMatch ".+\.phps$">
        # Deny access to raw php sources by default
        # To re-enable it's recommended to enable access to the files
        # only in specific virtual host or directory
        Require all denied
    </FilesMatch>
    # Deny access to files without filename (e.g. '.php')
    <FilesMatch "^\.ph(?:ar|p|ps|tml)$">
        Require all denied
    </FilesMatch>
</IfModule>
</IfModule>
```

#### 3.3.3 启用 `php8.4-fpm.conf` 配置
`apache2` 已经帮我们预先写好了配置，放在 `/etc/apache2/conf-available/phpx.x-fpm.conf` 中
![[可控制版本的_ubuntu_php_环境-250907-200201.png]]

内容为上一个标题中展示的配置。

要想启用，只需把 `conf-available/phpx.x-fpm.conf` 建立一个符号链接到 `conf-enable/phpx.x-fpm.conf` 即可。
也可以用如下命令
```shell
a2enconf php8.4-fpm
```

#### 3.3.4 重启 `apache`
```shell
systemctl restart apache2.service
```

然后就能正常解析 `php` 了。
![[可控制版本的_ubuntu_php_环境-250907-200611.png]]

### 3.4 切换版本
想要切换版本，只需：

#### 3.4.1 关闭旧的 `phpx.x-fpm`
```shell
systemctl disable --now php8.4-fpm.service
```

#### 3.4.2 启动新的 `phpx.x-fpm`
```shell
systemctl enable --now php7.3-fpm
```

#### 3.4.3 停用旧的 `phpx.x-fpm.conf`
```shell
a2disconf php8.4-fpm
```

#### 3.4.4 启用新的 `phpx.x-fpm.conf`
```shell
a2enconf php7.3-fpm
```

#### 3.4.5 重启 `apache`
```shell
systemctl restart apache2.service
```

然后就成功切换版本啦
![[可控制版本的_ubuntu_php_环境-250907-201937.png]]

# 总结
`php-cli` 切换版本在 `update-alternatives` 的帮助下还是很方便的；而 `sapi` 模式切换版本要麻烦一点，其中 `mod_php` 切换版本要比 `php-fpm` 少一点步骤。
然后如果用 `nginx` 的话，切换 `php-fpm` 的版本的步骤也是要比 `apache2` 少一点的，不过我暂时没配置 `nginx`，等以后测试需要用到 `nginx` 的时候再补充这篇笔记吧。

