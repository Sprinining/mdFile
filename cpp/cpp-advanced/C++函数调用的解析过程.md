## C++ 函数调用的解析过程

### 总览：编译器如何决定“叫谁”

给定一次调用表达式 `f(args...)`（或 `obj.f(args...)`、`op(args...)`）：

- **名称查找（Name Lookup）**：先在可见作用域查找；非限定调用触发 **ADL（Argument-Dependent Lookup）**；成员调用先找类及基类成员。
- **构造候选集（Candidate Set）**：收集普通函数、函数模板；运算符调用额外包括内建和用户自定义候选；成员函数考虑隐式对象形参。
- **模板实参推导**：根据实参类型推导模板参数；失败的排除（SFINAE）；C++20 Concepts 检查约束。
- **可行函数判定（Viable）**：参数数量、默认实参、参数包匹配；实参可通过标准或一次用户自定义转换匹配形参。
- **隐式转换序列分级（ICS）**：Exact > Promotion > Conversion > 用户自定义转换 > Ellipsis。
- **择优**：比较各候选的 ICS；若难分胜负，应用“非模板优先、更特化优先、非变参优先”等规则；无法判定 → 二义性。

### 名称查找（含 ADL 与隐藏）

- **限定查找**：`A::f`、`std::swap` 只在指定范围查找。
- **非限定查找**：逐作用域向上，再加上 ADL（在实参的关联命名空间/类内找函数）。
- **友元函数**：若定义在类内部且无命名空间声明，通常只能通过 ADL 被找到。
- **隐藏**：派生类的同名成员隐藏基类所有同名重载；用 `using Base::f;` 可引入基类重载集。

### 候选集构造

- 普通函数与函数模板均入集；
- 运算符调用：内建候选 + 用户自定义 `operator@`；
- 成员函数：考虑隐式对象形参。

### 模板实参推导

- 推导来源：形参模式 vs 实参类型。
- **非推导上下文**：如 `T::type`、`decltype(expr)` 内的 `T`。
- **转发引用**：`T&&` 在推导时左值实参使 `T` 推为 `U&`，折叠为 `U&`。
- **SFINAE**：推导出错 → 排除该模板。
- **Concepts**：推导完成后检查 `requires`，不满足则剔除。

### 可行函数与参数匹配

- 参数个数需符合（默认值/参数包）。
- 每个实参：
  - 允许一次用户自定义转换（构造函数/转换函数），前后可有标准转换；
  - 或仅标准转换；
  - 或匹配 `...`（最差）。
- 列表初始化有特殊规则。

### 成员函数与隐式对象形参

- `obj.f(args)` 时，`obj` 参与匹配成员函数的 **cv 限定与 ref-qualifier**。

- 例如：

  ```cpp
  struct S {
    void g() &;
    void g() &&;
    void g() const&;
  };
  S s;  s.g();   // 调用 g() &
  S{} .g();     // 调用 g() &&
  ```

### 隐式转换序列（ICS）与分级

- **Exact Match**：无转换、顶层 cv 调整、引用绑定、数组/函数退化。
- **Promotion**：小整型到 int、float 到 double 等。
- **Conversion**：整数间转换、浮点间转换、整型与浮点间转换、派生到基类、指针 cv 加深。
- **用户自定义转换**：一次构造函数或转换函数，可前后接标准转换。
- **省略号转换**：匹配 `...`，最差。

### 最佳可行函数判定

- 比较每个实参的 ICS：若一个候选在至少一个实参更好，且其它不差 → 更优。
- 若难分胜负，次级规则：
  - 非模板优于模板；
  - 更特化的模板优于泛化模板（部分序）；
  - 非可变参数优于可变参数。
- 无法判定则报二义性。

### 模板部分序与约束

- **部分序**：比较模板形参模式谁更特化，例如 `f(T*)` 比 `f(T)` 特化。
- **Concepts**：约束不决定“更特化”，但可在可行性阶段剔除不满足者。

### 列表初始化与 `initializer_list`

- `f(std::initializer_list<U>)` 在花括号调用中优先。

- 构造函数：

  ```cpp
  struct X {
    X(int,int);
    X(std::initializer_list<int>);
  };
  X a(1,2);   // (int,int)
  X b{1,2};   // initializer_list<int>
  ```

### 引用绑定与值类别

```cpp
void g(T&);       // 左值优先
void g(const T&); // 通用兜底
void g(T&&);      // 右值优先
```

- 左值 → 选 `T&`；
- 右值 → 选 `T&&`；
- 若无匹配，则退到 `const T&`。

### ADL 的关键点

