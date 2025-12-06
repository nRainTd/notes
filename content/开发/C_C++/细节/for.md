## 1 `for` 循环结束条件运算

```cpp
#include <iostream>

int main() {
  using namespace std;
  int a = 2;
  for (int i = 0; i < --a; i++) {
    cout << i << ' '; // 0
  }

  cout << endl << a; // 0

  return 0;
}
```

**包括**第一次 (**初始化**那次) 在内的**每一次**都会对结束条件的表达式进行**运算**，只是一般我们写在比较运算符右边的都是常量，所以容易忽略**每次都会执行运算**这一事实

如例子那样，每次都会执行一次 --a
