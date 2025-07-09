## 条款15：尽可能使用 constexpr

`constexpr` 表示一个值 **不仅是常量（`const`）**，**而且必须在编译期已知（compile-time constant）**。

### `constexpr` 对象 vs 函数

| 用法             | 描述                                                         |
| ---------------- | ------------------------------------------------------------ |
| `constexpr` 变量 | 必须在编译期能被计算，且隐含 `const`。                       |
| `constexpr` 函数 | 如果传入编译期常量，结果也会是编译期常量；否则在运行期计算。 |

### `constexpr` 对象

- 所有 `constexpr` 对象都是 `const`。
- 但并非所有 `const` 对象都是 `constexpr`（因为 `const` 对象可以运行期初始化）。

**适用场景：**

- 数组长度、模板参数、枚举值、对齐修饰符等 **需要整型常量表达式（ICE）** 的地方。

```cpp
constexpr int size = 10;
std::array<int, size> arr;  // ✅ 正确，size 是编译期常量

const int runtimeSize = getValue();  // ❌ 非 constexpr
std::array<int, runtimeSize> arr;   // ❌ 编译错误
```

### `constexpr` 函数

- 如果实参是编译期可知的常量 → 在编译期执行
- 如果实参不是编译期常量 → 像普通函数一样在运行时执行

```cpp
constexpr int pow(int base, int exp) noexcept {
    return (exp == 0 ? 1 : base * pow(base, exp - 1));
}
```

### C++11 vs C++14 中的 `constexpr` 限制

| C++11 限制                          | C++14 改进                        |
| ----------------------------------- | --------------------------------- |
| 只能有一条 return 语句              | 允许多语句、变量定义、循环等      |
| 成员函数隐式 `const`                | 可以有非常量成员函数（如 `setX`） |
| 返回类型必须是字面值类型（Literal） | 更灵活（支持 `void` 返回等）      |

C++14 中更自然的写法：

```cpp
constexpr int pow(int base, int exp) noexcept {
    int result = 1;
    for (int i = 0; i < exp; ++i) result *= base;
    return result;
}
```

### `constexpr` 类的构造和成员函数

```cpp
class Point {
public:
    constexpr Point(double x = 0, double y = 0) noexcept : x(x), y(y) {}
    constexpr double xValue() const noexcept { return x; }
    constexpr double yValue() const noexcept { return y; }
	
    // 可以有非常量成员函数
    constexpr void setX(double newX) noexcept { x = newX; }  // C++14+
    constexpr void setY(double newY) noexcept { y = newY; }  // C++14+

private:
    double x, y;
};
```

可以在 `constexpr` 函数中构造对象、访问成员、进行计算：

```cpp
constexpr Point midpoint(const Point& p1, const Point& p2) noexcept {
    return Point{ (p1.xValue() + p2.xValue()) / 2,
                  (p1.yValue() + p2.yValue()) / 2 };
}
```

### `constexpr` 的用途示例

- 编译期计算表达式（替代浮点 std::pow）
- 实例化模板参数
- 初始化静态数组长度
- 更高效：常量放入只读内存

### 注意事项

#### 优点

- `constexpr` 对象和函数 **使用场景更多**。
- 编译器可 **更早发现错误**，还能进行 **性能优化**（如内联、常量传播等）。

#### 风险

- `constexpr` 是**接口的一部分**。
- **一旦加入就不能轻易移除**，否则会破坏调用代码。
- 添加调试语句（如 I/O）或异常处理可能使函数不再 `constexpr`。

#### 设计建议

- 如果函数能 **始终在编译期求值**，就声明为 `constexpr`。
- 不要为了 `constexpr` 而强行写死函数逻辑。
- 对于长期稳定性有要求的接口，谨慎添加 `constexpr`。

### 总结

| 建议                          | 原因                                       |
| ----------------------------- | ------------------------------------------ |
| 尽可能使用 `constexpr`        | 提高函数和变量的适用范围，提升性能与可靠性 |
| 优先用于编译期必须常量的位置  | 如模板参数、数组大小、`alignas`、枚举值等  |
| C++14 更适合 `constexpr` 编程 | 支持更丰富的函数体和返回类型               |
| 不盲目添加                    | 一旦添加，影响接口兼容性                   |