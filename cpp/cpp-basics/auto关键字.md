## auto关键字

`auto` 是 C++ 中一个非常有用的关键字，用于**自动类型推断（type inference）**。从 C++11 开始引入，在 C++14 和 C++17 中功能不断增强。

### auto 是什么？

`auto` 让编译器根据变量的**初始值**自动推导其类型，避免显式地写出复杂冗长的类型名。

```cpp
auto x = 10;       // int
auto y = 3.14;     // double
auto z = "hello";  // const char*
```

### 典型用法

#### 简化类型推导（特别是模板和复杂类型）

```cpp
std::map<std::string, std::vector<int>> mp;
// 不用写 std::map<std::string, std::vector<int>>::iterator
for (auto it = mp.begin(); it != mp.end(); ++it) {
    std::cout << it->first << "\n";
}
```

#### 简化迭代器声明

```cpp
std::vector<int> vec = {1, 2, 3, 4};
for (auto it = vec.begin(); it != vec.end(); ++it) {
    std::cout << *it << " ";
}
```

#### 用于函数返回值

```cpp
auto getValue() {
    return 42; // 推导为 int
}
```

这种形式必须有 return 语句，编译器才能推导出类型。

### 细节与注意事项

#### `auto` 推导会**忽略 const/reference/volatile**，除非显式指定

```cpp
int a = 5;
const int& b = a;
auto x = b;     // x 是 int，不是 const int&
auto& y = b;    // y 是 const int&，因为用了 &
```

属于类型推导中的第三类：**形参既非指针/引用，也非万能引用**：

- 实参如果是引用，推导时忽略引用部分。
- 忽略引用后，如果实参是顶层 `const` 或 `volatile`，也会被忽略。

#### 和指针、引用搭配使用

```cpp
int a = 10;
auto* p = &a;    // int*
auto& r = a;     // int&
```

属于类型推导中的第一类：**形参是指针或引用类型，但不是万能引用**：

- 若 `expr` 具有引用类型，则首先忽略引用部分
- 然后对 `expr` 的类型和 `ParamType` 的类型执行模式匹配，决定 `T` 的类型

### C++ 各版本中 auto 的演进

#### **C++98 / C++03**

**`auto` 是一个存储类型说明符 (storage class specifier)**，含义是 **“自动存储期”**。但所有局部变量默认就是自动存储期，所以这个关键字基本上是 **鸡肋**，几乎没人用。

```cpp
auto int x = 5; // 表示 x 是一个自动存储期的 int，等价于 int x = 5;
```

实际开发中几乎没见过。

#### **C++11**

`auto` 语义 **彻底重定义**：**用来做类型推导**，根据初始化表达式自动推导变量的类型。

```cpp
auto x = 1;        // int
auto y = 1.5;      // double
auto z = &x;       // int*
```

类似函数模板参数推导：

- 会丢掉 `const`/`volatile`（除非加 `&` 或 `*`）。
- 引用折叠规则也适用。

#### **C++14**

进一步扩展了 `auto`：

- **函数返回类型自动推导**

  ```cpp
  auto foo() {
      return 42;   // 返回 int
  }
  ```

- **Lambda 参数类型推导**

  ```cpp
  auto f = [](auto x, auto y) { return x + y; };
  cout << f(1, 2.5); // double
  ```

#### **C++17**

扩展：

- **结构化绑定（structured bindings）**

  ```cpp
  auto [a, b] = std::pair(1, 2.0); // a:int, b:double
  ```

- **非类型模板参数中的 auto**

  ```cpp
  template <auto N>
  void foo() { std::cout << N; }
  foo<10>();  // 推导 N 为 int
  ```
  
  - **函数模板**：模板参数是 **类型**，`auto` 用来推导类型。
  - **非类型模板参数 (NTTP)**：模板参数是 **值**，`auto` 用来推导值的类型。

#### **C++20**

