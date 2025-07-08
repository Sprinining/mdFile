## 条款34：优先使用 Lambda 而非 std::bind

- `std::bind` 是 C++98 中 `std::bind1st` 和 `std::bind2nd` 的后续版本，2005年成为非正式标准库一部分。
- C++11 引入了 lambda，C++14 中 lambda 功能更加强大。
- 现在，lambda 几乎总是比 `std::bind` 更好的选择。

### 为什么优先使用 lambda？

#### 可读性和直观

- Lambda 代码像普通函数调用，易于理解。
- `std::bind` 使用占位符（如 `_1`, `_2`），对不熟悉的人来说是“魔法”，不直观。
- 例如，设置一个一小时后响铃30秒的闹钟：

```cpp
// Lambda版本（清晰）
auto setSoundL = [](Sound s) {
    using namespace std::chrono;
    setAlarm(steady_clock::now() + 1h, s, 30s);
};

// std::bind版本（含占位符，且有问题）
using namespace std::placeholders;
auto setSoundB = std::bind(setAlarm, steady_clock::now() + 1h, _1, 30s);
```

#### 表达式求值时机不同

- Lambda 中，`steady_clock::now() + 1h` 在调用时求值，符合预期。
- `std::bind` 中，表达式在创建绑定对象时就求值，导致时序错误。

#### 函数重载歧义

- Lambda 通过重载解析可以正确调用重载函数。
- `std::bind` 需要强制转换函数指针来消除重载歧义，写法复杂。

#### 内联优化

- Lambda 调用函数可以内联，效率更高。
- `std::bind` 使用函数指针调用，不易内联，可能影响性能。

### 代码复杂度示例对比

**Lambda 版本：**

```cpp
auto betweenL = [lowVal, highVal](const auto& val) {
    return lowVal <= val && val <= highVal;
};
```

**std::bind 版本：**

```cpp
using namespace std::placeholders;
auto betweenB = std::bind(std::logical_and<>(),
                         std::bind(std::less_equal<>(), lowVal, _1),
                         std::bind(std::less_equal<>(), _1, highVal));
```

- Lambda 简洁易懂，`std::bind`晦涩难懂。

### 捕获方式的显式性

- Lambda 捕获明确写出是按值还是按引用。
- `std::bind` 总是拷贝参数，除非使用 `std::ref`，但无法直观看出。

### std::bind 仍有少数合理用例（C++11限定）

1. **移动捕获**
    C++11 lambda 不支持移动捕获，可以用 `std::bind` 结合 lambda 模拟（见条款32）。
2. **多态函数对象绑定**
    绑定带模板 `operator()` 的函数对象，`std::bind` 的函数调用运算符使用完美转发，支持多态。