---
创建: 2025-11-23
tags:
  - 开发/Go/包管理
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

## 1 包

### 1.1 包

以我自己比较直观的角度理解，包是 `go` 语言中“共享”全局变量作用域的基本单位；也就是说，在同一个包的不同位置声明的全局变量在那个包中的任意位置可见。

一个包由同一个文件夹下的多个 `.go` 文件构成，`go` 中对包和目录的关系的限定比较严：
1. 属于同一个包的 `.go` 文件 (以文件开头的 `package xxx` 的 `xxx` 部分相同)，只能在同一个文件夹下的相对根目录，在相对子目录中也不行；
2. 同一个文件夹下的相对根目录下存放的 `.go` 文件，必须属于同一个包，即 `package xxx` 的 `xxx` 要相同 (不过测试包例外，允许有 `xxx_test` 格式命名的测试包，放在 `xxx` 包的相同文件夹，用来以其他包的身份测试 `xxx` 包)。

### 1.2 子包

一个包可以有子包，子包所在文件夹是父包文件夹的子文件夹。

> [!tip]
> 一个包和它的子包是两个不同的包，和没有父子关系的两个包相同

## 2 模块

### 2.1 GOPATH 模式与 GOMODULE 模式

在 `go1.11` 之前，`go` 使用 `GOPATH` 模式进行包管理。在这个模式下，我们必须把源码包写在 `$GOPATH/src/` 目录下，并且包的导入路径就是 `$GOPATH/src/` 目录下的相对路径。

但 `GOPATH` 模式有个缺点，就是无法解决不同的包依赖同一个包的不同版本的问题，即依赖的版本控制问题。

因此，在 `Go1.11` 版本之后，`go` 发布了基于模块的包管理系统，即 `GOMODULE` 模式；此模式的打开与否由环境变量 `GO111MODULE` 控制，并且从 `Go1.13` 版本之后，`GOMODULE` 模式默认打开。

在 `GOPATH` 模式下，我们编写代码以包为单位，一个 `Go` 程序源码至少是一个只有一个源码文件的文件夹构成的包。
而在 `GOMODULE` 模式下，我们编写代码以模块为单位，一个 `Go` 程序源码至少是一个模块；具体来说，至少在一个文件夹下通过 `go mod init` 命令生成了一个 `go.mod` 文件并且有一个根包在同级文件夹下。

> [!tip] 单文件 Go 源码
> 上面说了两种模式下 `go` 源码的基本单位，本质上都至少是一整个文件夹；
> 但实际上，我们随便找个地方写个 `xxx.go` 文件，然后 `go run xxx.go` 也能运行，不过我们并不认为这是一个基本的 `go` 项目，只认为这是一个简单的 `helloWorld` 类代码。
> 事实上，这种单文件的源码有诸多限制，比如只能 `import` 标准库包等。

### 2.2 模块与包

模块与包的关系，并不是单纯的包含与被包含的关系。如果硬要从这种角度概括，可以把包比作一个包装好的集装箱，而模块则是在这个集装箱的外面又包了一层集装箱，是对包的包装。

从功能上来讲，模块和包负责的方向是不同的。

**包主要负责 `go` 源码的组织**。一个包通过导入路径导入其他包，进而使用其他包中写好的代码；一个包有一个根包和可选的多个嵌套的子包，根包和子包的关系与包和其他包的关系没什么两样，只不过同一个包中的根包和不同子包之间，能通过相同的根包导入路径加子包相对路径的方式去导入其他子包。

而**模块主要负责依赖管理**，一个模块同时也是一个包，有一个根包和可选的多个嵌套子包，源码的组织规则就是包的规则，不由模块来负责。
**模块名只负责定位到包，只是包的定位方式**，所以模块名就是根包的导入路径；`GOPATH` 和 `GOMODULE` 模式根包的导入路径对比起来，前者是 `$GOPATH/src/` 下的相对路径、后者则直接是模块名。

一个模块的根包文件夹下，`go.mod` 文件中记录了该模块所代表的包中所有 `import` 的模块的具体版本，比如下面的例子：

```gomod
require github.com/gin-gonic/gin v1.11.0
```

