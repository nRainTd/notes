1. `git switch <branchName>` 切换分支

2. `git switch -c <branchName>` 新建并切换到分支

3. `git switch <localTrackBranch>` 新建一个跟踪同名远程分支的跟踪分支

4. `git switch -c <localTrackBranch> <remote>/<remoteBranch>` 新建一个本地跟踪分支 localTrackBranch 来跟踪远程跟踪分支 remoteBranch 。

5. `git switch -c <remoteBranchName>` 不会创建跟踪分支，而是新建普通分支。新建分支是在 HEAD 的基础上新建的，与 `fetch` 来的分支没有关系。
