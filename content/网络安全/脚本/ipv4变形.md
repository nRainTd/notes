---
创建: 2025-09-10
tags:
  - CTF/脚本/ipv4变形
---
```python
def ipv4_to_int(ipv4):
    sum = 0
    parts = ipv4.split(".")
    for i in range(len(parts)):
        part = int(parts[i])
        sum += part << (8 * (3 - i))
    return sum


def ipv4_to_hex(ipv4):
    return hex(ipv4_to_int(ipv4))


def ipv4_to_oct(ipv4):
    parts = ipv4.split(".")
    res = []
    for part in parts:
        part = str(oct(int(part))).replace("0o", "0")
        while len(part) < 4:
            part = "0" + part
        res.append(part)
    return ".".join(res)


print(ipv4_to_hex("127.0.0.1"))
```
