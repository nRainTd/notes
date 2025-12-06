1. `git pull <remoteName> <branchName>` ：拉取并合并远程仓库的某分支，如果无法合并，会提示手动合并，到相应文件里做出调整后使用 `git commit -a` 提交即可。需要写齐四个参数。  
2. `git pull` 会拉取整个仓库的数据，但是只会 `merge` 当前跟踪分支，其他分支需要切换到那个分支然后执行 `git merge` 或 `git pull` 。其实就是拆解成 `git fetch` 和 `git merge` 。  
**待办：验证 `git pull <remoteName> <branchName>` 拉取的是整个远程仓库的数据还是单个分支的数据。其中，\<branchName> 为普通分支**
