## C++ bind

`std::bind` 是 C++11 引入的一个函数适配器，用于**创建一个可调用对象**，**提前绑定部分参数**（也叫“占位绑定”或“柯里化”）。

它的本质是返回一个新的函数对象，这个对象**封装了原函数+部分参数**，等到调用时再传入剩余参数。

```cpp
std::bind(可调用对象, 参数1, 参数2, ...)
```

- 参数可以是具体值（代表绑定值）或占位符（代表保留参数）
- 占位符使用 `std::placeholders::_1`、`_2` 等来表示函数调用时传入的位置参数

### 绑定普通函数

```cpp
#include <iostream>
#include <functional>
#include <cmath>  // 为了使用 std::pow

// 自定义的 power 函数，接收 double 类型参数
double power(double base, double exp) {
    return std::pow(base, exp);
}

int main() {
    // 通过 std::bind 固定指数为 3，形成一个 cube 函数
    auto cube = std::bind(power, std::placeholders::_1, 3.0);

    std::cout << "cube(2.0) = " << cube(2.0) << std::endl;  // 输出 8
    return 0;
}
```

- 将 `pow(x, y)` 的第二个参数绑定为 `3.0`
- `_1` 是占位符，表示实际调用时传入第一个参数是 base
- `std::bind(power, _1, 3.0)`：生成一个一元函数 `cube(x)`，等价于 `power(x, 3.0)`。

### 绑定成员函数

```cpp
struct Printer {
    void print(const std::string& msg) const {
        std::cout << "Message: " << msg << std::endl;
    }
};

int main() {
    Printer p;
    auto boundPrint = std::bind(&Printer::print, &p, std::placeholders::_1);
    boundPrint("Hello from bind!");  // 输出 Message: Hello from bind!
}
```

- `&Printer::print` 是成员函数指针
- `&p` 是对象指针
- `_1` 表示实际调用时填入 print 的参数

### 与 Lambda 的对比

| 特性     | `std::bind`              | Lambda                 |
| -------- | ------------------------ | ---------------------- |
| 可读性   | 稍复杂                   | 简洁明了               |
| 灵活性   | 可绑定成员函数、占位符   | 功能强，语法灵活       |
| 性能     | 稍慢（可能生成复杂对象） | 一般更快，编译器优化好 |
| 推荐程度 | **不如 Lambda 常用**     | 更现代、更推荐         |