- 标准用法：

  ```cpp
  using std::swap;
  swap(a,b); // ADL 找到用户定义的 swap
  ```

- 友元仅通过 ADL 可见：

  ```cpp
  struct X{ friend void h(X){} };
  X x; h(x); // ADL 找到
  ```

### 转换构造与 `explicit`

- 隐式匹配时只能使用非 `explicit` 的构造函数/转换函数。
- C++20 起 `explicit(bool)` 可上下文决定，但用于参数匹配仍需允许隐式。

### 运算符重载与内建候选

- 对 `a+b`：考虑成员 `operator+`、非成员 `operator+`、内建算术候选。
- 非成员运算符更灵活，因两边都能做隐式转换；成员只能对右操作数转换。

### 常见例子

```cpp
struct S{
  void f() &;
  void f() &&;
};
S s; s.f();   // 选 f() &
S{} .f();     // 选 f() &&

void g(int);
template<class T> void g(T);
g(1);         // 选 g(int)

template<class T> void h(T);
template<class T> void h(T*);
int* p; h(p); // 选指针版
```

### 常见二义性与排错

- 二义性来源：多个候选同等优劣；模板部分序无法决出胜负。
- 解决方法：
  - 限定命名或显式类型转换；
  - `using Base::f;` 引入隐藏重载；
  - 删除/`=delete` 不需要的重载；
  - 使用 Concepts 或 `requires` 限制。

### 示例

```cpp
#include <iostream>
#include <type_traits>

// 一般函数
void foo(int) { std::cout << "foo(int)\n"; }

// 模板函数1：要求参数能相加
template<typename T>
auto foo(T t) -> decltype(t + t, void()) {
    std::cout << "foo(T) with operator+\n";
}

// 模板函数2：要求参数有成员 bar()
template<typename T>
auto foo(T t) -> decltype(t.bar(), void()) {
    std::cout << "foo(T) with bar()\n";
}

struct A {};              // 普通类型
struct B { int bar(); };  // 有成员 bar()
struct C {};              // 普通类型，但后面会触发二义性

int main() {
    foo(10);   // 调用 foo(int)
    foo(B{});  // 调用 foo(T) with bar()
    foo(A{});  // 调用 foo(T) with operator+
    foo(C{});  // 触发二义性
}
```

#### 调用解析逐步分析

##### `foo(10)`

1. **名称查找**：找到三个候选：`foo(int)`、两个模板。
2. **模板推导**：
   - `foo(T) with +`：`10+10` 可行。
   - `foo(T) with bar()`：`10.bar()` 不成立，SFINAE 剔除。
3. **ICS 比较**：
   - `foo(int)` 与 `foo(T)` 都可行，实参 `int` → `int` 精确匹配。
   - 非模板优于模板 → 选 `foo(int)`。

输出：

```cpp
foo(int)
```

##### `foo(B{})`

1. 候选：同上。
2. 推导：
   - `foo(T) with +`：`B{}+B{}` 不合法 → 剔除。
   - `foo(T) with bar()`：`B{}.bar()` 成立 → 保留。
3. 唯一可行：`foo(T) with bar()`。

输出：

```cpp
foo(T) with bar()
```

##### `foo(A{})`

1. 候选：同上。
2. 推导：
   - `foo(T) with +`：`A{}+A{}` 不合法 → **注意！** 如果我们没有定义运算符 `+`，其实编译会直接报错，不是 viable。这里我假设我们定义了一个 `operator+(A,A)`。
   - `foo(T) with bar()`：`A{}.bar()` 不存在 → 剔除。
3. 剩余候选：`foo(T) with +`。

输出：

```cpp
foo(T) with operator+
```

##### `foo(C{})`

1. 候选：同上。
2. 推导：
   - `foo(T) with +`：我们定义了 `operator+(C,C)`，可行。
   - `foo(T) with bar()`：假设我们也给 `C` 定义了 `bar()` 方法，那么这个也可行。
3. 两个模板候选都可行，且 ICS 完全相同。
4. 编译器无法判定哪个更优 → 报二义性错误。

#### 实际编译器报错（g++/clang）

假设我们给 `C` 同时定义了 `operator+` 和 `bar()`，结果如下：

```cpp
struct C {
    int bar() { return 0; }
};
C operator+(C, C) { return {}; }
```

报错信息示例（g++）：

```cpp
error: call of overloaded 'foo(C)' is ambiguous
note: candidate: 'void foo(T) [with T = C; decltype ((t + t), void()) <anonymous> = void]'
note: candidate: 'void foo(T) [with T = C; decltype (t.bar(), void()) <anonymous> = void]'
```
