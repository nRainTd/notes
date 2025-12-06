1. `git checkout <commitId> <file>` ：从某次提交取出 \<file> ，放到工作区和暂存区。  

**后面的命令都有替代品，为了明确语义，避免造成混乱，不建议使用。**
2. `git checkout -- <file>` 将 \<file\> 撤销到最近一次 `git commit` 或 `git add` 时的状态。**用 `git restore <file>` 也能实现类似效果，这个是新出的命令。**
3. `git checkout <branchName>` ：切换到 branchName 分支。**用 `git switch <branchName>` 也能实现类似的效果，这个是新出的命令。**