1. `git restore <file>` ：取消修改 \<file> ，即将工作区的 \<file\> 撤销到最近一次 `git commit` 或 `git add` 时的状态。类似 `git checkout -- <file>` 。
2. `git restore --staged <file>` ：取消暂存 \<file>，即清空暂存区，工作区不变。类似 `git reset HEAD <file>` 。
