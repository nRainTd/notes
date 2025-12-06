`git mv oldName newName`
改名，相当于：
``` bash
mv oldName newName
git rm oldName
git add newName
```
先重命名，再**取消跟踪**旧文件名，最后**跟踪**新文件名。