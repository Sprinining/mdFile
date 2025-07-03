## auto 类型推导

### auto 与模板类型推导的对应关系

虽然 `auto` 不直接用于模板、函数或形参，但它与模板类型推导之间存在**一一映射的关系**，可以通过一个非常规范和系统的流程相互转换。

#### 对应关系类比

```cpp
template<typename T>
void f(ParamType param);     // 模板形式

f(expr);                     // 使用 expr 推导 T 和 ParamType
```

等价于：

```cpp
auto x = expr;               // auto 扮演 T，auto 所在位置的类型说明符扮演 ParamType
```

#### 示例转换

```cpp
auto x = 27;
// 相当于：
template<typename T>
void func_for_x(T param);
func_for_x(27);              // T 推导为 int

const auto cx = x;
// 相当于：
template<typename T>
void func_for_cx(const T param);
func_for_cx(x);              // T 推导为 int，cx 类型为 const int

const auto& rx = x;
// 相当于：
template<typename T>
void func_for_rx(const T& param);
func_for_rx(x);              // T 推导为 int，rx 类型为 const int&
```

### auto 推导对应模板类型推导的三种情景

在模板类型推导中，将推导情况分为三种：

| 情景 | 类型说明符                         |
| ---- | ---------------------------------- |
| 1    | 指针或引用，但不是万能引用         |
| 2    | 万能引用（`T&&`）                  |
| 3    | 既不是指针也不是引用（非引用类型） |

对应 `auto` 示例：

```cpp
auto x = 27;                  // 情景三：非引用类型
const auto cx = x;            // 情景三：非引用类型
const auto& rx = cx;          // 情景一：非万能引用

auto&& uref1 = x;             // 情景二：x 是 int 左值，推导为 int&
auto&& uref2 = cx;            // 推导为 const int&
auto&& uref3 = 27;            // 右值，推导为 int&&
```

### 数组和函数的退化行为

`auto` 类型推导中，数组和函数名的退化与模板推导一致：

```cpp
const char name[] = "flash bang";
auto arr1 = name;             // const char*
auto& arr2 = name;            // const char (&)[11]

void someFunc(int, double);
auto func1 = someFunc;        // void (*)(int, double)
auto& func2 = someFunc;       // void (&)(int, double)
```

### 唯一的区别：大括号初始化 `{}`

这是 `auto` 类型推导与模板类型推导**唯一的重大区别**。

```cpp
int x1 = 27;
int x2(27);
int x3 = { 27 };
int x4{ 27 };
// 四者类型均为 int，值为 27

auto x1 = 27;                 // int
auto x2(27);                  // int
auto x3 = { 27 };             // std::initializer_list<int>
auto x4{ 27 };                // std::initializer_list<int>
```

- 当使用大括号 `{}` 初始化时，`auto` 会推导为 `std::initializer_list<T>`

- 如果不能推导出 `initializer_list`（例如元素类型不一致），编译会报错：

```cpp
auto x5 = { 1, 2, 3.0 };      // ❌ 错误：无法推导为统一类型的 initializer_list
```

此时发生了两层推导：

- `auto` 推导变量类型为 `std::initializer_list<T>`
- `std::initializer_list<T>` 的模板参数 T 也需要推导

### 模板类型推导与大括号初始化不兼容

```cpp
auto x = { 11, 23, 9 };       // 推导成功：std::initializer_list<int>

template<typename T>
void f(T param);

f({ 11, 23, 9 });             // ❌ 错误：模板推导无法识别大括号中的类型
```

正确的模板声明方式：

```cpp
template<typename T>
void f(std::initializer_list<T> initList);

f({ 11, 23, 9 });             // ✔️ T 推导为 int，initList 类型为 std::initializer_list<int>
```

### C++14 中 auto 的新用法限制

C++14 扩展了 `auto` 的用法 —— 可以用于函数返回值、lambda 参数中，但这时**并不采用 auto 类型推导，而是使用模板类型推导规则**。

#### 函数返回值中的 auto

```cpp
auto createInitList() {
    return { 1, 2, 3 };       // ❌ 错误：无法推导出 return 列表的类型
}
```

#### lambda 参数中的 auto

```cpp
std::vector<int> v;

auto resetV = [&v](const auto& newValue){ v = newValue; };

resetV({ 1, 2, 3 });          // ❌ 错误：无法推导 { 1, 2, 3 } 的类型
```

### 总结

- `auto` 类型推导几乎等同于模板类型推导，两者是等价体系。
- **唯一的差异**是：
  - `auto` 遇到大括号初始化（`{}`）时会尝试推导为 `std::initializer_list<T>`。
  - 模板类型推导则对 `{}` 无能为力，除非显式指定类型为 `std::initializer_list<T>`。
- **C++14 扩展的用法**（函数返回值、lambda 参数中的 `auto`）实际使用的是模板类型推导规则，不支持 `{}` 初始化。

- 在 C++11/14 编程中要警惕 `auto` 的大括号初始化陷阱，除非你明确需要 `std::initializer_list`，否则建议优先使用 `=` 或 `()` 方式初始化。