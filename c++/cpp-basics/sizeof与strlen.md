## sizeof与strlen

### `sizeof`：**编译时操作符**

#### 作用：

用于获取类型或对象在**内存中所占的字节数**。

#### 用法：

```cpp
sizeof(类型名)    // 获取某个类型的字节大小
sizeof(变量名)    // 获取某个对象（变量、数组等）的大小
```

#### 特点：

- 是 **编译时决定** 的操作，结果是一个 `constexpr`。
- 返回值类型是 `size_t`。
- 与内容无关，仅与 **类型定义** 或 **数组大小** 有关。

#### 示例：

```cpp
#include <iostream>
using namespace std;

int main() {
    int x = 10;
    char str1[] = "hello";
    char* str2 = "hello";

    struct MyStruct {
        char a;   // 1 字节
        int b;    // 4 字节
        char c;   // 1 字节
    };

    MyStruct s;

    cout << "sizeof(x) = " << sizeof(x) << endl;           // 输出 4
    cout << "sizeof(str1) = " << sizeof(str1) << endl;     // 输出 6
    cout << "sizeof(str2) = " << sizeof(str2) << endl;     // 输出 8（在64位系统中）
    cout << "sizeof(MyStruct) = " << sizeof(MyStruct) << endl; // 输出 12（字节对齐）
}
```

结构体 `MyStruct` 的内存布局分析：

```cpp
struct MyStruct {
    char a;   // 占 1 字节，偏移 0
    padding   // 3 字节，对齐 int 到 4 字节边界
    int b;    // 占 4 字节，偏移 4
    char c;   // 占 1 字节，偏移 8
    padding   // 3 字节，使结构体总大小为 12（对齐到最大对齐单位）
};
```

总大小：

```txt
1 + 3（padding）+ 4 + 1 + 3（padding）= 12 字节
```

如果改为：

```cpp
struct MyStruct2 {
    int b;
    char a;
    char c;
};
```

此时：

- `b` 在偏移 0，占 4 字节；
- `a` 和 `c` 紧跟其后，占 1+1；
- padding 2 字节，使结构体对齐到 `4` 字节边界。

```cpp
sizeof(MyStruct2) == 8
```

### `strlen`：**运行时函数**

#### 作用：

用于计算 C 风格字符串的**实际长度**（不包括 `\0` 终止符）。

#### 用法：

```cpp
strlen(const char* str);  // 参数必须是以'\0'结尾的C字符串
```

#### 特点：

- 是运行时函数，遍历字符串直到遇到 `\0`。
- 返回值类型也是 `size_t`。
- 与内存大小无关，只与字符串的内容有关。
- 需要包含头文件：`#include <cstring>`

#### 示例：

```cpp
char str1[] = "hello";      // 长度是5，实际占6字节（包含'\0'）
char* str2 = "hello";

std::cout << strlen(str1);  // 输出5
std::cout << strlen(str2);  // 输出5
```

### 对比表格

| 项目          | `sizeof`               | `strlen`                          |
| ------------- | ---------------------- | --------------------------------- |
| 类型          | 编译时操作符           | 运行时函数                        |
| 返回值类型    | `size_t`               | `size_t`                          |
| 所测内容      | 类型或对象的**字节数** | 字符串的**实际长度（不含 '\0'）** |
| 与内容相关性  | 无关                   | 有关                              |
| 是否遍历内存  | 否                     | 是                                |
| 是否包含 `\0` | 包含（数组中）         | 不包含                            |
| 常用场景      | 内存分配、结构体计算   | 字符串处理                        |

### 易错点

| 错误思维                     | 正确理解                           |
| ---------------------------- | ---------------------------------- |
| `sizeof(str)` 就是字符串长度 | 错 ❌，可能只是指针大小（8 字节）   |
| `strlen` 可以用于任意类型    | 错 ❌，只能用于 `\0` 结尾的 `char*` |
| `sizeof` 返回的是元素个数    | 错 ❌，它返回的是**字节数**         |

> 例如：`sizeof(arr) / sizeof(arr[0])` 才是数组长度（元素个数）

### 数组作为函数参数会退化为指针

```cpp
#include <iostream>
using namespace std;

void printSize(int arr[]) {
    cout << "sizeof(arr) in function = " << sizeof(arr) << endl;
}

int main() {
    int arr[10];

    cout << "sizeof(arr) in main = " << sizeof(arr) << endl;  // 输出 40（10 * 4）
    printSize(arr);  // 实际上传递的是 int*
}
```

输出：

```txt
sizeof(arr) in main = 40
sizeof(arr) in function = 8 （在64位系统）或 4（32位系统）
```

- 在 `main()` 里，`arr` 是一个真正的数组，大小是 `10 * sizeof(int)`，所以是 40。
- 在 `printSize()` 里，`arr` 是 **函数参数**，它退化成了一个 `int*`，`sizeof(arr)` 实际上就是 `sizeof(int*)`，在 64 位系统上是 8。

函数签名中三种写法等价：

```cpp
void func(int arr[]);
void func(int arr[10]);
void func(int* arr);
```

这三种在函数参数中是等价的，**都会退化为指针 `int\*`**。

### sizeof 一个空类

在 C++ 中，即使一个类是空的（即没有成员变量和成员函数），`sizeof` 这个空类的结果也不会是 `0`，而是 **1**。这是 C++ 语言标准所规定的行为。

原因：

C++ 需要确保每个对象在内存中有一个唯一的地址。如果 `sizeof(Empty)` 是 `0`，那么创建多个该类的对象时，它们可能会被分配到相同的地址，从而违反了对象地址唯一性的要求。

示例代码：

```cpp
#include <iostream>

class Empty {};

int main() {
    std::cout << sizeof(Empty) << std::endl;  // 输出 1
    return 0;
}
```

特别说明：

- 编译器会为空类分配至少 1 字节空间，以确保不同对象的地址不同。
- 如果你继承一个空类，情况可能会有所不同（尤其涉及 **空基类优化 EBO, Empty Base Optimization**），例如：

```cpp
class Empty {};

class Derived : public Empty {
    int x;
};

int main() {
    std::cout << sizeof(Derived) << std::endl; // 通常输出 4，而不是 5
}
```

在这个例子中，`Derived` 继承自 `Empty`，但 `Empty` 并没有占用额外空间，说明编译器应用了 **EBO**。

总结：

- `sizeof(空类)` == 1，这是标准规定的。
- 主要目的是为了让对象地址唯一。
- 编译器可能在继承时优化掉空基类占用的空间。