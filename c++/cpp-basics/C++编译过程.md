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

### C++ 分离式编译

C++ 分离式编译（**Separate Compilation**）是一种 **将程序拆分为多个源文件分别编译**，然后在链接阶段将它们组合成一个可执行文件的机制。这种机制能带来更好的模块化、编译速度提升和团队协作效率。

在 C++ 中，一个典型的项目可能被拆成以下几类文件：

| 文件类型         | 后缀名                   | 内容                           |
| ---------------- | ------------------------ | ------------------------------ |
| 头文件（Header） | `.h` 或 `.hpp`           | 类声明、函数声明、宏定义等     |
| 源文件（Source） | `.cpp`                   | 函数实现、类成员函数定义       |
| 编译目标文件     | `.o` 或 `.obj`           | 每个 `.cpp` 编译生成的中间文件 |
| 可执行文件       | `.exe` 或无后缀（Linux） | 链接所有目标文件生成的最终程序 |

#### 分离式编译的优点

- **更快的编译速度**：只修改一个 `.cpp` 文件时，其他模块无需重新编译。
- **更好的可维护性**：代码结构更清晰，每个模块职责分明。
- **有利于多人协作**：多人可以同时编写和调试不同模块。
- **支持复用与封装**：通过头文件声明接口，只暴露必要内容。

#### 注意事项

- 不要在 `.cpp` 中定义多次同一个函数或全局变量（否则链接时重复定义）。
- 每个 `.cpp` 文件应包含自己所需的头文件。
- 使用 `#include` 时要注意头文件的**包含保护（include guard）**，避免重复包含。

#### 举例

有这样一个项目结构：

```less
project/
├── math_utils.cpp   // 数学函数的实现
├── math_utils.h     // 数学函数的声明
├── string_utils.cpp // 字符串处理实现
├── string_utils.h   // 字符串处理声明
├── main.cpp         // 主函数
```

编译过程是分开的：

```bash
g++ -c math_utils.cpp     # ➜ 生成 math_utils.o
g++ -c string_utils.cpp   # ➜ 生成 string_utils.o
g++ -c main.cpp           # ➜ 生成 main.o
g++ math_utils.o string_utils.o main.o -o my_program
```

如果只改了 `math_utils.cpp`

- 只需要重新运行：

  ```bash
  g++ -c math_utils.cpp    # 重新生成 math_utils.o
  ```

- `string_utils.o` 和 `main.o` **不需要重新编译**（假设 `math_utils.h` 没变）；

- 然后重新链接：

  ```bash
  g++ math_utils.o string_utils.o main.o -o my_program
  ```

这样做的好处是：

- **节省时间**：每个 `.cpp` 编译可能需要几秒甚至几十秒，大项目编译一次很慢；
- **提高效率**：只重编改动的文件，不影响其他模块。

如果改动的是 **头文件**（如 `math_utils.h`），而这个头文件被多个 `.cpp` 包含（通过 `#include`），那么 **所有依赖这个头文件的 `.cpp` 文件都要重新编译**，因为头文件的变化可能影响函数签名、类定义等。
