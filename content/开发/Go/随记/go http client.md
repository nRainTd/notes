在 `go` 中，对于同一个 `http.Client`，即：

```go
client = http.Client{}
```

默认使用会复用连接(`keep-alive`)，并且使用了连接池机制。

当正常复用的前提是读取完 `resp.Body` 并且最后不能忘记 `resp.Body.Close()`，否则都会新开一个连接而不会复用。

连接池的默认 `MaxIdleConns` 最大连接数为 `100`，`DefaultMaxIdleConnsPerHost` 默认每主机最大连接数为 `2`，如果想要更改，可以这样：

```go
client := http.Client{           
	Transport: &http.Transport{    
		MaxIdleConns:        100,    
		MaxIdleConnsPerHost: 100,    
	},                             
}
```
