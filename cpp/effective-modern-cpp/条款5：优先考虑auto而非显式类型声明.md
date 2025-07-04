## 条款5：优先考虑`auto`而非显式类型声明

- 优先使用 `auto` 代替显式类型声明，除非这样会损害代码的可读性或导致类型推导错误。

- 使用 `auto` 不只是图省事，它能带来：

  - **更强的类型安全**

  - **更少的重复**

  - **更高的可移植性**

  - **更少的维护负担**

### 避免未初始化变量

```cpp
int x;     // 可能未初始化
auto y;    // 错误！必须初始化
auto z = 0; // OK，初始化为0
```

### 简化复杂类型声明

```cpp
typename std::iterator_traits<It>::value_type val = *b;
// 简化为：
auto val = *b;
```

### 可用于无法书写的类型（如闭包）

```cpp
auto cmp = [](const auto& a, const auto& b) { return *a < *b; };
```

### 节省闭包的空间与调用开销

- `auto` 保存闭包不会发生堆分配，调用更快。
- `std::function` 可能有堆分配、类型擦除和额外的运行时开销。

```cpp
auto cmp = [](...) { ... };           // 高效
std::function<...> cmp = ...;         // 慢，冗长，占内存
```

### 避免类型缩窄与类型不匹配

```cpp
std::vector<int> v;
unsigned sz = v.size(); // 潜在的类型问题
auto sz = v.size();     // 正确，自动推导为 size_type
```

### 防止临时对象问题（引用绑定）

```cpp
for (const std::pair<std::string, int>& p : m) // 错误！m中元素是 pair<const std::string, int>
for (const auto& p : m)                        // 正确！类型精确匹配，避免隐式拷贝和悬空引用
```

### 更有利于重构与维护

- m函数返回类型修改，`auto` 自动跟随，不需要手动修改变量类型。

某些情况下推导结果与预期不同，比如：

```cpp
const int x = 42;
auto y = x;         // y 是 int，而不是 const int
auto& z = x;        // z 是 const int&
```

关于可读性争议

- 经验和 IDE 支持可以弥补 `auto` 带来的可读性问题。
- 合理命名变量能表达抽象意义（如 `count`, `ptr`, `widgetMap`）。
- `auto` 避免了类型重复、简化了阅读成本。