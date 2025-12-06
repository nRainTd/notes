1. `git branch` ：查看分支

2. `git branch <branchName>` ：创建名为 branchName 的新分支

3. `git branch -m newName` ：将当前分支重命名为 newName

4. `git branch -d <branchName>` ：删除 branchName 分支（不能删除当前分支）

5. `git branch <localBranch> <remote>/<remoteBranch>` ：新建跟踪分支 localBranch，来跟踪远程跟踪分支 remoteBranch 。  

6. `git branch <remoteBranchName>` ：不会创建跟踪分支，而是新建普通分支。新建分支是在 HEAD 的基础上新建的，与 `fetch` 来的分支没有关系。
