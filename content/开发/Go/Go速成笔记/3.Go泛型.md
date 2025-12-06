---
创建: 2025-11-23
tags:
  - 开发/Go/泛型
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

## 1 概述

比如我们要实现一个 `addSum` 函数，调用时向全局变量 `var sum float64 = 0` 加一个数。这个数可以是整型也可以是浮点型；如果没有泛型，我们要么定义多个 `addSumInt8` `addSumInt16` `addSumFloat32` 函数，然后每个函数中都是相同的逻辑，即 `sum += float64(x)`；或者我们也可以把形参设置为接口类型，但是函数内部我们还是需要进行类型选择，麻烦而且有一定性能损耗。

有了泛型后，我们就可以用一个 `addSum[T canToFloat](x T)` 实现了；下面的例子是具体实现。

```go
var sum float64 = 0

type canToFloat interface {
	constraints.Integer | constraints.Float
}

func addSum[T canToFloat](x T) {
	sum += float64(x)
}

func main() {
	a := 1
	b := 1.2
	addSum(a)
	addSum(b)
	fmt.Println(sum)
}
```

## 2 泛型和空接口的区别

我们可能会发现，发现可以让一个参数接受多个类型的值，空接口也可以；那么他们有什么区别呢？

这里简单写两点区别：
1. 泛型是编译时，空接口是运行时；
2. 泛型适用于一组符合类型约束的能够执行同一套代码的类型，比如 `int8` 和 `int16` 等都支持算数运算符操作；而空接口则是可以接受操作逻辑不同的类型，通过类型选择为每一种类型分配对应的处理逻辑。

## 3 泛型函数

