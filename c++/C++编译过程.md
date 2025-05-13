## C++编译过程

- 源文件

```c++
#include <iostream>

#define M "Result: "

int add(int a, int b) {
    return a + b;
}

int main() {
    int result = add(3, 4);
    // 在预处理阶段 M 会被替换成 "Result: "
    std::cout << M << result << std::endl;
    return 0;
}
```

### 1. 预处理（生成 `.i` 文件）

```bash
g++ -E main.cpp -o main.i
```

- `-E`：只运行**预处理器**（Preprocessor），不编译。
- `main.cpp`：原始源文件。
- `-o main.i`：指定输出文件为 `main.i`，这是预处理完成后的代码（包含宏展开、头文件替换等）。

打开 `main.i` 会发现所有 `#include` 的内容被展开成真实代码，宏 (`#define`) 被替换为实际内容，没有注释（都被移除了）。

```cpp
......(有几万行)
# 2 "main.cpp" 2

# 5 "main.cpp"
int add(int a, int b) {
    return a + b;
}

int main() {
    int result = add(3, 4);

    std::cout << "Result: " << result << std::endl;
    return 0;
}
```

### 2. 编译（生成 `.s` 汇编文件）

```bash
g++ -S main.cpp -o main.s
```

- `-S`：只进行**编译**，输出汇编代码，不进行汇编（不生成机器码）。
- `main.cpp`：源文件。
- `-o main.s`：输出文件是汇编代码。

把预处理后的源码转换成 **汇编代码（.s 文件）**，主要是语法分析、语义分析、优化、生成汇编。

### 3. 汇编（生成 `.o` 目标文件）

```bash
g++ -c main.cpp -o main.o
```

- `-c`：**编译并汇编**，生成机器码（目标文件），不进行链接。
- `main.cpp`：源代码。
- `-o main.o`：输出目标文件 `main.o`。

把汇编代码（`.s` 文件）转成机器码（`.o` 或 `.obj` 文件，叫“目标文件”），每个源文件会变成一个 `.o` 文件，里面是二进制的函数/变量信息。

查看内容（反汇编）：

```bash
nm main.o           # 查看符号表
objdump -d main.o   # 查看反汇编代码
```

### 4. 链接（生成最终可执行程序）

```bash
g++ main.o -o app
```

- `main.o`：输入的目标文件。
- `-o app`：输出可执行文件名为 `app`。

把多个 `.o` 文件 + 库文件组合成一个完整的 **可执行文件**，把函数/变量地址统一、补上引用，比如 `std::cout` 是从 `libstdc++.so` 来的。如果使用了多个源文件，链接阶段会把它们拼在一起。

### 总结

```txt
源代码（.cpp）
   ↓ 预处理
展开 include、宏等
   ↓ 编译
生成汇编代码
   ↓ 汇编
生成目标文件（.o）
   ↓ 链接
整合库、目标文件
   ↓
最终可执行程序（app）
```