然后在该模块的包的任意源码文件中 `import "github.com/gin-gonic/gin"`，使用的源码就是 `gin@v1.11.0` 版本的源码。执行 `go build .` 等命令的时候，如果本地没有源码，会自动去包名所指示的 `url`(见后面的说明) 下载源码，源码会被缓存到 `GOPATH/pkg/mod/github.com/gin-gonic/gin@v1.11.0/` 目录下。

### 2.3 模块名与根包的导入路径

`go.mod` 的开头会通过 `module xxx/yyy` 声明一个模块名；模块名一般是一个由 `/` 分隔的路径字符串，它和此模块的根包的导入路径相同。

> [!info] 模块名与包的导入路径
> 对于根包，模块名就是包的导入路径；
> 对于子包，模块名是子包导入路径的前缀。

在 `GOMODULE` 模式下的模块名 (即根包的导入路径) 并没有很清晰的规则 (不像 `GOPATH` 模式下就是 `$GOPATH/src/` 下的相对路径)，根据模块的用途，大体分为以下两种命名规则：

1. 一般来说，自己写的、最终直接编译成可执行程序的、不计划发布为第三方库给他人使用的、根包名为 `main` 的模块的模块名是任意的，这时的模块名除了给你看以及在模块内部作为子包导入路径的前缀 (这个后面会讲到) 之外没有任何意义；
2. 但如果计划发布为第三方模块作为依赖的，模块名一般是版本控制系统源码仓库去掉协议名后的 `url`，比如 `github.com/gin-gonic/gin`；`go` 工具链可以直接通过模块名下载到源码，源码的缓存路径为 `$GOPATH/pkg/mod/` + **模块名 (根包导入路径)** + `@模块版本号`。

## 3 包名与导入路径 (模块名)

### 3.1 包名

包名，即 `.go` 源码文件开头使用 `package xxx` 声明的 `xxx` 名字。

一般来说，如果我们编写的包最终要被直接编译为可执行程序执行，那么我们把它命名为 `main` 包即可；`main` 包中一般要声明一个 `main` 函数，编译器会把这个函数当成整个程序的入口，在程序一开始调用它。

如果我们编写的包是作为第三方库使用，那就需要起一个能描述这个包功能的名字，作为包名。
其他要用到这个包的包通过 *导入路径* 导入这个包后，就是通过 `包名.Sth` 的方式访问包里面的**导出**标识符 (就是标识符与关键字的那个标识符，其实差不多就是变量名)，这就是包名的作用：作为其他包访问该包的导出标识符的“命名空间”名。

### 3.2 导出与未导出

与其他语言使用 `export` 显式导出或是使用 `public` 显式访问控制不同，`go` 语言通过标识符开头是否**大写**来确定一个标识符是否是导出的。规则很简单：

> [!info]
> 如果一个包中声明在全局作用域的标识符是以**大写字母**开头的，那么它就是**导出的**，能够被其他包通过 `包名.Xxx` 的方式访问到；
> 
> 否则，就是未导出的，只能在包内部使用，不能被其他包访问到。

### 3.3 全局作用域 (包作用域)

只要标识符不是在函数中声明的，而是在一份源码文件的顶层声明的，那么它就位于全局作用域。

能够在全局作用声明的标识符有以下四种：
- 变量 (通过 `var` 声明)
- 常量 (通过 `const` 声明)
- 类型 (通过 `type` 声明)
- 函数 (通过 `func` 声明)

包声明和包导入严格来说作用域是单个文件，而不是整个包，所以不算在上面。

声明在全局作用域的标识符，无所谓声明顺序，在整个包的任何地方都可以访问到。

### 3.4 导入路径

在其他编程语言中，`import` 一般是直接通过包名/模块名导入；而 `go` 中，则是通过导入路径。

导入路径是一个字符串，它是包的唯一标识；用于让编译器找到对应的包。

在 `GOMODULE` 模式下，根包的导入路径就是它所属模块的模块名，同时也是子包导入路径的前缀。

> [!note] 包名和导入路径的区别
> 简单来说，包名就在两个地方会用到：
>    - 源文件开头用于标识其属于哪个包，即 `package xxx`
>    - 其他包导入该包后，访问这个包时使用的默认标识符，即 `xxx.Sth`
> 
> 而导入路径则只会在 `import` 导入这个包时用到，用来定位一个包；在 `GOMODULE` 模式下其前缀或其本身就是模块名。
> 
> 一般来说，导入路径最后一个斜杠右边的字符串和包名相同；当然也可以不同。

