1. 其实就相当于：  
``` bash
rm <file>
git add <file>
```
2. `git rm --cached <file>` ：保留工作区的 \<file> ，其实就相当于**把 \<file> 变为未跟踪**。**以后** commit 的**快照**中就**没有** \<file> 了。
3. `git rm` 相当于 `git add` 的反义，在执行后需要运行 `git commit` 。
4. 被 `git rm` 的文件只是以后不会被跟踪了，亦即不会出现在以后的仓库里了（除非以后又 `add` ）；在  rm 那次的 commit 之前的 commit 依然保存有 \<file> 的快照，依然可以通过 `git reset` 找到被删除的 \<file> 。