例如 `char arr[3][2]` 这样一个二位数组中，在内存中其实就是 6 个连续的 1 字节空间；如果画出内存分布图的话，应该是这样：
![[twoDimeArr.drawio.png]]

在试验程序中的表现也符合上图：

```c
#include <stdio.h>

int main() {
  char arr[3][2] = { {1, 2}, {3, 4}, {5, 6} };

  printf("---arr[i][j]---\n");
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 2; j++) {
      printf("%d ", arr[i][j]);
    }
  }
  putchar('\n');

  printf("---&arr[i][j]---\n");
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 2; j++) {
      printf("%#x\n", &arr[i][j]);
    }
  }

  printf("---*arr[i]---\n");
  for (int i = 0; i < 3; i++) {
    printf("%d ", *arr[i]);
  }
  putchar('\n');

  printf("---arr[i]---\n");
  for (int i = 0; i < 3; i++) {
    printf("%#x\n", arr[i]);
  }

  char *p_arr = (char *)arr;

  printf("---(char*)arr[i]---\n");
  for (int i = 0; i < 6; i++) {
    printf("%d ", p_arr[i]);
  }
  putchar('\n');

  printf("---&(char*)arr[i]---\n");
  for (int i = 0; i < 6; i++) {
    printf("%#x\n", &p_arr[i]);
  }

  return 0;
}
```

输出为：

```bash
---arr[i][j]---
1 2 3 4 5 6 
---&arr[i][j]---
0x5ffea2
0x5ffea3
0x5ffea4
0x5ffea5
0x5ffea6
0x5ffea7
---*arr[i]---
1 3 5
---arr[i]---
0x5ffea2
0x5ffea4
0x5ffea6
---(char*)arr[i]---
1 2 3 4 5 6
---&(char*)arr[i]---
0x5ffea2
0x5ffea3
0x5ffea4
0x5ffea5
0x5ffea6
0x5ffea7
```