如 [[#1 概述]] 这个标题下给的例子就是泛型函数的使用。

## 4 泛型类型

除了对定义泛型函数，我们还可以声明泛型参数。

比如 [[#利用 `map[T]struct{}` 手动实现集合 `set`]] 这个标题下面给的例子就是泛型类型的使用。

## 5 泛型实例化

比如 [[#1 概述]] 这个标题例子中写的 `addInt` 函数，其实是向下面这样调用的；使用 `addSum[int]` 的语法来“取出”这个泛型函数对 `int` 类型的实现，赋值给 `addSumInt`；这就叫泛型函数的实例化。

```go
a := 1
b := 1.2
addSumInt := addSum[int]
addSumFloat := addSum[float64]
addSumInt(a)
addSumFloat(b)
```

我们也可以在实例化后直接调用，不用变量来保存实例化的函数：

```go
a := 1
addSum[int](a)
```

在 [[#利用 `map[T]struct{}` 手动实现集合 `set`]] 这个标题下的 `set[T]` 也是可以先实例化再使用的

```go
type intSet = set[int]

func TestSet() {
	var s intSet = make(intSet)
	s.Add(1)
	s.Add(2)
	fmt.Println(s.Has(1))
}
```

## 6 类型约束

`Go1.18` 版本增加了泛型后，也拓展了接口的语法用于对泛型进行类型约束。
现在，接口不止可以声明方法签名，还可以写类型签名 (不过类型签名的接口只能用于泛型约束)。

在下面这个例子中，就约束了 `addSum` 的泛型 `T` 只能是 `int` 或 `float64` 类型。

```go
package main

import "fmt"

var sum float64 = 0

func addSum[T interface{ int | float64 }](x T) {
	sum += float64(x)
}

func main() {
	addSum(1)
	addSum(1.2)
	fmt.Println(sum)
}
```

对于字面值泛型约束，我们也可以省略外层的 `interface{}`，直接写 `[T int | float64]`

使用这种方式会严格匹配类型，如果想要支持命名类型，需要加上 `~`(例如 `~int`) 表示所有以它为底层类型的类型。

```go
var sum float64 = 0

func addSum[T ~int | ~float64](x T) {
	sum += float64(x)
}

type myInt int

func main() {
	addSum(myInt(1))
	addSum(1.2)
	fmt.Println(sum)
}
```

## 7 类型推断

### 7.1 函数参数泛型类型推断

从上面的例子我们也能看出来，我们调用泛型函数时可以不手动实例化，而是像调用普通函数一样，直接传参；这时候，泛型的类型将根据传入参数的类型自动推断。

### 7.2 类型参数不支持泛型推断

Go 中只有函数参数支持泛型推断，类型参数必须显式实例化。
然后类型参数泛型的方法声明看起来很像是类型推断，但其实是调用泛型类型的方法时，往往泛型类型已经实例化了；

比如下面例子定义的方法，看起来没写类型约束 (`func (v *Stack[T]) Push(elem T)` 只有泛型 `T` 没有约束)；但事实上，当我们能够调用方法时，接收者的类型已经确定下来了；也即是说这里的 `T` 就是从 `v *Stack[T]` 接收到的具体类型 (`v.Push` 的时候 `v` 已经实例化，`v *Stack[T]` 能够自动推导出 `T`)，然后后面的 `Push(elem T)` 自然也跟着确定了。

```go
package stack

type Stack[T any] []T

func New[T any](length int, capacity int) *Stack[T] {
	s := make(Stack[T], length, capacity)
	return &s
}

func (v *Stack[T]) Push(elem T) {
	*v = append(*v, elem)
}

func (v *Stack[T]) Pop() (ret T, ok bool) {
	back := len(*v) - 1
	if back < 0 {
		return
	}
	defer func() { *v = (*v)[:back] }()
	return (*v)[back], true
}
```

```go
package main

import (
	"fmt"
	"nraintd/gogogo/stack"
)

func main() {
	s := stack.New[int](3, 10)
	s.Push(123)
	s.Push(456)
	s.Push(789)
	fmt.Println(s.Pop())
	fmt.Println(s.Pop())
	fmt.Println(s.Pop())
	fmt.Println(s.Pop())
}
```

```
789 true
456 true
123 true
0 true
```

然后对于方法表达式，我们也需要手动实例化，例如：

```go
push := (*Stack[int]).Push
```

### 7.3 约束类型推断

> [!quote] 参考
> [参考文章在这](https://golangstar.cn/go_series/go_advanced/generics.html#%E7%B1%BB%E5%9E%8B%E6%8E%A8%E6%96%AD)
> 他给的例子略微有点冗长，我简化了一下

比如我们有这样一个泛型函数 `Push`，它接收一个满足 `Interger` 约束的泛型参数，实现和 `append` 一样的功能：像 `arr []T` 末尾添加 `elem T` 并返回 `[]T`，看起来它能够正常工作。

```go
func Push[T constraints.Integer](arr []T, elem T) []T {
	return append(arr, elem)
}
```

现在，我们定义一个以 `[]int32` 为底层类型的类型 `Vector`，它有一个方法 `Len()`；
然后执行 `Push(Vector{1, 2, 3}, 4)` 并将结果赋值给 `v` 变量；最后，我们对 `v` 执行方法 `Len()`，发现报错了。

```go
type Vector []int32

func (v Vector) Len() int { return len(v) }

func main() {
	v := Push(Vector{1, 2, 3}, 4)
	fmt.Println(v)
	fmt.Println(v.Len())
}
```

原因时自动类型推断时，传给 `arr` 的实参 `Vector{}` 是 `Vector` 类型；
这时候 `[]T <=> Vector <=> []int32`，`T` 被推导为 `int32`，所以 `Push` 返回的就是 `[]T => []int32`，而不是 `Vector` 类型，就无法调用 `Len` 方法。

这时候，我们只需要把泛型函数 `Push` 改成这样：

```go
func Push[T constraints.Integer, U ~[]T](arr U, elem T) U {
	return append(arr, elem)
}
```

然后我们把 `Vector{}` 传递给 `arr` 时，
`U <=> Vector` 推断出 `U` 的类型为 `Vector`；
而 `U <== ~[]T`，所以 `[]int32 <=> Vector <=> ~[]T` 得出 `T` 类型为 `int32`。

于是 `v.Len()` 就能正常执行了。
