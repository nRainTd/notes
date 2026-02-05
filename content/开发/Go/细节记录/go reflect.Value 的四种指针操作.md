---
created: 2025-12-14
modified: 2025-12-14
tags:
  - 开发/Go/细节
---

```go
// 在反射值层面，返回一个值的地址，即反射值层面的取地址(值本身和取到的地址都是 reflect.Value 类型)
field.Addr()

// 取一个反射值中存储的数据的实际内存地址并以 uintptr 形式返回(软废弃，推荐 uintptr(v.Addr().UnsafePointer()))
field.UnsafeAddr()

// 返回一个反射值内部持有指针的 uintptr 形式(软废弃，推荐 uintptr(v.UnsafePointer()))
field.Pointer()

// 返回一个反射值内部持有指针的 unsafe.Pointer 形式
field.UnsafePointer()
```

通过反射和 `unsafe` 修改结构体私有字段：

我们假设 `private` 包下面有一个 `Private` 结构体，有 `age` 私有字段需要修改

```go
package private

type Private struct {
	Name string
	age  int
}

func New() *Private {
	return &Private{
		Name: "张三",
		age:  20,
	}
}
```

常规的反射是不允许 `set` 私有字段的，但我们可以先借助 `field.Addr().UnsafePointer()` 获取私有字段的 `unsafe.Pointer` 指针，然后用 `reflect.NewAt()` 在这个指针的基础上创建一个新的 `reflect.Value`；由于这个 `Value` 里面的上下文信息里面没有记录这个值是私有的，所以可以绕过安全检查，达到设置私有字段的目的。

```go
package main

import (
	"fmt"
	"main/private"
	"reflect"
)

func main() {
	p := private.New()

	v := reflect.ValueOf(p).Elem()

	field := v.FieldByName("age")

	if !field.IsValid() {
		panic("没有这个字段")
	}
	if !field.CanAddr() {
		panic("不可寻址")
	}

	if field.CanInt() {
		fmt.Println(field.Int())
	}

	pv := reflect.NewAt(field.Type(), field.Addr().UnsafePointer())
	if pv.Elem().CanSet() && pv.Elem().CanInt() {
		pv.Elem().SetInt(123)
	}

	if field.CanInt() {
		fmt.Println(field.Int())
	}
}

```
