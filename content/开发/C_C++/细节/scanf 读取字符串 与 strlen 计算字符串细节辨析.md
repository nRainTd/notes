先看代码  

``` cpp
#include <cstdio>
#include <cstring>
#include <iostream>

using namespace std;

int main() {
  char input_chs[10] = { 0 };
  char hard_chs[10] = "abcd \t\n";
  scanf("%s", input_chs);

  auto input_len = strlen(input_chs);
  auto hard_len = strlen(hard_chs);
  cout << "input_len: " << input_len << endl;
  cout << "hard_len: " << hard_len << endl;

  cout << "input_chs: ";
  for (int i = 0; i < 10; ++i) {
    cout << '[' << (int)input_chs[i] << ']';
  }

  cout << endl;

  cout << "hard_chs: ";
  for (int i = 0; i < 10; ++i) {
    cout << '[' << (int)hard_chs[i] << ']';
  }

  return 0;
}
```

运行结果  

``` powershell
abcd(空格)(换行)(回车) 
input_len: 4
hard_len: 7
input_chs: [97][98][99][100][0][0][0][0][0][0]
hard_chs: [97][98][99][100][32][9][10][0][97][98]
```

可以看到：  
1. scanf("%s") 只能读取连续的字符串，遇到空格、制表符、换行就会停止，并且前叙三者不会被读取进字符数组；  
2. strlen 会计算数值 0 之前字符的个数，不包括数值 0 ；  