- **`auto` 可以作为模板形参 (abbreviated function template)**：

  ```cpp
  auto add(auto a, auto b) { return a + b; } // 等价于模板函数
  ```

- **概念 (concepts) + auto**，形成受约束的类型推导：

  ```cpp
  auto add(std::integral auto a, std::integral auto b) { return a + b; }
  ```

#### **C++23**

- **`deducing this`**：成员函数可以用 `auto` 来推导 `this` 的类型。

  ```cpp
  struct S {
      void f(this auto&& self) { /* self 可推导为 S&, const S&, S&& ... */ }
  };
  ```

### auto 的陷阱

#### 推导精度不匹配

```cpp
auto x = 3.0f;  // x 是 float
auto y = 3.0;   // y 是 double

auto z = x + y; // 发生了 float + double
```

`auto` 推导的结果**依赖右值的字面量类型**，像 `3.0f` 推导成 `float`，`3.0` 推导成 `double`，这在混用时会导致**精度不匹配**，容易产生意料之外的类型转换，应加以留意或显式指定类型。

#### 容易忽略拷贝 vs 引用

```cpp
std::vector<int> v = {1, 2, 3};
for (auto x : v) { x = 0; }       // 改变的是副本
for (auto& x : v) { x = 0; }      // 改变原始容器
```

当用 `auto` 声明变量时，**可能会无意中复制对象（拷贝）**，而不是本意想要的**引用（引用/别名）**，从而导致性能下降、逻辑错误或修改无效等问题。

### 和 decltype 的关系

`auto` 是“编译器根据值推导类型”，`decltype` 是“编译器根据表达式**本身**判断类型”。

| 特性       | 含义                                                         |
| ---------- | ------------------------------------------------------------ |
| `auto`     | 编译器根据 **右值的结果（赋值的值）** 来推导变量类型（通常是去掉引用、cv 修饰的“值”） |
| `decltype` | 编译器根据 **表达式本身的类型** 推导（包括是否是引用、常量等） |

#### `decltype` 的规则（核心）

- **规则 1**：如果表达式是一个不加括号的标识符（比如 `x`），那么 `decltype(x)` 的结果就是 **它的声明类型**。

  ```cpp
  int x = 0;
  decltype(x) a;  // a 是 int
  ```

- **规则 2**：如果表达式是一个 **左值表达式**（不是单纯的标识符，而是更一般的表达式，比如 `(x)`、`*p`、`x+0` 的某些情况等），那么 `decltype(expr)` 的结果是 **T&**，其中 T 是表达式的类型。

  ```cpp
  int x = 0;
  decltype((x)) b = x; // (x) 是左值表达式 → b 的类型是 int&
  ```

- **规则 3**：如果表达式是一个 **将亡值 (xvalue)**，则推导为 `T&&`。

- **规则 4**：如果表达式是一个 **纯右值 (prvalue)**，则推导为 `T`。

#### 例子对比

```cpp
int i = 0;
int& ri = i;

auto a = ri;      // a 是 int（引用被忽略）
decltype(ri) b = i; // b 是 int&（引用保留）
```

再复杂一点：

```cpp
int x = 10;
decltype((x)) a = x;  // 注意：a 是 int&（因为 (x) 是一个 lvalue 表达式）
decltype(x)  b = x;   // b 是 int（变量名是 lvalue，但 decltype 不加括号只看类型声明）
```

#### 使用场景


| 你想做什么                       | 用哪个？                    | 说明                             |
| -------------------------------- | --------------------------- | -------------------------------- |
| 自动声明变量（不关心引用/const） | `auto`                      | 简洁、方便                       |
| 精确获取表达式类型（保留引用等） | `decltype`                  | 精度高、适合模板、泛型编程等场景 |
| 用于泛型函数返回值（C++11 起）   | `decltype`                  | `decltype(f(x))` 推导返回值类型  |
| 与 `auto` 搭配做尾返回类型       | `auto f() -> decltype(...)` | 用于需要明确函数返回类型的场景   |
