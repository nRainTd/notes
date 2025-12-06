---
创建: 2025-09-06
tags:
  - 开发/git/换行符转换
---

```toc
```

# 引入

一次我用 `git` 拉取一道 CTF web 题的源码，然后用 `docker` 构建镜像并运行容器，结果容器中 `init.sh` 脚本运行失败。

报错
![[win中git拉取仓库的换行符问题-250906-164959.png]]

脚本内容 (就是放出来展示一下，实则跟脚本的具体内容无关)

```sh
#!/bin/sh

if [ "$A1CTF_FLAG" ]; then
    INSERT_FLAG="$A1CTF_FLAG"
    unset A1CTF_FLAG
elif [ "$LILCTF_FLAG" ]; then
    INSERT_FLAG="$LILCTF_FLAG"
    unset LILCTF_FLAG
elif [ "$GZCTF_FLAG" ]; then
    INSERT_FLAG="$GZCTF_FLAG"
    unset GZCTF_FLAG
elif [ "$FLAG" ]; then
    INSERT_FLAG="$FLAG"
    unset FLAG
else
    INSERT_FLAG="LILCTF{!!!!_FLAG_ERROR_ASK_ADMIN_!!!!}"
fi

echo -n $INSERT_FLAG > /flag
INSERT_FLAG=""

python3 app.py
```

后来才知道原因是，windows 上使用 `git` 从远程仓库拉取源码时，把文件中的 `\n` unix `LF` 换行符自动改成 `\r\n` dos `CRLF` 换行符了。(其实是从远程仓库拉取 git 仓库后，检出最新的提交时转换的)
而 `Dockerfile` 中，存有 `init.sh` 的目录是直接被 `COPY` 到镜像中的，所以构建完镜像启动容器后，可能是由于 shell 脚本对大小写敏感，运行带有 `CRLF` 换行符的 `init.sh` 就报错了。

`Dockfile` 长这样：

```Dockfile
FROM ghcr.io/gzctf/challenge-base/python:alpine

RUN pip install --no-cache-dir flask werkzeug flask_sqlalchemy requests

COPY --chown=ctf --chmod=700 src /home/ctf/app/
COPY --chown=ctf --chmod=744 flag /flag

WORKDIR /home/ctf/app

EXPOSE 5000

CMD ["./init.sh"]
```

# git 对换行符的自动转换机制

git 对换行符转换的处理方式，由 `core.autocrlf` 配置决定，而这个配置有三个值

## 1 查看配置

可以使用下面命令查看自己的 git 的配置

```shell
git config --global core.autocrlf
```

当然，如果从来没配置过，上面的命令输出会是空的，表示使用默认配置 (其实官方文档也没提默认配置是什么)
![[win中git拉取仓库的换行符问题-250906-202410.png]]

## 2 三种配置值

| 配置值   | 检出                   | 提交                      |
| ----- | -------------------- | ----------------------- |
| true  | 把仓库的 `LF` 转换为 `CRLF` | 把目录的 `CRLF` 转换为仓库的 `LF` |
| input | 保持仓库不变               | 把目录的 `CRLF` 转换为仓库的 `LF` |
| false | 不改变                  | 不改变                     |

官方文档的描述，可以看到，里面只说了在什么系统上推荐什么配置，没说系统的默认配置是啥。
![[git对换行符的处理-250906-203916.png]]

## 3 改变配置

使用如下命令改变配置

```shell
git config --global core.autocrlf <配置>
```

![[git对换行符的处理-250906-204353.png]]
