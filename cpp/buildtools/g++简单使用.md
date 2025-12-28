## g++ 简单使用

### 基本编译

```bash
g++ main.cpp
```

- 将 `main.cpp` 编译为默认可执行文件 `a.out`（Linux/macOS）或 `a.exe`（Windows）。

```bash
g++ main.cpp -o myprogram
```

- 指定输出文件名为 `myprogram`。

### 多文件编译

```bash
g++ main.cpp utils.cpp -o myprogram
```

- 将多个源文件一起编译并链接成一个可执行文件。

```bash
g++ -c utils.cpp
g++ -c main.cpp
g++ main.o utils.o -o myprogram
```

- `-c`：只编译生成目标文件 `.o`，不链接。
- 链接时再生成最终可执行文件。

### 预处理、编译、汇编、链接阶段控制

```bash
g++ -E main.cpp -o main.i    # 只做预处理
g++ -S main.cpp -o main.s    # 生成汇编代码
g++ -c main.cpp -o main.o    # 生成目标文件
g++ main.o -o main           # 链接生成可执行文件
```

### 编译选项

| 选项          | 说明                                        |
| ------------- | ------------------------------------------- |
| `-std=c++17`  | 指定 C++ 标准（C++11/C++14/C++17/C++20 等） |
| `-Wall`       | 打开常用警告                                |
| `-Wextra`     | 打开额外警告                                |
| `-O2` / `-O3` | 优化编译等级，`-O0` 表示不优化              |
| `-g`          | 生成调试信息，用于 gdb                      |
| `-I<路径>`    | 指定头文件搜索路径                          |
| `-L<路径>`    | 指定库文件搜索路径                          |
| `-l<库名>`    | 链接库，例如 `-lm` 链接数学库 `libm.so`     |

### 调试相关

```bash
g++ -g main.cpp -o myprogram
gdb myprogram
```

- `-g` 生成调试信息，方便在 gdb 中调试。

### 链接静态/动态库

```bash
g++ main.cpp -L./lib -lmylib -o myprogram
g++ main.cpp ./libmylib.a -o myprogram   # 静态库
```

- `-L./lib`：告诉链接器 **去 `./lib` 目录里找库**

  `-lmylib`：

  - `-l` 表示“链接一个库”
  - 实际找的是：
    - `libmylib.so`（优先，动态库）
    - 找不到再找 `libmylib.a`（静态库）

- **`.a`（静态库）**：
   编译时直接“拷进”可执行文件

- **`.so`（动态库 / 共享库）**：
   程序运行时再加载，多个程序可共享