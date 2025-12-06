`git reset --<mixed/soft/hard> <commitId>` 会把 `HEAD` 移到 \<commitId> 处，\<commitId> 之后的提交将无法通过 `git log` 查看到（此时 `git log` 查看到的最新提交是 \<commitId>），不过，通过 `git reflog` 依然可以查看 `HEAD` 的移动记录（其实就是把它指过的 commit 按先后顺序列出来）。（准确地说，前面（和后面）的 `HEAD` 代指 `HEAD` 指向的分支指针）  ![](git_reflog.png)
如图，`git reflog` 会把 `HEAD` 每次指向的 commit 从先到后列出来，通过这个就可以回到 \<commitId> 之后。  
对于三种模式：`HEAD` 都指向 \<commitId>，后面的提交历史（`log`）“清空”。  
1. `--mixed` ：保留工作区内容，清空暂存区。
2. `--soft` ： 保留工作区内容，保留暂存区（如果 `reset` 前有内容暂存），会把 \<commitId> 之后的提交也添加到暂存区。（但不会把工作区未暂存的内容添加到暂存区）
3. `--hard` ：用 \<commitId> 处提交的内容刷新工作区，清空暂存区。
以上所有操作都不会对未跟踪的文件起作用，可以把未跟踪的文件归类到工作区之外。