> [!quote] 包名和导入路径的命名规范
> 命名规范推荐使用小写字母，但大写字母也是被允许的。

对于不同的包，其导入路径 (模块名) 的命名规则略有不同

#### 3.4.1 标准库包

标准库包一般使用简短的名字来表示，如果没有斜杠，则导入路径和包名相同；
如果有斜杠，则导入路径最后一个斜杠右边部分和包名相同。

例如：

```go
import (
	"fmt"
	"reflect"
	"sync"
	"sync/atomic"
)

// 使用
fmt.Println()
sync.WaitGroup
atomic.AddInt32
```

> [!info]
> 一般标准库包的导入路径就是 `$GOROOT/src/` 目录下 *包源码所在文件夹* 的相对路径，比如 `fmt` 包源码所在文件夹就是 `$GOROOT/src/fmt`，而 `sync/atomic` 包则是 `$GOROOT/src/sync/atomic`

#### 3.4.2 子包

对于同一个包的子包，**子包的导入路径** 为 **根包的导入路径 (模块名)** 加上 **子包在根包文件夹中的相对路径**

例如，我们根包的导入路径 (模块名) 为 `nRainTd/goLearn`，根包所在文件夹为 `goTry`；
子包文件夹为 `goTry/subPack`，另一个子包文件夹为 `goTry/other/childPack`，那么他们的导入路径分别为：

```go
import (
	"nRainTd/goLearn/subPack"
	"nRainTd/goLearn/other/childPack"
)
```

#### 3.4.3 第三方包

一般第三方包的导入路径为该包版本控制系统 (`git`) 源码仓库不带协议名的 `url`，`go` 工具链能够直接通过这串 `url` 直接下载到源码。

例如：

```go
import "github.com/gin-gonic/gin"
```

> [!info] GOMODULE 模式下第三方包的缓存路径
> 在 `GOMODULE` 模式下，当我们在源码中 `import "github.com/gin-gonic/gin"`；然后执行 `go mod tidy` 整理 `go.mod` 文件后 (`go.mod` 会多出一行 `require github.com/gin-gonic/gin v1.11.0` 和好几行 `gin` 的间接依赖的 `require`)，依赖的源码会被下载到 `$GOPATH/pkg/mod/` 下，具体的路径为 `$GOPATH/pkg/mod/github.com/gin-gonic/gin@1.11.0`。
> 
> 从上面的例子可以看到，`GOMODULE` 下，第三方包源码的缓存路径其实就是 `$GOPATH/pkg/mod` + **模块的导入路径** + `@` + **模块的版本** + **子包路径**(如果有)

> [!info] GOPATH 模式下第三方包的存储路径
> 在 `GOPATH` 模式下，第三方包的存储路径和用户自己的包的存储路径相同，都是 `$GOPATH/src/` 后拼接上包的导入路径作为相对路径。比如对于包 `github.com/gin-gonic/gin`，它的存储路径为 `$GOPATH/src/github.com/gin-gonic/gin`

#### 3.4.4 自己电脑上的其他包

这个情况主要是在自己电脑上写了一个作为依赖的包，但没有发布；我们要如何在另一个包中使用它。

##### GOPATH 模式

对于 `GOPATH` 模式来说很容易，我们只需要在 `$GOPATH/src/` 文件夹下写我们的包，然后在其他包把这个文件夹下该包的相对路径作为导入路径导入即可。

##### GOMODULE 模式

这个模式下比较麻烦，这里我们以一个实际的例子引入。

> [!todo] 任务
> 假设我们有一个作为依赖的模块 `nraintd/greeting`，包名为 `greeting`，里面有一个 `Hello` 函数，能够输出 `"hello"` 字符串到终端。
> 
> 然后我们要在另一个模块中导入 `nraintd/greeting` 并执行 `greeting.Hello()`。

我们先找一个文件夹 `xxx/greeting`，在这个文件夹执行：

```bash
go mod init nraintd/greeting
```

这个命令会生成文件 `go.mod`，内容为：

```gomod
module nraintd/greeting

go 1.25.3
```

接着我们再创建一个 `hello.go` 文件，内容为：

```go
package greeting

import "fmt"

func Hello() {
	fmt.Println("hello")
}

```

到此，依赖包就准备完成了。

