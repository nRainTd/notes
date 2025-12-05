---
创建: 2025-11-23
tags:
  - 开发/Go/基础语法
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

## 1 关键字和标识符

Go 中一共有 25 个关键字，关键字不能被覆盖，它们只能在特定的语法结构中使用。

这 25 个关键字分别是：

```go
break      default       func     interface   select
case       defer         go       map         struct
chan       else          goto     package     switch
const      fallthrough   if       range       type
continue   for           import   return      var
```

除了这 25 个关键字之外，其他的都是标识符。下面是一些 Go 语言预声明的标识符，它们分别是内建常量、内建类型和内建函数。

```go
内建常量: 
true false iota nil

内建类型: 
int int8 int16 int32 int64
uint uint8 uint16 uint32 uint64 uintptr
float32 float64 complex128 complex64
bool byte rune string error

内建函数: 
make len cap new append copy close delete
complex real imag
panic recover
```

是的，类型是标识符而不是关键字；因此我们完全可以覆盖它，比如下面的例子就覆盖了 `true` 和 `int` 两个表示符，而且能正常运行。

```go
package main

import (
	"fmt"
)

func main() {
	true := 123
	int := 456
	fmt.Println(true)
	fmt.Println(int)
}

```

我们会发现上面那 25 个关键字中有 `map`，那么这是否与我们上面说的类型是标识符而不是关键字的说法冲突呢？
不冲突，因为 `map` 类型是没法确定的，`map[int]int` 和 `map[string]int` 就是两个不同的类型；所以无法预声明为标识符。而 `map` 只是一个类型构造符，用来构造出特定的 `map` 类型，所以是关键字。

## 2 声明语句

### 2.1 全局声明与局部声明

