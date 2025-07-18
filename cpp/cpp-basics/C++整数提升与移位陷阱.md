## C++ 整数提升与移位陷阱

C++ 语言规定，小于或等于 `int` 的整数类型（如 `char`, `uint8_t`, `short`, `bool`，以及枚举类型等）在表达式中参与算术、移位或逻辑运算时，会被**自动提升**为 `int` 或 `unsigned int`（根据是否能表示原类型范围）。

引用 [cppreference](https://en.cppreference.com/w/c/language/conversion.html?utm_source=chatgpt.com)（“Implicit conversions” 页面）：

> **Integer promotion is the implicit conversion of a value of any integer type with rank less or equal to rank of int …
>  If int can represent the entire range of values of the original type … the value is converted to type int. Otherwise … unsigned int.
>  … applied … to both operands of the shift operators `<<` and `>>`.** 

### 提升规则

当 `char`, `short`, `bool`, `enum`, `uint8_t`, `int8_t`, `int16_t` 等较小的整数类型参与表达式时：

1. **如果 `int` 能表示该类型的所有值**，就提升为 `int`
2. 否则，提升为 `unsigned int`

- 大部分现代平台（如 x86-64）`int` 都是 32 位，足够表示所有小于 `int` 的整数类型的值，所以他们都会提升成 `int`。
- **如果平台 `int` 是 16 位**，那 `unsigned short` 的最大值 65535 是无法放入 `int` 的（`int` 最大只能 32767），此时 `unsigned short` 会提升为 `unsigned int`。
- 这个规则是为了兼容一些特殊平台和古老环境，保证类型转换的安全。

示例：

```cpp
uint8_t g = 0x80; // 实际是 unsigned char，值为128
auto x = g + 1;   // g 会提升为 int
```

- **整数提升（integer promotion）是表达式中算术操作符的操作数转换规则的一部分。**
- 这使得 `uint8_t`、`char` 等类型在参与算术运算时，都会先“变成” `int` 或 `unsigned int`，确保计算过程安全且符合预期。

这个规则是针对**表达式中运算符操作数的隐式类型转换**，不等同于直接写的变量定义，比如

```cpp
uint8_t g = 0x80;
int y = g; // 这里也是隐式转换，但不是算术运算，叫做整型转换
```

### 移位（bit shift）操作中的隐患

当使用小整数类型（如 `uint8_t`）进行移位操作时，很容易**在未转换类型的情况下发生隐式提升和溢出问题**。

#### 错误示例

```cpp
uint8_t g1 = 0x80;
uint32_t key = (g1 << 24); // 错误：g1 被提升为 int，再左移，结果为负数！
```

这个表达式中，`g1` 是 `uint8_t`，但它会被自动提升为 `int`：

- 所以等价于：`(int(g1) << 24)`
- `int(128) << 24` == `0x80000000`
- 这是 **int** 类型中的一个**负数**（`-2147483648`）

最终把这个负数放进了 `uint32_t`：

```cpp
uint32_t key = int(-2147483648); // 结果仍然是 0x80000000，数值是对的
```

- **结果是对的，但过程是危险的**

#### 危险在哪？

根据 C++ 标准：

> 移位操作如果作用在负数上，行为是未定义的。

如果写：

```cpp
int a = -1;
int b = a << 1;  // 未定义行为
```

这种 `(int(g1) << 24)` 的中间结果**可能就是负数**，**不符合 C++ 的类型安全**。

#### 正确使用示例

用 **类型提升** 避免依赖：

```cpp
uint8_t g1 = 0x80;
uint32_t key = (uint32_t(g1) << 24); // 强制提升为无符号整数后移位
```

这样可以避免中间变成负数，避免任何未定义行为的风险。

### 推荐使用 uint64_t 做拼接

拼接多个 `uint8_t` 时：

```cpp
uint64_t key = (uint64_t(g1) << 24) |
               (uint64_t(g2) << 16) |
               (uint64_t(g3) << 8)  |
               (uint64_t(g4));
```

相对 uint32_t 的优势：

| 项目           | `uint32_t`                       | `uint64_t`                |
| -------------- | -------------------------------- | ------------------------- |
| 安全性         | 若某个 `gX` 未显式转换，容易溢出 | 宽度更大，溢出风险低      |
| 可容纳的位数   | 32 位，刚好 4×8 位               | 64 位，冗余位宽，移位安全 |
| 对于调试和扩展 | 容易溢出难发现                   | 冗余位数让调试更安心      |

### 示例代码对比

```cpp
#include <iostream>
#include <cstdint>

// 打印一个 32 位整数的十进制和十六进制表示
void print(uint32_t val) {
    std::cout << "Decimal: " << val << ", Hex: 0x" 
              << std::hex << val << std::dec << "\n";
}

int main() {
    // 四个 8 位基因值，g1 = 0x80 是关键，它的高位是 1，会触发符号位问题
    uint8_t g1 = 0x80, g2 = 0x01, g3 = 0x02, g4 = 0x03;

    // 错误写法：
    // 每个 uint8_t 在移位时会自动提升为 int，而不是 uint32_t
    // 如果提升后的 int 是负数（比如 g1 << 24 = 0x80000000），结果可能有符号解释
    uint32_t wrong = (g1 << 24) | (g2 << 16) | (g3 << 8) | g4;
    std::cout << "Wrong: ";
    print(wrong);  // 可能输出错误，依赖平台实现

    // 正确写法：
    // 显式将每个 uint8_t 转换为 uint32_t 后再移位
    // 避免了整型提升导致的负数参与运算，结果是完全可靠的
    uint32_t correct = (uint32_t(g1) << 24) | (uint32_t(g2) << 16) |
                       (uint32_t(g3) << 8) | uint32_t(g4);
    std::cout << "Correct: ";
    print(correct);  // 输出稳定，逻辑正确

    // 推荐安全写法（尤其用于哈希、跨平台）：
    // 用更大的 uint64_t 来保存拼接结果，可以避免溢出或中间值截断
    uint64_t safe = (uint64_t(g1) << 24) | (uint64_t(g2) << 16) |
                    (uint64_t(g3) << 8) | uint64_t(g4);
    std::cout << "64-bit safe: " << std::hex << safe << std::dec << "\n";

    return 0;
}
```

