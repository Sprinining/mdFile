## 条款5：优先考虑`auto`而非显式类型声明

优先使用 `auto` 代替显式类型声明，除非这样会损害代码的可读性或导致类型推导错误。使用 `auto` 不只是图省事，它能带来：

- 更强的类型安全
- 更少的重复
- 更高的可移植性
- 更少的维护负担

### 避免未初始化变量

```cpp
int x;      // 可能未初始化
auto y;     // 错误！必须初始化
auto z = 0; // 初始化为0
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

- Lambda 在 C++ 中的类型是由编译器生成的一个匿名类类型（closure type，闭包类型）。

- 这种类型没有名字，不能直接写成 `SomeType cmp = ...;`。

- 但 `auto` 可以自动推导类型，所以我们写：

  ```cpp
  auto cmp = ...;
  ```

  就能保存这个 lambda。

### 节省闭包的空间与调用开销

```cpp
// auto 保存的是编译器生成的闭包对象，直接存在栈上或对象里，没有额外内存分配。
auto cmp = [](...) { ... };
// std::function 可能有堆分配、类型擦除和额外的运行时开销。
std::function<...> cmp = ...;
```

#### lambda 本质

```cpp
auto f = [x = 42](int y) { return x + y; };
```

编译器会生成一个类似这样的闭包类：

```cpp
struct __lambda {
    int x;  // 捕获的变量
    int operator()(int y) const { return x + y; }
};
```

这里 `f` 就是一个栈上对象，大小 = `sizeof(int)`，没有堆分配。

#### std::function 的目标

`std::function` 设计的目的是**统一保存任意可调用对象**（函数指针、函数对象、lambda……），让它们有一个相同的接口：

```cpp
std::function<int(int)> f;
```

不管放进去的是：

- 普通函数 `int foo(int);`
- lambda `[](int x){ return x+1; }`
- 有状态的闭包 `[a,b](int x){ return a*x+b; }`

`std::function` 都要用相同的方式保存和调用。

这就需要**类型擦除**：隐藏真实类型，只暴露一个统一的调用接口。

#### 为什么会有堆分配

闭包对象的大小编译时是不确定的，可能很小（捕获一个 `int`），也可能很大（捕获几十个成员）。`std::function` 不能为每种大小都预留固定空间，所以常见实现会这样做：

- **小对象优化（Small Object Optimization, SOO）**：如果闭包对象很小（比如几个指针大小），直接存在 `std::function` 内部的缓冲区，不需要堆分配。
- **大对象处理**：如果闭包对象很大，放不下，就只能在**堆上动态分配内存**，然后 `std::function` 里保存一个指针指向它。

#### 调用的额外间接层

- `auto f = lambda;`
  调用时直接走闭包的 `operator()`，可以内联，几乎零开销。
- `std::function f = lambda;`
  内部调用流程是：
  1. 找到保存的函数对象（可能在堆上）。
  2. 通过虚拟表/函数指针调用它。

这就比 `auto` 慢，尤其是在循环里调用很多次时差别明显。

### 避免类型缩窄与类型不匹配

```cpp
std::vector<int> v;
unsigned sz = v.size(); // 潜在的类型问题
auto sz = v.size();     // 正确，自动推导为 size_type
```

- `vector::size()` 返回 `size_t`（64 位无符号整数）。
- 手动写成 `unsigned`（32 位）时，如果容器很大，会**溢出/截断**。
- 用 `auto` 就不会有问题，因为类型能正确推导成 `size_t`。

### 防止临时对象问题（引用绑定）

```cpp
for (const std::pair<std::string, int>& p : m) // 错误！m 中元素是 pair<const std::string, int>
for (const auto& p : m)                        // 正确！类型精确匹配，避免隐式拷贝和悬空引用
```

- `map<K,V>` 的元素类型是 `pair<const K, V>`，key 一定是 `const`。
- 如果手动写成 `pair<K,V>`，就和实际类型不一致，会报错或导致拷贝。
- `auto` 能自动推导正确的 `pair<const K,V>` 类型，更安全、更高效。

#### 隐式拷贝的问题

如果手写了**不完全匹配的类型**：

```cpp
for (const std::pair<std::string, int> p : m) { ... }
```

- `m` 的元素类型是 `std::pair<const std::string, int>`
- 编译器会生成一个**新的 `pair<std::string, int>` 对象**，从 `pair<const std::string, int>` **拷贝构造**而来。
- 每次迭代都发生一次 **额外的拷贝**（性能损耗）。
- 对于 `std::string` 这种对象，拷贝意味着堆内存分配和复制，更加昂贵。

而 `auto` 会精确推导为 `const std::pair<const std::string, int>&`，**直接引用容器里的元素，不会发生拷贝**。

####  悬空引用的问题

如果手写了一个**错误的引用类型**：

```cpp
for (const std::pair<std::string, int>& p : m) { ... } // 错误类型
```

- 这里期望绑定的是 `pair<std::string, int>&`
- 但 `m` 里的元素是 `pair<const std::string, int>`
- 类型不匹配，C++ 不允许直接绑定，编译器会尝试创建一个**临时对象** `pair<std::string, int>` 来匹配。

然后再把 `const std::pair<std::string, int>& p` 绑定到这个临时对象上。

问题：

- 临时对象只在本次循环迭代结束前有效。
- 如果把 `p` 存到了别处（比如返回、放进容器里），那么在循环结束后它就悬空了，变成**悬空引用 **。
- 即使没存出去，这个过程也导致了**多余的临时对象构造和析构**。

### 更有利于重构与维护

函数返回类型修改，`auto` 自动跟随，不需要手动修改变量类型。

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