在全局作用域能声明的东西已经在 [[#3.3 全局作用域(包作用域)]] 这个标题下叙述过了，因此这里我们主要讲局部作用域的声明语句。

在局部作用域能主要能声明变量、常量、类型三种标识符，无法声明函数 (但可以把匿名函数保存到变量中)

### 2.2 变量

#### 2.2.1 `var` 声明

这三种形式都可以，支持自动类型推导

```go
var a int

var b int = 123

var c = 123
```

#### 2.2.2 短变量声明

只能在局部变量中使用。只有这一种格式；对于这种格式，注意不要重复声明 (把赋值语句写成声明)。

```go
a := 123
```

### 2.3 常量

形式如下：

```go
const a int = 123
const b = 123
```

#### 2.3.1 常量的类型

常量只能保存**布尔型**、**数值型**和**字符串型**的值，不能保存其他类型的值 (比如结构体、数组)

特别的，对于 `const b = 123` 这种为具体指定类型的常量，它的类型在声明时是 `untyped` 的；其具体的类型由其上下文来决定。

例如下面这个例子，对于赋值给 `Big` 的数 `1 << 50`，其字面量是 `int` 类型，如果赋值给一个变量的话，使用的时候就只能传递给 `needInt()` 函数；而下面代码中赋值给了一个常量，那么这个常量就能同时用在 `needInt()` 和 `needFloat` 函数中，而且不用类型转换。

```go
package constLearn

import "fmt"

const (
	Big = 1 << 50
)

func TestConst() {
	fmt.Println(needInt(Big))
	fmt.Println(needFloat(Big))
}

func needInt(x int) int { return x }
func needFloat(x float64) float64 {
	return x
}
```

这就是因为 Go 未声明类型的常量的类型根据上下文决定的；在编译期间，Go 语言把 `untyped` 常量看做精确值，在合适的上下文中才把其转换为具体的类型。

这一点我自己其实也没太多直观的理解，这里就不多讲了，反正也是一个不痛不痒的特性。

#### 2.3.2 常量用作枚举

比如下面的例子，解释一下语法：
1. 对于一个 `const ()` 块，如果只赋值了第一行，那么下面几行常量将赋和第一行一样的值；
2. 在下面代码中，每行都被赋值为 `iota + 1`；
3. 然后 `iota` 是一个特殊的常量，编译器在 `const` 后第一次出现 `iota` 时将其重置为 `0`，然后每重复出现一次，就把他的值加一；
4. 于是就有了下面代码的写法，实际上就是从 `Monday` 到 `Sunday` 依次被赋值为了 `1~7`。

```go
package enumLearn

import "fmt"

type week int

const (
	Monday week = iota + 1
	Tuesday
	Wednesday
	Thursday
	Friday
	Saturday
	Sunday
)

func Camp() {
	WeekOne := week(1)
	One := 1

	fmt.Println(WeekOne == Monday) // true
	fmt.Println(One == Monday) // 编译不通过，必须同一类型相比
}
```

### 2.4 类型

Go 语言中，使用 `type` 关键字声明一个类型，它的语法为：

```go
type [newType] [baseType]
```

使用这种方法声明的类型不是其基础类型的别名，而是和基础类型在语义上完全不同的新类型；新类型和基础类型虽然都能被相同的字面量赋值，但这两种类型的变量不能相互赋值；如果把这两种类型赋值给一个接口，那么对这个接口向两种类型转换使用的类型断言也不同 (并且保存新类型的接口只能断言为新类型，不能断言为它的基础类型；同样保存基础类型的接口也不能断言出新类型)。

具体可以看这个例子

```go
import "fmt"

type myStr string

func TestType() {
	a := myStr("hello")
	i := any(a)
	str, ok := i.(string)
	my_str, my_ok := i.(myStr)
	fmt.Println(str, ok)       // false
	fmt.Println(my_str, my_ok) // hello true
}

```

与之相反的，是下面这种语法：

```go
type [aliasType] [originType]
```

使用上面这种语法定义的类型只是原本类型的别名罢了。

## 3 作用域

Go 语言从外到内一共可以分为五种作用域，分别是 `Universe scope`、`Package scope`、`File scope`、`Func scope` 和 `Block scope`。

### 3.1 `Universe` 作用域

主要是一些内建标识符在这个作用域中，在任何包内可见。

### 3.2 包作用域 (全局作用域)

整个包可见，详细请看 [[#3.3 全局作用域(包作用域)]] 这个标题。由于它的概念类似其他编程语言中的全局作用域，所以我也这么叫它。

### 3.3 文件作用域

#### 3.3.1 `import` 语句

对于 `import` 语句导入的“包类型”的标识符，仅在使用了 `import` 的文件中可见，是文件级作用域。

#### 3.3.2 `init` 函数

还有 `init` 函数，也是各个文件相互独立的文件级作用域；即同一个包内的每个文件都可以有一个 `init` 函数，它们相互独立，作用域仅为它们所在文件。

这是个和 `main` 类似的特殊函数，在包初始化的时候被执行；它的执行时机在全局变量初始化之后、`main` 函数调用之前。同一个包不同文件中的 `init` 函数会按照文件名的字典序的顺序依次被执行。

### 3.4 函数级作用域

这个没啥好说的，跟其他编程语言一样。

### 3.5 块级作用域

`if` `for` 等块内声明的标识符属于这个作用域，也没啥好说，跟其他编程语言一样。

## 4 数据类型

### 4.1 基本的数据类型

go 中基本的数据类型如下：

```go
bool

string

int  int8  int16  int32  int64
uint uint8 uint16 uint32 uint64 uintptr

byte // uint8 的别名

rune // int32 的别名，表示一个 Unicode 码位

float32 float64

complex64 complex128
```

### 4.2 类型转换

#### 4.2.1 赋值、运算需手动类型转换

Go 语言中没有隐式类型转换、没有类型自动提升，所有需要类型转换的地方都必须手动进行。

如下面的例子所示：

```go
package main

import (
	"fmt"
)

func main() {
	var a0 int8 = 1
	var a int16 = int16(a0)
	var b int32 = 1234
	var c float64 = 0.1
	var d float64 = float64(a) + float64(b) + c
	fmt.Println(d)
}

```

#### 4.2.2 只能在兼容的类型间转换

这里简单归纳了一下可以类型转换的兼容类型

##### 底层类型相同

命令类型和它的底层类型，以及具有相同底层类型的命名类型之间可以互相转换。

```go
type int1 int
type int2 int

func main() {
	var a int1 = int1(123)
	var b int2 = int2(a)
	var c int = int(b)
	fmt.Println(c)
}
```

##### 数值类型

数值类型之间相互转换除了会有精度损失外，一般是可以互相转换的；

不过有一个特殊的是复数，只能其他数值类型转复数，不能复数转其他数值类型。

##### 字符串和 byte/rune 切片

字符串和 `byte[]/rune[]` 可以相互转换；

另外，由于 `type byte = uint8`、`type rune = int32`，所以字符串也可以和 `uint8[]/int32[]` 互转，但其他的数值类型切片不行。

## 5 控制结构

### 5.1 分支

#### 5.1.1 if

与其他语言不同，Go 的 `if` 语句除了接收一个条件表达式，还可以像 `for` 一样有一个初始化语句。

用法如下面代码所示：

```go
package main

import (
	"fmt"
	"math/rand"
)

func main() {
	if res := rand.Intn(100); res < 50 {
		fmt.Println("<50:", res)
	} else {
		fmt.Println(">=50:", res)
	}
}
```

当然，正常的 `if` 也是可以的

```go
func main() {
	res := rand.Intn(100)

	if res <= 20 {
		fmt.Println("0~20")
	} else if res <= 40 {
		fmt.Println("21~40")
	} else {
		fmt.Println("41~99")
	}
}
```

#### 5.1.2 switch

##### switch 默认 break

Go 中的 `switch` 和 `if` 类似，也可以有一个初始化语句在前面。然后除了 Go 中去掉了 `break` 而是默认只执行匹配的 `case` 之外，其他的都和其他语言类似。

然后 `switch` 有一个特殊的类型选择语法，这个写到接口那的时候再讲。

```go
func main() {
	switch res := rand.Intn(3); res {
	case 0:
		fmt.Println("零")
	case 1:
		fmt.Println("一")
	case 2:
		fmt.Println("二")
	default:
		fmt.Println("其他")
	}
}
```

或，

```go
func main() {
	res := rand.Intn(3)

	switch res {
	case 0:
		fmt.Println("零")
	case 1:
		fmt.Println("一")
	case 2:
		fmt.Println("二")
	default:
		fmt.Println("其他")
	}
}
```

##### fallthrough

如果想实现像其他语言不写 `break` 那样的效果，则需要手动在每个 `case` 中写 `fallthrough`，表示执行完这个 `case` 后继续执行下一个 `case`(注意如果只在一个 `case` 中写了 `fallthrough`，最后最多会执行两个 `case`，因为 `fallthrough` 只会使下**一个** `case` 执行)

```go
switch res := 0; res {
case 0:
	fmt.Print("零")
	fallthrough
case 1:
	fmt.Print("一")
case 2:
	fmt.Print("二")
default:
	fmt.Print("其他")
}
```

上面这串代码最后会输出 `零一`

##### 无条件 switch

> [!quote] 参考
> https://tour.go-zh.org/flowcontrol/11

无条件的 `switch` 相当于 `switch true`，匹配条件表达式为真的 `case`；这其实就是 `if{}else{}` 的语法糖，能把多分支写得更清晰。

```go
func main() {
	h := time.Now().Hour()
	switch {
	case h < 12:
		println("上午好")
	case h < 18:
		println("下午好")
	default:
		println("晚上好")
	}
}
```

### 5.2 循环

#### 5.2.1 for

直接看代码

和其他编程语言类似的形式：

```go
for i := 0; i < 10; i++ {
	fmt.Print(i)
}
```

Go 中没有 `while` 关键字，`for` 就是 `while`：

```go
i := 0
for i < 10 {
	fmt.Print(i)
	i++
}
```

还可以直接写死循环

```go
i := 0
for {
	fmt.Println(i)
	i++
}
```

#### 5.2.2 for range

##### 语法糖

Go 提供的用于迭代数组、切片、字符串、`map`、`chan` 的语法糖，和 `js`/`python` 的迭代器机制不同，`go` 的 `range` 只是语法糖，编译后会生成对应的基本迭代逻辑。

具体的使用方法等讲到对应类型时再讲，这里只给出迭代字符串的例子

```go
str := "hello world"
for i, ch := range str {
	fmt.Printf("%d: %c\n", i, ch)
}
```

当然，`range` 后面也可以跟整数值，这也是一个语法糖；比如下面的例子：

```go
for i := range 5 {
	fmt.Println(i)
}
```

其实是下面代码的语法糖

```go
for i := 0; i < 5; i++ {
	fmt.Println(i)
}
```

##### 迭代器

在 go1.23 版本之后，go 支持了 `range over func`，即 `range` 可以用来 *“迭代”* 函数了。

不过，并不是什么函数都可以被 `range` 迭代，必须得是函数签名符合 
`iter.Seq[V any] func(yield func(V) bool)` 或 
`iter.Seq2[K, V any] func(yield func(K, V) bool)` 
的函数才可以；这样的函数被称为**迭代器**。

###### 推送式迭代器

Go 的 `range over func` 迭代器是推送式的，为了方便说明，我们先写一个例子：

```go
func TestRange() {
	i := 0
	for n := range Fib(10) {
		i++
		fmt.Println(i, n)
	}
}

func Fib(n int) iter.Seq[int] {
	a, b := 0, 1
	return func(yield func(int) bool) {
		for range n {
			if !yield(b) {
				fmt.Println("break")
				return
			}
			a, b = b, a+b
		}
	}
}
```

上面例子中，我们写了一个能够生成特定长度斐波那契数列的迭代器的生成函数 `Fib`，它接受参数 `n` 并返回一个迭代器；

这个迭代器接收一个 `yield func(int) bool` 参数作为回调函数，可以认为 `for range` 的循环体就是这个回调函数 `yield` 的函数体、`for range` 的返回值就是这个 `yield` 的参数；`yield` 只是命名惯例，也可以使用其他名字。

因此，每当迭代器内部调用一次 `yield` 回调，`for range` 循环体都会被执行一遍，并且传递给 `yield` 的参数会被作为 `for range` 的 `:=` 返回值，供循环体内部使用；

`yield` 回调的返回值为 `bool` 类型，当循环体内执行 `break` 的时候，它的返回值为 `false`；像 `break` `continue` `goto` `return` `defer` 这些关键词的行为，`go` 已经帮我们自动处理好了，也就是我们在 `for range over func` 循环体内可以像正常循环体那样使用它，而不用考虑 `range over func` 的循环体实际上是被包装成 `yield` 回调的。

之所以称这种迭代器为推送式迭代器，是因为在这种迭代器中，迭代流程是由迭代器主动控制的，每当**迭代器内部调用**一次 `yield`，`for range over func` 循环体就会被执行一遍；并且循环体每次获取到的元素值是由迭代器调用 `yield` 是**推送**的。

这种迭代器就类似于 `js` 中的 `forEach`：

```js
let arr = [1, 2, 3, 4];
arr.forEach(ele => {
	console.log(ele);
})
```

在 `go` 中，我们也可以在自定义类型 `type Array[T any] []T` 上实现类似的 `forEach`，以及实现能用于 `range over func` 的迭代器版本的生成函数 `forEachIterGen`(当然这里只是演示，实际肯定不会这么用，毕竟 `for range` 本身就能迭代切片)：

```go
type Array[T any] []T

func (arr Array[T]) ForEach(yield func(ele T)) {
	for _, ele := range arr {
		yield(ele)
	}
}

func (arr Array[T]) ForEachIterGen() iter.Seq[T] {
	return func(yield func(T) bool) {
		for _, ele := range arr {
			if !yield(ele) {
				return
			}
		}
	}
}

func TestForEach() {
	arr := Array[int]([]int{1, 2, 3, 4})

	fmt.Println("ForEach:")
	arr.ForEach(func(ele int) {
		fmt.Printf("%v ", ele)
	})

	fmt.Println()

	fmt.Println("ForEachRange:")
	for ele := range arr.ForEachIterGen() {
		fmt.Printf("%v ", ele)
	}
}
```

###### 拉取式迭代器

在 `go` 中，一个经典的拉取式迭代器的例子是 `bufio.Scanner`：

```go
scanner := bufio.NewScanner(file)
for scanner.Scan() {
    line, err := scanner.Text(), scanner.Err()
    if err != nil {
        fmt.Println(err)
        return
    }
    fmt.Println(line)
}
```

可以看到，在拉取事迭代器中，迭代流程是由用户控制而非迭代器控制的；具体地，在上面例子中，迭代器只通过 `.Scan()` 方法来告知用户迭代是否完毕，而由用户用 `.Text()` 方法来**拉取**一次数据并开启下一次迭代。

我们不难看出，拉取式迭代器并不涉及语言特性，而是一种编程范式罢了；我们完全可以利用结构体保存状态的特性来实现一个拉取式迭代器，然后用普通 `for` 循环来使用它。

对于 `iter.Seq` 和 `iter.Seq2` 的推送式迭代器，`iter` 包提供了将其转换为拉取式迭代器的方法：
`func Pull[V any](seq Seq[V]) (next func() (V, bool), stop func())` 和
`func Pull2[K, V any](seq Seq2[K, V]) (next func() (K, V, bool), stop func())`，
他们接收一个推送式迭代器，并返回 `next` 函数用于拉取数据和继续下一次迭代、以及 `stop` 函数用于停止迭代。

对于之前的 `Fib(10)`，转换为拉取式后用法如下：

```go
next, stop := iter.Pull(Fib(10))
defer stop()
for {
	n, ok := next()
	if !ok {
		break
	}
	fmt.Println(n)
}
```

它只是用来把现成的 `iter.Seq` 转换为拉取式用的，如果就是像写拉取式的话，直接写就行了 (就行 `bufio.Scanner`)，不需要中间再转换一遍。

## 6 复合数据类型

### 6.1 数组与切片

#### 6.1.1 数组

数组是一个由多个类型相同的值排列在一起组成的长度固定的序列；它的类型声明如下：

```go
[<长度>]valueType
```

##### 数组的长度是固定的

Go 语言中的数组和 C 语言一样，都是固定长度的；
在声明数组时，必须指定好长度。

```go
greets := [2]string{"hello", "world"}
var bin [2]int
bin[0] = 0
bin[1] = 1
fmt.Println(greets)
fmt.Println(bin)
```

> [!warning] 下标访问越界问题
> 对于数组，越界访问会直接报运行时错误。

##### 获取数组长度

通过 `len` 内置函数可以获得一个数组的长度

```go
len(bin) // 2
```

##### Go 数组是值类型

这里需要提一个跟其他编程语言不一样的点，就是在 Go 中，数组是值类型，而不是引用类型。

这就导致，数组的赋值等操作是值传递，而不是引用传递。引用传递造成的特性 Go 数组都没有。

如下面的例子所示，把 `arr` 赋值给 `arr2`，传递的是整个数组的值，而不是对数组的引用；之后我们改变 `arr[1]` 下标的值，并不会同时改变 `arr2[1]`，因为他们两个变量中保存的是不同的数组。

```go
func main() {
	arr := [5]int{1, 2, 3, 4, 5}
	arr2 := arr
	arr[1] = 1
	fmt.Println(arr)
	fmt.Println(arr2)
}
```

```
[1 1 3 4 5]
[1 2 3 4 5]
```

##### 数组的比较

如果数组的元素是可以比较的，那么该数组就是可以比较的；可以使用 `==` 或 `!=` 运算符比较两个可比较的数组，这时将按位置比较两个数组的每个元素是否相等，如果都相等结果为 `true`，否则为 `false`。

> [!tip]
> 另外还需要注意一个点，就是可比较的前提是类型相同；
> 而 `[3]int` 和 `[5]int` 是两个不同的类型，它们不可比较。

##### for range 遍历数组

```go
func main() {
	arr := [5]int{1, 2, 3, 4, 5}
	for i, v := range arr {
		fmt.Println(i, v)
	}
}
```

```
0 1
1 2
2 3
3 4
4 5
```

#### 6.1.2 切片

Go 中数组与切片的关系，有点类似与 Js 中 `ArrayBuffer` 和 `TypedArray` 的关系。

在 Go 中，切片是对其底层数组某一段的引用。它的类型声明如下：

```go
[]valueType
```

##### 切片的创建

###### 对数组切片

切片通过 `arr[low : high]` 的语法来获得对底层数组某一段的**引用**；对的，*切片是引用类型*；当我们改变其中一个切片的某下标，其他和它共享同一底层数组的切片都能观察到更改，因为它们是对同一块数组的内存空间的引用。

`arr[low : high]` 语法可以省略 `low` 和 `high`，`low` 的默认值是 `0`、`high` 的默认值是 `len(arr)`

```go
func main() {
	arr := [5]int{1, 2, 3, 4, 5}
	s1 := arr[1:3]
	s2 := arr[:3]
	s3 := arr[3:]
	s4 := arr[:]

	printAll := func(msg string) {
		fmt.Println(msg)
		fmt.Println(arr)
		fmt.Println(s1)
		fmt.Println(s2)
		fmt.Println(s3)
		fmt.Println(s4)
		fmt.Println("")
	}

	printAll("未更改")
	s1[0] = 1002
	printAll("s1[0] = 1002 后")
}
```

```
未更改
[1 2 3 4 5]
[2 3]
[1 2 3]
[4 5]
[1 2 3 4 5]

s1[0] = 1002 后
[1 1002 3 4 5]
[1002 3]
[1 1002 3]
[4 5]
[1 1002 3 4 5]
```

###### 对切片切片

`[low : high]` 除了作用于数组，还可以作用于切片。作用于切片时，实际上切的还是该切片的底层数组，相当于对相同底层数组进行了两次分步切片；在下面的例子中，先是切出 `[1:4]` 这一个片段，然后在切出的这个局部片段基础上再切出 `[0:2]` 片段；二者叠加，相当于最后切出了底层数组 `[1:3]` 这个片段。

`s[low : high]` 语法也可以省略 `low` 和 `high`，`low` 的默认值为 `0`、`high` 的默认值为 `len(s)` 而不是 `cap(s)`

```go
func main() {
	arr := [5]int{1, 2, 3, 4, 5}
	s1 := arr[1:4]
	s2 := s1[0:2]
	printAll := func(msg string) {
		fmt.Println(msg)
		fmt.Println(arr)
		fmt.Println(s1)
		fmt.Println(s2)
		fmt.Println("")
	}
	printAll("未改变")
	s2[0] = 100
	printAll("改变 s2[0]=100")
}
```

```
未改变
[1 2 3 4 5]
[2 3 4]
[2 3]

改变 s2[0]=100
[1 100 3 4 5]
[100 3 4]
[100 3]
```

###### 6.2 切片字面量

除了可以通过对现有数组执行切片操作来获取切片，我们还可以直接创建切片字面量：

```go
s := []int{1, 2, 3}
```

这将创建一个长度为 3 的数组，然后对他进行 `[:]` 切片，最后返回这个切片给 `s`。

另外，由于切片是引用类型，所以如果声明了切片类型的变量而不赋值，那么将默认被赋零值；而引用类型的零值是 `nil`，所以声明但没赋值的切片类型变量的值为 `nil`。

```go
var s []int
if s == nil {
	fmt.Println("nil")
}
// 输出: nil
```

###### 切片的长度与容量

对于一个切片 `s`，通过 `len(s)` 可以获得它的长度，通过 `cap(s)` 可以获得它的容量。

切片的长度就是 `[low : high]` 中的 `high - low`，即它所包含的元素的个数；
切片的容量是从它的第一个元素开始，到它的底层数组的最后一个元素的个数。

```go
func main() {
	arr := [5]int{1, 2, 3, 4, 5}
	s := arr[:3]
	fmt.Println("arr", arr)
	fmt.Println("s", s)
	fmt.Println("len", len(s))
	fmt.Println("cap", cap(s))
}
```

```
arr [1 2 3 4 5]
s [1 2 3]
len 3
cap 5
```

我们也可以通过对一个切片执行超出其长度的切片，以拓展这个切片的长度；这叫做重新切片。
在下面的例子中，如果执行 `s[:]`，那其实是执行 `s[0:len(s)]`；但执行 `s[:cap(s)]` 则是 `s[0:cap(s)]`，这就实现了对原有切片的拓展。

```go
func Reslice() {
	arr := [...]int{1, 2, 3, 4, 5}
	info(arr)

	s := arr[:2]
	info(s)

	s = s[:cap(s)]
	info(s)
}
```

```
arr:    [1 2 3 4 5] len: 5
slice:  [1 2] len: 2 cap: 5
slice:  [1 2 3 4 5] len: 5 cap: 5
```

但有一点需要注意，就是切片只能向后拓展；`s = s[-1:]` 的语法是不支持的。

###### 使用 `make` 创建切片

`make` 函数是 Go 用于创建并初始化引用类型的内建函数，支持创建切片、映射和信道。

创建一个长度为 `3`，容量为 `5` 的 `int` 切片：

```go
s := make([]int, 3, 5)
```

这行代码会创建一个长度为 `5` 的底层数组，然后把数组的前三个元素置零 (对于 `int` 类型来说，是赋值为 `0`)，最后返回对这前三个元素的切片给 `s`。

当然，也可以省略第三个参数；此时，创建出的切片 `len` 和 `cap` 相同。

##### 使用 `append` 向切片增加元素

使用 `append` 可以向切片末尾增加一个新元素；它接收一个切片和若干个待 `push` 的元素，然后**返回**一个 `push` 后的**新切片**，**原切片保持不变**。

对于 `append` 拓展切片容量的具体操作，如下所示：
1. 如果底层数组还有空间，即 `cap(s) > len(s)`，那就往后拓展一个下标的切片，然后给这个下标赋值；从下面代码中可以看到，这时候底层数组也是同步改变的。
2. 如果底层数组没有空间，即 `cap(s) = len(s)`，那就新分配一个长度更长的数组 (一般是原数组长度的两倍) 作为新切片的底层数组，把原切片的内容复制到这个新数组中，然后就和上面一样，往后拓展一个下标的切片，赋值，最后返回这段切片；原切片保持不变且还是引用的原数组，原数组也保持不变。

```go
func Push() {
	arr := [5]int{0}
	s1 := arr[:3]
	info(arr)
	info(s1)
	fmt.Println("============================")
	s2 := append(s1, 1)
	info(arr)
	info(s1)
	info(s2)
	fmt.Println("============================")
	s3 := append(s2, 2)
	info(arr)
	info(s3)
	fmt.Println("============================")
	s4 := append(s3, 3)
	info(arr)
	info(s4)
}
```

```
arr:    [0 0 0 0 0]   len: 5
slice:  [0 0 0]       len: 3 cap: 5
============================
arr:    [0 0 0 1 0]   len: 5
slice:  [0 0 0]       len: 3 cap: 5
slice:  [0 0 0 1]     len: 4 cap: 5
============================
arr:    [0 0 0 1 2]   len: 5
slice:  [0 0 0 1 2]   len: 5 cap: 5
============================
arr:    [0 0 0 1 2]   len: 5
slice:  [0 0 0 1 2 3] len: 6 cap: 10
```

当然，`append()` 也可以一次 `append` 多个元素，例如 `append(s, e1, e2, e3, ...)` 效果相当于多次调用 `append(s, en)`；这里不再演示。

> [!info]
> Go 中对切片的操作只提供了 `append` 一个内置函数，也就是只有 `push` 功能，而 `pop` `shift` `unshift` `delete` 等功能都需要我们手动实现。
> 
> 当然，在 `Go1.21` 版本后，引入了 `slices` 用于拓展对切片的操作，里面倒是多了很多操作切片的实用操作。

##### for range 遍历切片

```go
func main() {
	s := []string{"a", "b", "c", "d", "e", "f", "g"}
	for i, v := range s {
		fmt.Printf("index: %d, value: %s\n", i, v)
	}
}
```

```
index: 0, value: a
index: 1, value: b
index: 2, value: c
index: 3, value: d
index: 4, value: e
index: 5, value: f
index: 6, value: g
```

> [!warning] 下标访问越界问题
> 对于切片，越界访问会直接报运行时错误。
>  
> 对于切片，只要访问的下标大于或等于 `len(s)` 就算越界访问。

##### `slice` 只能与 `nil` 比较

理论上它是引用类型，可以比较它们的引用是否相同；但 Go 就是不让比较。

### 6.2 映射

映射允许我们创建键值对形式的复合值；它的类型声明如下：

```go
map[<keyType>]<valueType>
```

> [!quote] https://golang-china.github.io/gopl-zh/ch4/ch4-03.html
> 在 Go 语言中，一个 `map` 就是一个哈希表的引用，`map` 类型可以写为 `map[K]V`，其中 `K` 和 `V` 分别对应 key 和 value。
> 
> `map` 中所有的 key 都有相同的类型，所有的 value 也有着相同的类型，但是 key 和 value 之间可以是不同的数据类型。
> 
> 其中 `K` 对应的 key 必须是支持 `==` 比较运算符的数据类型，所以 map 可以通过测试 key 是否相等来判断是否已经存在。
> 虽然浮点数类型也是支持相等运算符比较的，但是将浮点数用做 key 类型则是一个坏的想法，正如第三章提到的，最坏的情况是可能出现的 `NaN` 和任何浮点数都不相等。
> 
> 对于 `V` 对应的 value 数据类型则没有任何的限制。

#### 6.2.1 映射的创建

##### 6.2.2 映射字面量

我们可以以字面量的形式创建映射

```go
func main() {
	mp := map[string]int{
		"one":   1,
		"two":   2,
		"three": 3,
	}
	fmt.Println(mp["one"]) // 1
}
```

映射是引用类型，拥有引用类型所拥有的特性，这里不再叙述。引用类型的零值是 `nil`，所以如果声明了一个映射但没有赋值，那么它的值将为 `nil`；`nil` 映射既没有键，也不能添加键。

```go
func main() {
	var mp map[string]int
	if mp == nil {
		fmt.Println("nil")
	}
}
// 输出 nil
```

##### 使用 `make` 创建映射

`make` 函数可以返回一个初始化后的映射，和 `nil` 映射不同，`make` 函数返回的映射可以直接使用 (向其添加元素)

```go
func main() {
	mp := make(map[string]int)
	mp["one"] = 1
	mp["two"] = 2
	fmt.Println(mp["one"])
}
```

#### 6.2.2 映射的操作

##### 添加或修改

```go
mp[key] = value
```

> [!warning]
> 不能对 `nil` 映射执行此操作

##### 6.2.3 获取元素

```go
ele := mp[key]
```

另外，还可以使用双赋值来检测某个键是否存在

```go
ele, ok = mp[key]
```

在这种情况下，如果键不存在，`ok` 将为 `false`；`ele` 将为值类型的零值。

```go
func main() {
	mp := map[string]int{"one": 1, "two": 2}
	one, oneExist := mp["one"]
	three, threeExist := mp["three"]
	fmt.Println(one, oneExist)
	fmt.Println(three, threeExist)
}
```

```
1 true
0 false
```

##### 删除元素

```go
delete(mp, key)
```

例子如下：

```go
func main() {
	mp := map[string]int{"one": 1, "two": 2}
	one, ok := mp["one"]
	fmt.Println(one, ok)
	delete(mp, "one")
	one, ok = mp["one"]
	fmt.Println(one, ok)
}
```

```
1 true
0 false
```

#### 6.2.3 `map` 只能与 `nil` 比较

理论上它是引用类型，可以比较它们的引用是否相同；但 Go 就是不让比较。

### 6.3 指针

Go 语言有指针类型，指针中保存了值的内存地址。

#### 6.3.1 指针类型声明

指针的类型声明如下：

```go
*<valueType>
```

例如，一个 `int` 类型的指针的类型为 `*int`

#### 6.3.2 指针的零值

指针类型的零值为 `nil`

如果声明了一个指针变量而不赋值，那么这个指针变量将持有指针类型的零值，即 `nil`。

#### 6.3.3 取地址与取值

`&` 运算符可以返回一个值的指针，
`*` 运算符则可以访问到指针指向的值；
这和 `C` 语言一样。

```go
a := 123
p := &a
fmt.Println(*p) // 123
```

与 `C` 语言不一样的是，Go 指针不能进行运算；也就是说，Go 中的指针只是用来实现引用的功能的。

#### 6.3.4 指针的比较

指针可以进行比较，当对两个指针进行比较时，比较的时它们的地址是否相同。

```go
a := 1
b := 2
p1 := &a
p2 := p1
p3 := &b
fmt.Println(p1 == p2)
fmt.Println(p1 == p3)
```

```
true
false
```

### 6.4 结构体

#### 6.4.1 结构体类型声明

结构体是对一系列不同类型的变量的聚合，每个被聚合进结构体的变量被称为结构体的成员变量；结构体的类型声明如下：

```go
struct{
	<MemberVar> <MemberType>
}
```

比如，

```go
struct{
	Name string
	Age int
}
```

像上面这种类型定义就能直接使用，就跟 `map[string]int` 一样，就是一个具体的类型；不过实际中，我们一般不这么用，而是用 `type` 定义一个结构体类型。

```go
type Stu struct{
	Name string
	Age int
}
```

然后用的时候直接用类型名 `Stu` 就行了。

这里可能会有一个疑问，就是为什么不用 `type =` 取别名，比如这样：

```go
type Stu = struct{
	Name string
	Age int
}
```

如果我再定义一个结构体就能很清楚的解释了：

```go
type Worker = struct{
	Name string
	Age int
}
```

在实际使用中，我们肯定期望 `Stu` 和 `Worker` 是不同的类型；但使用 `type =` 取别名的方式，如果两个结构体的成员刚好相同，那么它们就是同一个类型。
为了避免这种情况，使得每个定义出的结构体都是不同于其他结构体的新类型，我们就需要用 `type` 定义新类型而不是用 `type =` 取别名。

下面定义的两个类型就是不同的类型 (哪怕它们具有相同的结构体结构)

```go
type Stu struct{
	Name string
	Age int
}
type Worker struct{
	Name string
	Age int
}
```

#### 6.4.2 结构体成员访问控制

结构体成员变量的访问控制与全局变量的访问控制一样，都是大写字母开头表示这个变量是导出的，其他包可以访问；否则，其他包就访问不了。

#### 6.4.3 结构体的创建 (初始化) 与字段赋值

##### 按顺序给每个字段赋值

结构体创建时，可以使用“初始化列表” `{}` 按照顺序给每个字段初始化；
使用这种方式初始化时，各字段类型要按顺序和结构体声明时的一一对应，字段的数量也要和结构体声明的成员变量相等。

```go
type Stu struct {
	Name string
	Age  int
}

func main() {
	stu1 := Stu{"zhangsan", 18}
	fmt.Println("name:", stu1.Name, "age:", stu1.Age)
}
```

```
name: zhangsan age: 18
```

##### 按字段名给每个字段赋值

我们也可以在初始化时指定我们要赋值的成员变量的名字；这种情况下，“初始化列表”中可以不用包含所有成员的初值，没有初值的成员将持零值。

```go
type Stu struct {
	Name string
	Age  int
}

func main() {
	stu1 := Stu{Age: 18}
	fmt.Println(
		"name:",
		func() string {
			if stu1.Name == "" {
				return `""`
			}
			return stu1.Name
		}(),
		"age:", stu1.Age,
	)
}
```

```
name: "" age: 18
```

##### 先创建后访问成员赋值

我们也可以不在初始化的时候给结构体成员变量赋值，这时，所有成员将持有其类型的零值 (`0`、`""`、`false` 或 `nil`)；等之后在通过访问成员的方式赋值。

```go
type Stu struct {
	Name string
	Age  int
}

func main() {
	stu1 := Stu{}
	fmt.Println(stu1)
	stu1.Name = "zhangsan"
	stu1.Age = 18
	fmt.Println(stu1)
}
```

```
{ 0}
{zhangsan 18}
```

#### 6.4.4 结构体成员访问

使用 `.` 点号来访问结构体的成员，这个没啥好说的。

##### 结构体指针的隐式解引用

访问一个结构体指针 `p` 的成员，我们可以使用 `(*p).MemberName`；也可以直接用 `p.MemberName` 来访问，这算是一个语法糖，类似 C 的 `p->MemberName`。

```go
type Stu struct {
	Name string
	Age  int
}

func main() {
	p := &Stu{"zhangsan", 18}
	fmt.Println(p.Name) // zhangsan
}
```

#### 6.4.5 结构体是值类型

这个倒是和 C 语言是一样的，结构体是值类型；当进行赋值等操作时，是值传递，会发生值的复制。

```go
type Stu struct {
	Name string
	Age  int
}

func main() {
	stu1 := Stu{"zhangsan", 18}
	stu2 := stu1
	stu1.Name = "lisi"
	fmt.Println(stu1, stu2)
}
```

```
{lisi 18} {zhangsan 18}
```

#### 6.4.6 空结构体

> [!quote] 参考文章
> https://golang-china.github.io/gopl-zh/ch4/ch4-04.html

##### 空结构体不占用空间

如果声明一个没有任何字段的结构体类型，即空结构体。

空结构体的实例的大小为零，不保存任何信息；通过下面的例子可以看到，空结构体的实例比一个空指针占用的空间还小。

```go
func main() {
	var none struct{}
	var aNil *int
	var intStruct struct{ Age int }

	size_none := unsafe.Sizeof(none)
	size_nil := unsafe.Sizeof(aNil)
	size_intStruct := unsafe.Sizeof(intStruct)

	fmt.Println(none, aNil, intStruct)
	fmt.Println(size_none, size_nil, size_intStruct)
}
```

```
{} <nil> {0}
0    8    8
```

##### 利用 `map[T]struct{}` 手动实现集合 `set`

我们可以利用这个特性，通过把 `map` 类型的值“置空”的方法来模拟一个 `set` 集合。

比如这里我自己简单写了一个 `set`：

```go
package set

type set[T comparable] map[T]struct{}

func New[T comparable](elems ...T) set[T] {
	ret := make(set[T])
	for _, elem := range elems {
		ret[elem] = struct{}{}
	}
	return ret
}

func (s set[T]) Add(elem T) {
	s[elem] = struct{}{}
}

func (s set[T]) Remove(elem T) {
	delete(s, elem)
}

func (s set[T]) Has(elem T) bool {
	_, res := s[elem]
	return res
}
```

然后在 `main` 函数中调用：

```go
package main

import (
	"fmt"
	"nraintd/gogogo/set"
)

func main() {
	nums := set.New(1, 2, 3)
	nums.Add(4)
	fmt.Println(nums.Has(4))
	nums.Remove(4)
	fmt.Println(nums.Has(4))
}
```

```
true
false
```

#### 6.4.7 结构体的比较

如果一个结构体的所有成员都是可比较的，那么这个结构体就是可以比较的，可以用 `==` `!=` 运算符进行比较。

> [!tip]
> 可比较的结构体可以作为一个映射的键

```go
type Stu struct {
	Name string
	Age  int
}

func main() {
	stu1 := Stu{"zhangsan", 18}
	stu2 := Stu{"lisi", 19}
	stu3 := Stu{"zhangsan", 18}
	fmt.Println(stu1 == stu2) // false
	fmt.Println(stu1 == stu3) // true
}
```

#### 6.4.8 匿名成员和结构体嵌入

> [!quote] 参考文章
> https://golang-china.github.io/gopl-zh/ch4/ch4-04.html
> 
> 他这篇文章举的是描述图形的结构体的例子，我感觉不过描述人的结构体直观 (主要是很多单词不认识)，所以我另造了一个例子。

##### 引入

我们考虑有 `Stu` `Teac` `Worker` 来表示学生、老师、职工，那么我们可能会声明下面三个结构体：

```go
type Stu struct {
	Name string
	Age  int
	Cls  int
}

type Teac struct {
	Name    string
	Age     int
	Subject string
}

type Worker struct {
	Name string
	Age  int
	Work string
}
```

我们发现他们都有相同的字段 `Name` 和 `Age`，于是把这两字段提出来，定义了 `Person`；然后在每个身份的结构体中都删掉 `Name` 和 `Age`，添加 `BaseInfo` 字段。

```go
type Person struct {
	Name string
	Age  int
}

type Stu struct {
	BaseInfo Person
	Cls      int
}

type Teac struct {
	BaseInfo Person
	Subject  string
}

type Worker struct {
	BaseInfo Person
	Work     string
}
```

但这有个问题，就是每次访问 `Name` 和 `Age` 都需要多一层 `BaseInfo` 访问，比如 `stu.BaseInfo.Name`，很麻烦。

这里我们可以这样解决 (如下面代码所示)，代码中，我们把每个结构体的 `BaseInfo` 字段的字段名去掉，只保留了类型，这就构成了匿名字段；而匿名字段的类型是结构体，就发生了结构体嵌入：即匿名字段的成员通过包含匿名字段的结构体就能直接访问到。
这样一来，我们就可以直接以 `stu.Name` 的形式访问 `Person` 的成员，而不用多访问一层 `stu.BaseInfo.Name`。

```go
type Person struct {
	Name string
	Age  int
}

type Stu struct {
	Person
	Cls int
}

type Teac struct {
	Person
	Subject string
}

type Worker struct {
	Person
	Work string
}

func main() {
	stu := Stu{
		Person{"zhangsan", 18},
		1,
	}
	fmt.Println(stu.Name, stu.Person.Age, stu.Cls)
}
```

当然，如果想多访问一层也是可以的，只要把类型名当字段名访问即可 (`stu.Person.Age`)。

##### 匿名成员

上面提到了匿名成员，这里我们再界定一下概念。

简单来说，如果我们有一个命名类型 (使用 `type` 声明的类型；内置类型也是命名类型，因为源码写了 `type int int`；但像切片、映射、结构体字面类型这些需要现场构造类型的类型不属于，不过以它们为基础类型 `type` 后的类型属于)，然后我们在声明一个结构体的成员时，不指定成员名，直接填类型或类型的指针，这就是一个匿名成员。

对于匿名成员，我们能直接以类型名来访问这个成员。

```go
type Test struct {
	int
	Name string
}

func main() {
	test := Test{int: 1, Name: "zhangsan"}
	fmt.Println(test.int, test.Name)
}
```

```
1 zhangsan
```

##### 结构体嵌入 (字段提升)

如果一个匿名成员 `Kind` 是结构体类型，那么就可以触发字段提升特性：即这个匿名成员的字段可以被直接嵌入 (提升) 到外层结构体，使得可以直接通过外层结构体访问到这个匿名成员的字段。

例子在上面引入的时候已经讲过，这里就省略了。

##### 方法提升

如果匿名成员对应的类型有定义方法，那么方法也会被提升到外层结构体。

也就是说，能够直接通过外层结构体访问到匿名成员的方法。

```go
type Person struct {
	Name string
	Age  int
}

func (p Person) Show() {
	fmt.Printf(
		"Name: %s, Age: %d\n",
		p.Name, p.Age,
	)
}

func (p *Person) SetAge(age int) {
	p.Age = age
}

type Stu struct {
	Person
	Cls int
}

func main() {
	stu := Stu{Person{"zhangsan", 18}, 1}
	stu.Show()
	stu.SetAge(20)
	stu.Show()
}
```

```
Name: zhangsan, Age: 18
Name: zhangsan, Age: 20
```

##### 普通匿名成员和指针匿名成员的区别

普通匿名成员和指针匿名成员之间的区别，和普通成员和指针成员的区别一样，没有什么特别的区别；说到这一步，有什么区别就是显然的了，不多讲了。

## 7 函数

### 7.1 函数声明

一个标准的函数声明长这样，包括函数名、形参列表、返回值列表以及函数体

```go
func name(paraList) (resList) { body }
```

### 7.2 参数列表

#### 7.2.1 基本语法

函数的参数列表以逗号分隔，每一个参数以空格分隔形参名和形参类型

```go
func add(x int, y int) int { return x + y }
```

如果多项形参类型相同，也可以只写一次

```go
func add(x, y int) int { return x + y }
```

```go
func f(a, b int, c, d string) { /** **/ }
```

#### 7.2.2 可变参数

Go 的参数列表的**最后一项**，可以写**一个**变长参数，表示变长参数的类型用 `...T` 表示。

```go
func sum(des string, nums ...int) {
	sum := 0
	for _, num := range nums {
		sum += num
	}
	fmt.Println(des, sum)
}

func main() {
	sum("1+2+3+4+5 =", 1, 2, 3, 4, 5)
}
// 1+2+3+4+5 = 15
```

在函数体中，`...T` 类型的形参实际上是 `[]T` 类型的切片；在上面的例子中，`nums` 的在函数体中的实际类型其实是 `[]int`。

从前面的叙述看起来，可变参数貌似只是变长参数，不同时支持任意数量、任意类型的参数；但通过 `interface{}` 空接口，我们就能够实现真正的可变参数。

```go
func sum(nums ...interface{}) float64 {
	var sum float64
	for _, num := range nums {
		switch n := num.(type) {
		case int:
			sum += float64(n)
		case float64:
			sum += n
		default:
			sum += 0
		}
	}
	return sum
}

func main() {
	fmt.Println(sum(1, 1.1, "0.1"))
}
// 2.1
```

当然，也可以不用空接口，而是用泛型：

```go
func sum[T constraints.Integer | constraints.Float](nums ...T) float64 {
	var sum float64
	for _, num := range nums {
		sum += float64(num)
	}
	return sum
}

func main() {
	fmt.Println(sum(1, 1.1))
}
// 2.1
```

### 7.3 返回值列表

如果一个函数没有返回值，则可以不写返回值列表；
如果一个函数只有一个返回值，在 `()` 后面直接写返回值类型即可。

```go
func hello() { fmt.Println("hello") }
```

```go
func add(x, y int) int { return x + y }
```

#### 7.3.1 多返回值

Go 中，也支持多个返回值。

```go
func check(msg string) (string, bool) {
	if (msg == "xxx") { return "", false }
	return msg, true
}

func main() {
	msg, ok := check("yyy")
	fmt.Println(msg, ok)
	msg2, ok2 := check("xxx")
	fmt.Println(msg2, ok2)
}
```

```
yyy true
 false
```

#### 7.3.2 命名返回值

Go 中，返回值也可以有名字；如果一个返回值有名字，那么所有返回值都必须有名字。
当使用命名返回值时，`return` 时可以省略返回值，这时候将返回 `return` 时命名返回值变量的值。

```go
func parseCplx(cplx complex128) (rl, img float64) {
	rl = real(cplx)
	img = imag(cplx)
	return
}

func main() {
	a, b := parseCplx(1 + 2i)
	fmt.Println(a, b)
}
```

命名返回值，其实就是相当于帮我们自动在函数开头声明好了对应的变量，然后我们使用空 `return` 时自动把那些变量当作返回值而已；就是个语法糖。

我们也可以最后不返回命名返回值变量，而是返回其他值。

```go
func test(x int) (y int) {
	y = x + 1
	return x - 1
}

func main() {
	fmt.Println(test(1)) // 0
}
```

上面的例子将返回 `0` 而不是 `2`；
这时候，其实可以理解为把 `x - 1` 赋值给 `y`，再返回 `y`；即下面这样的逻辑：

```go
func test(x int) (y int) {
	y = x + 1
	// return x - 1 相当于下面两行
	y = x - 1
	return y
}
```

### 7.4 匿名函数

匿名函数是一个值，它可以被赋值给变量，可以作为另一个函数的实参被传递；当然，作为一个函数，它也可以被调用。

当我们去掉一个函数声明 (只能在全局作用域声明) 的函数名后，它就变成了一个函数字面量；函数字面量是一个表达式，它的结果就是匿名函数。

```go
func main() {
	say := func(msg string) {
		fmt.Println(msg)
	}
	say("hello")
}
```

事实上，函数也是一种数据类型；和 `map` 等符合类型一样，它也是需要实时构造的类型，而不是像 `int` 那样预定义的。

不过，用于区分两个函数类型是否相同的依据只有两个：参数列表类型和返回值列表类型；而它们的名字是不被关心的，可以不同。

```go
func main() {
	var genMsg func(msg string) (newMsg string)

	genMsg = func(msg string) (newMsg string) {
		newMsg = msg
		return
	}
	println(genMsg("hello"))

	genMsg = func(mg string) (nM string) {
		nM = mg + " received"
		return
	}
	println(genMsg("hello"))
}
```

### 7.5 闭包

Go 中的函数也有闭包的特性，即一个函数可以访问其定义处的外部变量。

不太好描述，但这也不是什么新奇的特性了，`js` `py` 都有，就不说了；这里以一个例子来描述：

```go
package main

import "fmt"

func main() {
	hello1 := createHello(1)
	for i := 0; i < 5; i++ {
		hello1()
	}

	fmt.Println("==============")
	
	hello2 := createHello(2)
	for i := 0; i < 5; i++ {
		hello2()
	}
}

func createHello(th int) func() {
	count := 0
	return func() {
		count++
		fmt.Printf("第 %d 次 hello%d\n", count, th)
	}
}

```

```
第 1 次 hello1
第 2 次 hello1
第 3 次 hello1
第 4 次 hello1
第 5 次 hello1
==============
第 1 次 hello2
第 2 次 hello2
第 3 次 hello2
第 4 次 hello2
第 5 次 hello2
```

但有一点需要强调，就是在 `js` 中，你可以看到这样的代码是允许的：

```js
function outer() {
  function inner() {
    console.log(info);
  }
  let info = 'Hello, World!';
  return inner;
}

const fn = outer();
fn();
```

上面代码中，`info` 变量声明在了 `inner` 函数之后，但 `inner` 函数依然可以通过闭包捕获它。

但在 Go 中，要想变量被闭包捕获，这个变量必须声明在匿名函数定义之前。

### 7.6 defer

#### 7.6.1 defer 的作用

在 Go 语言中，`defer` 可以起到一个延迟调用的作用；即跟在 `defer` 后面的函数调用会在函数 `return` 时执行。

一般来说，`defer` 有两个应用场景：资源释放和 `panic` 处理。

> [!note] 为什么 `defer` 适合资源释放和异常处理
> 我们知道，一个函数内如果某段代码触发了 `panic`，那么 `panic` 后面的代码都不会被执行了；
> 
> 但是 `defer` 有这样一个特性，就是被 `defer` 延迟调用的函数调用在 `panic` 触发后依然会被执行，这就保证了资源能够被正常释放；
> (`defer` 的底层原理暂时没搞清楚，之后我再去研究研究；现在知道它的行为就行了)
> 
> 而且在 `defer` 中可以调用 `recover` 去恢复 `panic`，Go 通过这种方式进行异常处理 (注意在 Go 中并不推荐把 `panic/recover` 当 `try{}catch{}` 用，正常的错误处理请用 `if err != nil` 来搞；`recover` 只是用来给空指针、数组越界访问、类型断言失败等会导致程序退出的 `panic` 兜底的)。

下面是一个模拟用 `defer` 做资源释放的例子；可以看到，即使因为切片越界访问触发了 `panic` 导致程序退出，`defer` 过的函数调用依然会被执行。

```go
func TestDefer() {
	defer func() {
		fmt.Println("清理资源")
	}()
	fmt.Println("开始执行 TestDefer")

	s := []int{1, 2, 3}
	fmt.Println(s[3]) // 越界访问，会触发 panic

	fmt.Println("这里不会执行")
}
```

```
开始执行 TestDefer
清理资源
panic: runtime error: index out of range [3] with length 3

goroutine 1 [running]:
nraintd/gogogo/funcLearn.TestDefer()
        C:/Users/baojy/Desktop/_try/go_try/funcLearn/deffer.go:12 +0x72
main.main()
        C:/Users/baojy/Desktop/_try/go_try/main.go:6 +0xf
exit status 2
```

至于 `defer` 用作 `recover` 一个 `panic` 的例子，我们等下一个大标题再讲。

#### 7.6.2 defer 的执行时机

Go 中的 `return` 其实不是原子操作，这里我们可以简单地把它分为两步：
1. 设置返回值
2. 返回返回值，回到函数调用处的下一个地址继续执行代码

而 `defer` 允许在上述那两步中间执行一个函数调用。

这时候，函数的 `return` 就分为了三步：
1. 设置返回值
2. 执行 `defer` 过的函数
3. 返回返回值

#### 7.6.3 defer 函数调用机制

`defer` 后面可以跟上一个函数调用语句，函数名和实参的计算会立刻进行，但等上述时机来临时函数才会被调用。

如果在一个函数中使用了多个 `defer`，那么执行顺序与写 `defer` 的顺序相反。

```go
func test() {
	defer func() {
		fmt.Println("defer1")
	}()
	defer func() {
		fmt.Println("defer2")
	}()
	fmt.Println("test")
}
```

```
test
defer2
defer1
```

#### 7.6.4 defer 易错例子

> [!quote]
> 下面看几个容易犯错的例子，摘自 [这篇文章](https://golangstar.cn/go_series/go_base/go_defer.html#defer%E4%B8%8Ereturn)

##### `defer` 函数调用实参的计算时机

```go
package main

import "fmt"


func deferRun() {
  var num = 1
  defer fmt.Printf("num is %d", num)
  
  num = 2
  return
}

func main(){
    deferRun()
}
```

```
num is 1
```

根据 [[#7.6.3 defer 函数调用机制]] 这个标题下所述，`defer` 后函数调用语句中的函数名和实参是在 `defer` 语句那行就立即计算的，所以当时 `num` 变量的值为 `1`，最后输出的是 `1`

再看一个对比例子

```go
package main

import "fmt"

func main() {
 deferRun()
}

func deferRun() {
 var arr = [4]int{1, 2, 3, 4}
 defer printArr(&arr)
 
 arr[0] = 100
 return
}

func printArr(arr *[4]int) {
 for i := range arr {
  fmt.Println(arr[i])
 }
}
```

```
100
2
3       
4
```

这个例子传的参数是指针，后面指针执行的值被改了 (`arr[0] = 100`)，等 `defer` 执行时根据指针访问的数据自然也是改过的数组。

##### defer 函数的闭包

```go
func main() {
	num := 1
	defer func() {
		fmt.Println(num)
	}()
	num++
}
```

```
2
```

上面代码中，`defer` 后调用的函数是直接定义在 `main` 函数中的，通过闭包捕获了 `main` 作用域的变量 `num`；接着 `num++` 被执行，`num` 的值变为了 `2`；再接着，`defer` 后的函数调用才被执行，此时函数内部访问 `num` 的值为 `2`，因此输出 `2`。

##### 命名返回值的计算时机

```go
package main

import "fmt"

func main() {
   res := deferRun()
   fmt.Println(res)
}

func deferRun() (res int) {
  num := 1
  
  defer func() {
    res++
  }()
  
  return num
}
```

```
2
```

根据 [[#7.6.2 defer 的执行时机]] 这个标题所叙述的：
这里，`return num` 相当于返回语句的第一步，将返回值 `res` 设置为了 `num` 的值，即 `1`；
接着，`defer` 过的函数调用被执行，重新将返回值变量 `res` 设置为 `2`(这里 `res` 一开始是零值 `0`)；
最后，返回返回值，所以是 `2`。

与之相比较的是这个例子：

```go
package main

import "fmt"

func main() {
    res := deferRun()
    fmt.Println(res)
}

func deferRun() int {
  num := 1
  defer func() {
    num++
  }()
  
  return num
}
```

```go
1
```

还是按照前面的思路分析，首先，设置返回值为 `num`，即 `1`；
然后，`defer` 执行，`num` 变为 `2`；
最后，返回设置好的返回值 `1`，这时已经和 `num` 变量没关系了。

### 7.7 异常

#### 7.7.1 认识 panic

在 Go 中，空指针、数组越界访问、类型断言失败等**运行时错误**发生时，会抛出 `panic` 异常；

> [!quote] 引用自 https://golang-china.github.io/gopl-zh/ch5/ch5-09.html
> 一般而言，当 `panic` 异常发生时，程序会中断运行，并立即执行在该 `goroutine` 中被延迟的函数 (`defer`)。
> 
> 随后，程序崩溃并输出日志信息。日志信息包括 `panic value` 和函数调用的堆栈跟踪信息。
> 
> `panic value` 通常是某种错误信息。
> 对于每个 `goroutine`，日志信息中都会有与之相对的，发生 `panic` 时的函数调用堆栈跟踪信息。

除了运行时错误导致的异常，我们也可以调用 `panic()` 函数手动触发异常，这个函数接收一个 `panic value` 作为参数，稍后我们会看到它的作用。

#### 7.7.2 异常日志信息

让我们故意构造一个切片越界访问的代码，让他运行时抛出 `panic`，然后看看都输出了哪些信息。

```go
func main() {
	s := []int{1, 2, 3}
	fmt.Println(s[3])
	fmt.Println("hello world")
}
```

可以看到，第一行输出了 `panic value`，即 `runtime error: index out of range [3] with length 3`；然后在下面输出了函数调用的堆栈跟踪信息。
并且，异常触发后，后面的代码都不会被执行。

```
panic: runtime error: index out of range [3] with length 3

goroutine 1 [running]:
main.main()
        C:/Users/baojy/Desktop/_try/go_try/main.go:7 +0x15
exit status 2
```

现在，我们调用 `panic` 函数手动抛出异常，传入 `"自定义的异常"` 作为参数。

```go
package main

func main() {
	panic("自定义的异常")
	fmt.Println("hello world")
}
```

可以看到，第一行输出了我们 `"自定义的异常"` 的 `panic value`。
同样，`panic` 后面的代码不会被执行。

```
panic: 自定义的异常

goroutine 1 [running]:
main.main()
        C:/Users/baojy/Desktop/_try/go_try/main.go:4 +0x25
exit status 2
```

#### 7.7.3 用 defer 和 recover 捕获并恢复 panic

在 [[#7.7.1 认识 panic]] 这个标题下，我们说了，发生 `panic` 后，该 `goroutine` 中被 `defer` 的函数调用会立即执行；因此，我们可以在 `defer` 中写 `recover` 来恢复异常。

在其他地方写 `recover` 是没有用的，毕竟 `panic` 后面的代码都不会被执行，只有 `defer` 是特殊的。

下面的例子演示了使用 `recover` 来恢复 `panic`；在 `defer` 中调用 `recover` 可以将程序从 `panic` 中恢复并拿到 `panic value`(注意这里不能拿到函数调用的堆栈跟踪信息)

```go
func main() {
	testRecover()
	fmt.Println("成功恢复")
}

func testRecover() {
	defer func() {
		if r := recover(); r != nil {
			fmt.Println("发生了异常，panic value 为:")
			fmt.Println(r)
		}
	}()
	s := []int{1, 2, 3}
	fmt.Println(s[3])
	fmt.Println("这个不会被执行")
}
```

```
发生了异常，panic value 为:
runtime error: index out of range [3] with length 3
成功恢复
```

#### 7.7.4 panic 的传递

当触发了 `panic` 时，如果当前函数中没有 `recover` 的 `defer`，那么这个 `panic` 就会向外层函数“抛出”；如果外层函数也没有 `recover`，那么这个 `panic` 就会继续向外层函数传递，知道遇到了 `recover` 把它恢复为止。
如果一直没有 `recover`，那么 `panic` 最终将导致程序崩溃。

下面以一个例子来演示 `panic` 的传递过程 ([参考文章](https://golangstar.cn/go_series/go_base/go_exception.html#panic%E4%BC%A0%E9%80%92))

```go
package panicLearn

import "fmt"

func testPanic1() {
	fmt.Println("testPanic1上半部分")
	testPanic2()
	fmt.Println("testPanic1下半部分")
}

func testPanic2() {
	defer func() {
		recover()
	}()
	fmt.Println("testPanic2上半部分")
	testPanic3()
	fmt.Println("testPanic2下半部分")
}

func testPanic3() {
	fmt.Println("testPanic3上半部分")
	panic("在testPanic3出现了panic")
	fmt.Println("testPanic3下半部分")
}

func Trans() {
	fmt.Println("程序开始")
	testPanic1()
	fmt.Println("程序结束")
}
```

```
程序开始
testPanic1上半部分
testPanic2上半部分
testPanic3上半部分
testPanic1下半部分
程序结束
```

## 8 方法

### 8.1 概述

提到方法，我们很容易想到面向对象那套，想到类。

但 Go 中没有类，不过我们可以通过给函数添加接收者参数来给类型定义自己的方法。

我们通过给一个函数添加接收者参数 (一个带有接收者名字 (函数内部使用) 和接收者类型 (用于把方法绑定到类型上) 的形参)，让它成为某个类型的方法；接着，我们就可以在该类型的变量上以 `v.Method()` 的方式调用这个方法了。使用这种方式调用，`v` 会自动作为实参被传递给接收者参数，就像普通实参传递给普通参数一样。

综上，Go 中的方法其实就是带有接收者参数的函数而已。

### 8.2 例子

下面我们看一个例子，代码中，我们为 `Person` 类型声明了一个方法 `Introduce`，这个方法内部输出了 `Person` 结构体的一些信息；
接着，我们对 `Person` 的实例 `pp` 调用这个方法，即 `pp.Introduce()`；
这个过程其实就是把 `pp` 变量当作方法的接收者参数 `(p Person)`，通过拷贝的方式 (和正常实参传递给形参一样) 把实参 `pp` 的值拷贝给形参 `p`，然后方法内部就能使用它了。

```go
package main

import "fmt"

type Person struct {
	Name string
	Age  int
}

func (p Person) Introduce() {
	fmt.Printf("我的名字是%s，今年 %d 岁\n", p.Name, p.Age)
}

func main() {
	pp := Person{"张三", 18}
	pp.Introduce()
}
```

```
我的名字是张三，今年 18 岁
```

除了结构体，我们也可以给普通类型定义方法

```go
type myInt int

func (n myInt) ToString() string {
	return strconv.Itoa(int(n))
}

func main() {
	n := myInt(10)
	var s string = n.ToString()
	fmt.Println(s)
}
```

### 8.3 只能给本地类型定义方法

所谓本地类型，就是在同一个包内声明的类型；
内置类型、其他包定义的类型都不属于本地类型。

在 Go 中，我们只能给本地类型定义方法，即只能给自己包内声明的类型定义方法，不能给内置类型和其他包中声明的类型定义方法。

这也算是一个约束吧，防止莫名奇妙的方法到处定义。

### 8.4 方法值和方法表达式

在下面的例子中，我们使用 `p.Introduce` *“选择器”* 把 `p` 实例绑定到了方法 `Introduce` 上，生成了一个函数并返回给 `pIntroduce` 变量；在这个过程中，生成的函数就是一个方法值，一个绑定了接收者参数的方法生成的函数。
然后，我们使用 `Person.Introduce` 方法表达式通过类型访问到了这个类型的方法，然后返回了一个没有绑定接收者参数的函数 `PersonIntroduce`；这个函数将把原来方法的接收者参数移动到普通参数列表的第一个形参处，待调用时提供。
代码中，`pIntroduce` 和 `PersonIntroduce` 的类型分别为 `func()` 和 `func(Person)`。

```go
type Person struct {
	Name string
	Age  int
}

func (p Person) Introduce() {
	fmt.Printf("我的名字是%s，今年 %d 岁\n", p.Name, p.Age)
}

func main() {
	p := Person{"张三", 18}
	pIntroduce := p.Introduce
	PersonIntroduce := Person.Introduce
	pIntroduce()
	PersonIntroduce(p)
}
```

### 8.5 指针类型的接收者

#### 8.5.1 引入

有时候，我们期望方法能够改变其接收者的内容。

比如对于结构体 `Person`，我们希望有一个方法 `Rename` 能改变它的 `Name` 字段，于是我们这样写：

```go
type Person struct {
	Name string
	Age  int
}

func (p Person) Introduce() {
	fmt.Printf("我的名字是%s，今年 %d 岁\n", p.Name, p.Age)
}

func (p Person) Rename(name string) {
	p.Name = name
}

func main() {
	pp := Person{"张三", 18}
	pp.Introduce()
	pp.Rename("李四")
	pp.Introduce()
}
```

```
我的名字是张三，今年 18 岁
我的名字是张三，今年 18 岁
```

运行程序，会发现 `pp` 的 `Name` 并没有被改变，这是因为 `(p Person)` 接收者参数跟普通参数一样，会把实参 `pp` 的内容赋值一份到 `p` 形参中，所以改变的是副本的 `Name` 而非 `pp` 的 `Name`。

为了能改变原本的接收者实例 `pp` 的内容，我们需要把接收者参数声明为指针：

```go
func (p *Person) Rename(name string) {
	p.Name = name
}
```

只需要改这一处，再次运行，会发现 `pp.Name` 被成功修改了。

```
我的名字是张三，今年 18 岁
我的名字是李四，今年 18 岁
```

#### 8.5.2 方法与指针重定向

在上面的例子中，我们只改了接收者参数为指针，但 `pp` 还是一个 `Person` 类型，而不是 `*Person` 类型；但程序却能正常运行。

这是因为对于 `pp.Rename()`，Go 可以自动解释为 `(&pp).Rename()`，即自动取地址。

同样，对于下面接收者参数为普通的 `p Person` 的方法，我们也可以通过类型为 `*Person` 的指针 `point` 直接用 `point.Introduce()` 的形式访问，Go 会自动帮我们解释为 `(*point).Introduce()`，就像通过指针能直接访问结构体成员一样。

```go
func (p Person) Introduce() {
	fmt.Printf("我的名字是%s，今年 %d 岁\n", p.Name, p.Age)
}

func main() {
	point := &Person{"张三", 18}
	point.Introduce()
}
```

> [!warning]
> 注意，对于方法表达式，即直接从类型访问方法来说，是没有指针重定向的。
> 例如，对于 `func (x *MyType) Xxx()` 来说，使用方法表达式得用 `(*MyType).Xxx` 的形式，`MyType.Xxx` 是无效的。

#### 8.5.3 如何选择?

一般来说，如果我们希望方法能改变接收者的值，我们会选择使用指针接收者；否则一般用普通接收者。

不过，当我们的接收者类型占用空间特别大时 (比如一个很大的结构体)，为了避免因为拷贝而造成的性能损耗，我们也会使用指针接收者，即使我们不改变接收者的值。

## 9 接口

### 9.1 引入

在其他编程语言中，接口是从抽象基类中引申出来的概念，我个人感觉就是抽象基类的语法糖，稍微拓展了一些它们的功能 (比如可以实现多个接口但不能继承多个抽象基类 (cpp 可以))；
它定义了一组方法却不实现它们，由 `implements` 它的类去实现；所有实现了某接口的类的实例都能直接赋值给某接口类型的变量，以此实现多态。

### 9.2 接口及其隐式实现

在 Go 中，接口的作用也是差不多的：
一个接口定义了一些没有实现只有签名的方法，只要一个类型实现了所有这些方法，那么这个类型的变量就可以直接赋值给这个接口类型的变量。
从上面的论述中我们也可以看出一点，就是 Go 的接口是隐式实现的，不需要 `implements` 去显式声明某类型属于某接口。

当把一个实现了某个接口的类型的变量赋值给某个接口类型的变量后，就可以通过接口变量直接调用接口中的方法，然后会去接口变量中保存的具体类型那去找到具体的方法实现。

### 9.3 细节

#### 9.3.1 接口中方法只需方法名、参数和返回值列表

很明显，我们在一个接口中声明方法时，这个方法的接收者是未知的。
或者说，只要实现了方法名、参数和返回值列表都和接口中声明的方法一样的方法，那么就可以认为一个类型实现了接口中这一个方法；在这种情况下，接口中不用写接收者参数是显然的；
而不写 `func` 关键字则是没有必要写。

```go
type Stu struct {
	Name   string
	Gender string
}

func (s *Stu) Info(field string) string {
	switch field {
	case "Name":
		return s.Name
	case "Gender":
		return s.Gender
	default:
		return ""
	}
}

type Person interface {
	Info(field string) string
}

func main() {
	stuPoint := &Stu{"张三", "男"}
	var p Person = stuPoint
	fmt.Println(p.Info("Name"))
}
```

#### 9.3.2 接口没有指针重定向

注意看上面的例子，我们给类型 `Stu` 实现的方法 `Info` 中，其接收者参数是 `(s *Stu)`；那么就只要 `*Stu` 类型的参数可以赋值给 `Person` 类型的接口。`Stu` 非指针类型的变量是不能的，因为没有接收者参数为 `(s Stu)` 的方法实现，它是不会自动把 `var p Person = stu` 转成 `var p Person = &stu` 的。

其实也好记，Go 对指针的自动转换基本只和 `.` 号有关，及 `v.Xxx()` => `(&v).Xxx()` 或 `p.Xxx` => `（*p).Xxx`。也即是它们**只是自动转换**，是语法糖。而对于接口这一块没有这种语法糖而已。

### 9.4 接口值

#### 9.4.1 接口值的底层结构

前面说过，接口是一种类型；接口类型的变量存储的是接口值。

> [!quote] https://tour.go-zh.org/methods/11
> 在内部，接口值可以看做包含值和具体类型的元组
> 
> 接口值保存了一个具体底层类型的具体值。
> 
> 接口值调用方法时会执行其底层类型的同名方法。

```go
(value, type)
```

#### 9.4.2 存有 nil 底层值的接口和 nil 接口

我们知道，对于引用类型 (指针、切片、映射、信道)，其零值为 nil。
如果我们有一个以这些引用类型为底层类型的类型，然后这个类型实现了一个接口；那么如果这个类型的变量为 `nil`，也是可以赋值给那个接口类型的变量的；这时候，接口内部值的部分存储 `nil`，但接口本身不是 `nil`(因为接口中还存储了类型信息)。

并且，存有 `nil` 底层值的接口，也是可以调用方法的。这时候，`nil` 值讲作为接收者参数被传入，然后方法实现中需要处理 `nil` 的情况，否则可能报错。(这里就算不用接口，直接用某类型存有 `nil` 的变量调用方法也会有这种问题)

比如下面的例子，就会输出 `nil`；如果去掉 `func (s *Stu) Introduce()` 实现中的 `if s == nil`，那对 `nil` 访问 `Name` 字段就会 `panic`

```go
type Stu struct {
	Name   string
	Gender string
}

func (s *Stu) Introduce() {
	if s == nil {
		fmt.Println("nil")
	} else {
		fmt.Println("I am a student, my name is ", s.Name)
	}
}

type Introducer interface {
	Introduce()
}

func main() {
	var s *Stu
	var i Introducer = s
	i.Introduce()
}
```

接口其实是引用类型，声明了但没有赋值的接口持有引用类型的零值 `nil`，这表示接口本身是 `nil`，没有 `(value,type)` 结构。
对 `nil` 接口调用方法会 `panic`，因为无法通过一个没有记录 `type` 的接口定位到具体类型的方法实现；下面的代码，如果没有 `p != nil` 的判断，将会 `panic`。

```go
package main

type Introducer interface {
	Introduce()
}

func main() {
	var p Introducer
	if p != nil {
		p.Introduce()
	}
}
```

### 9.5 空接口

没有定义任何方法的接口我们称之为空接口，即 `interface{}` 类型。

空接口类型的变量可以被赋值为任何类型的值，因为任何类型都实现了空接口 (最差的情况下，一个类型可以一个方法也没实现；而空接口里面刚好只有零个方法，可以被任何类型实现)

正如前面 [[#7.2.2 可变参数]] 一节讲过，一个变长参数如果是 `...interface{}` 类型的，那么就可以成为可变参数。Go 中正是借助空接口实现的可变参数，而不是用某些单独的语法。

#### 9.5.1 类型断言

利用接口接收到任意类型的值后，我们该如何用这些值呢？答案是从接口中取出具体类型的值。
Go 是静态类型的语言，我们对一个变量赋值的时候就一定要知道用来赋值的东西的具体的类型；所以从接口中取出具体值也得知道接口中存储的是什么类型的值。

Go 使用类型断言的语法来完成上述操作。

```go
func main() {
	var i interface{} = 123
	num := i.(int)
	fmt.Println(num + 1)
}
```

上面的例子中，使用 `i.(int)` 类型断言从存储有 `int` 类型值的接口 `i` 中取出 `int` 值并赋值给 `num`。使用这种方法，如果断言不对，比如上面写的是 `i.(float64)`，就会触发 `panic`。

但类型断言支持返回两个值，一个是断言出的值，另一个是断言结果 (`bool` 类型)；
如果断言成功，前者将被赋值为断言出的类型的值，后者将为 `true`；
如果断言失败，前者将被赋值为断言类型的零值，后者将为 `false`;

```go
func main() {
	var i interface{} = 123

	if num, ok := i.(int); ok {
		fmt.Println(num, ok)
	}

	num, ok := i.(float64)
	fmt.Println(num, ok)
}
```

```
123 true
0 false
```

> [!tip]
> 通过类型断言从接口中取出对应类型的值然后赋值给另一个变量的操作，和直接把一个变量赋值给另一个变量一样，都是赋值语义，会拷贝变量中的内容 (如果是引用类型就是拷贝的引用，还是属于内容)。

#### 9.5.2 类型选择

类型选择其实就是一种语法糖，把我们用 `if else` 手动判断某种类型是否 `ok` 的逻辑简化了而已。

```go
func main() {
	var i interface{} = 123

	switch num := i.(type) {
	case int:
		fmt.Println("int:", num)
	case float64:
		fmt.Println("float64:", num)
	default:
		fmt.Println("unknown")
	}
}
```

`i.(type)` 不是什么新的语法，只不过是用在 `switch` 里的语法糖而已，在别的地方不能写；事实上，上面的例子完全可以手动这么写：

```go
func main() {
	var i interface{} = 123

	if num, ok := i.(int); ok {
		fmt.Println("int:", num)
	} else if num, ok := i.(float64); ok {
		fmt.Println("float64:", num)
	} else {
		fmt.Println("unknown")
	}
}
```

#### 9.5.3 运行时判断是否实现了某接口

如果我们现在要写一个函数，接受一个空接口类型的参数。然后在函数内部，我们需要判断传入的值是否实现了某些接口，那我们应该怎么办？用反射？没这必要，直接用类型断言即可。

按我自己的理解，其实类型断言是否成功的语义上的判断依据，就是接口中的底层值是否能赋值给断言的类型的变量而已；然后我们再想想，是不是一个类型实现了某接口，那么这个类型的值就能赋值给某接口类型的变量；那我们是不是可以直接对我们接收到的空接口进行类型断言，断言其是否属于某另外的接口呢？可以的。

在下面这个例子中，`output` 通过对空接口类型断言，检测了其保存的值是否实现了 `Introducer` 接口，如果实现，则调用 `v.Introduce()`；如果没实现，继续检查是否实现了 `fmt.Stringer` 接口，实现则调用 `v.String()`；否则，就输出 `unknown` 作为缺省处理。

```go
package main

import "fmt"

type Stu struct {
	Name string
}

func (s *Stu) Introduce() string {
	return "I am " + s.Name
}

type Introducer interface {
	Introduce() string
}

func output(i interface{}) {
	switch v := i.(type) {
	case Introducer:
		fmt.Println(v.Introduce())
	case fmt.Stringer:
		fmt.Println(v.String())
	default:
		fmt.Println("unknown")
	}
}

func main() {
	s := &Stu{"Tom"}
	output(s)
}
```

```
I am Tom
```