接着，我们再创建文件夹 `xxx/main`，`cd` 进去执行 `go mod init main`(名字任意)；此时，`go.mod` 长这样：

```gomod
module main

go 1.25.3
```

然后，我们执行：

```bash
go mod edit -replace nraintd/greeting=../greeting
```

上面这个命令就是把对包导入路径 (模块名) `nraintd/greeting` “链接”到文件系统路径 `../greeting`；然后 `go.mod` 文件就会变成这样：

```gomod
module main

go 1.25.3

replace nraintd/greeting => ../greeting
```

接着我们创建 `main.go` 文件，编辑如下内容：

```go
package main

import "nraintd/greeting"

func main() {
	greeting.Hello()
}

```

然后执行 `go mod tidy`，之后 `go.mod` 会变成下面这样，可以看到增加了一行依赖信息

```gomod
module main

go 1.25.3

replace nraintd/greeting => ../greeting

require nraintd/greeting v0.0.0-00010101000000-000000000000
```

然后执行 `go run .` 就能看到输出 `hello`。

## 4 GOMODULE 模式开发流程

在 `nodejs` 中，对于存在依赖的项目，开发流程是这样的 (这里假设依赖为 `jsonwebtoken`)：
1. 执行 `npm install jsonwebtoken` 安装依赖，这时 `package.json` 会被自动更新；
2. 在代码中 `import jsonwebtoken` 使用依赖。

但在 `go` 中，对于存在依赖的项目，开发流程一般是这样的 (这里假设依赖为 `gin`)：
1. 在代码中 `import "github.com/gin-gonic/gin"`；
2. 执行 `go mod tidy` 更新 `go.mod`，如果依赖没缓存，则自动下载依赖缓存起来。

更新后的 `go.mod` 长下面这样，可以看到不仅记录了直接依赖，还记录了间接依赖

```gomod
module main

go 1.25.3

require github.com/gin-gonic/gin v1.11.0

require (
	github.com/bytedance/sonic v1.14.0 // indirect
	github.com/bytedance/sonic/loader v0.3.0 // indirect
	github.com/cloudwego/base64x v0.1.6 // indirect
	github.com/gabriel-vasile/mimetype v1.4.8 // indirect
	github.com/gin-contrib/sse v1.1.0 // indirect
	github.com/go-playground/locales v0.14.1 // indirect
	github.com/go-playground/universal-translator v0.18.1 // indirect
	github.com/go-playground/validator/v10 v10.27.0 // indirect
	github.com/goccy/go-json v0.10.2 // indirect
	github.com/goccy/go-yaml v1.18.0 // indirect
	github.com/json-iterator/go v1.1.12 // indirect
	github.com/klauspost/cpuid/v2 v2.3.0 // indirect
	github.com/leodido/go-urn v1.4.0 // indirect
	github.com/mattn/go-isatty v0.0.20 // indirect
	github.com/modern-go/concurrent v0.0.0-20180228061459-e0a39a4cb421 // indirect
	github.com/modern-go/reflect2 v1.0.2 // indirect
	github.com/pelletier/go-toml/v2 v2.2.4 // indirect
	github.com/quic-go/qpack v0.5.1 // indirect
	github.com/quic-go/quic-go v0.54.0 // indirect
	github.com/twitchyliquid64/golang-asm v0.15.1 // indirect
	github.com/ugorji/go/codec v1.3.0 // indirect
	go.uber.org/mock v0.5.0 // indirect
	golang.org/x/arch v0.20.0 // indirect
	golang.org/x/crypto v0.40.0 // indirect
	golang.org/x/mod v0.25.0 // indirect
	golang.org/x/net v0.42.0 // indirect
	golang.org/x/sync v0.16.0 // indirect
	golang.org/x/sys v0.35.0 // indirect
	golang.org/x/text v0.27.0 // indirect
	golang.org/x/tools v0.34.0 // indirect
	google.golang.org/protobuf v1.36.9 // indirect
)
```

个人感觉 `Go` 的这种模式有一个问题，就是在执行 `go mod tidy` 添加依赖到 `go.mod` 并下载到依赖缓存之前，我们在代码中 `import` 一个依赖后是得不到自动补全提示的。比如 `import "github.com/gin-gonic/gin"` 后，我们写 `gin.` 之后，编辑器是不会自动提示 `gin` 这个包里有哪些导出标识符的。
