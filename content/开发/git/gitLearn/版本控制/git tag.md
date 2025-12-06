1. 本地打的标签默认情况下不会被 `push` 到远程仓库，标签需要单独推送。

2. 猜测 git 对于标签应该有与分支差不多的处理方式，即：标签与分支实际上都是一个指向某一次提交的指针。下面是几点验证：
	1. 提交到远程仓库的方式：`git push <remote> <tagName>` 与 `git push <remote》 <branchName>` ，以及它们的本质：`git push <remote> refs/heads/branchName:refs/heads/branchName` 与 `git push <remote> refs/tags/tagName:refs/tags/tagName` 。
	2. 从远程仓库删除的方式：`git push <remote> --delete <tagName>` 与 `git push <remote> --delete <branchName>` ，以及它们的本质：`git push <remote>  :refs/heads/branchName`与  `git push <remote>  :refs/tags/tagName`
	
另外，从分支 `refs/heads/branchName` 与标签 `refs/tags/tagName` 表示方式中 heads 与 tags 的差异可以看出，`HEAD` 指针与分支指针是同类事物——或者可以说，`HEAD` 其实就是特殊类型的分支指针：被 `HEAD` 指向的分支指针代表了当前分支。正如 [[思考#如何理解 `HEAD` ？]] 中所说，`HEAD` 其实可以理解为当前分支的别名。