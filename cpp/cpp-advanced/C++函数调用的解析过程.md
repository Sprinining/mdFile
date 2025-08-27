## C++ 函数调用的解析过程

一次 **C++ 函数调用**（含普通函数、成员函数、运算符重载、构造函数等）的大致流水线是：

1. **名字查找（name lookup）** ➜ 找到可能的候选（含**未限定查找**与 **ADL**）。
2. **构建候选集** ➜ 普通函数 + 模板函数 + 成员函数/隐式对象参数 + 内置运算符/用户自定义运算符。
3. **模板实参推导（TAD）/类模板推导（CTAD）** ➜ 形成具体候选。
4. **可行性检查** ➜ 形参与实参是否能匹配（含默认实参、可访问性、=delete、显式/隐式转换、cv/ref 限定等）。
5. **重载决议（overload resolution）** ➜ 以“转换序列优劣”与“部分特化/偏序”等规则选出**最佳可行函数**；否则二义性或无匹配报错。
6. **动态派发（若是虚函数）** ➜ 运行期根据动态类型选择最终版本。

### 名字查找

C++ 标准里把名字查找分为两大类：

1. **未限定查找 (Unqualified Lookup)**
   - 直接写名字，例如 `f(1)`，没有加 `::`、没有指明作用域。
   - 编译器从**当前作用域**开始，一层一层向外找，直到全局命名空间。
   - 同时考虑 `using` 声明、`using namespace` 指令引入的名字。
   - 若是函数调用，还可能触发 **ADL**（实参依赖查找）。
2. **限定查找 (Qualified Lookup)**
   - 指定作用域，例如 `std::vector`、`Base::func`、`::globalVar`。
   - 编译器只在指明的作用域里查找名字，不会再逐层向外扩展。

#### 未限定查找示例

```cpp
#include <iostream>
int x = 1;

void foo() {
    int x = 2;
    {
        int x = 3;
        std::cout << x << "\n"; // 3，最内层作用域优先
    }
    std::cout << x << "\n";     // 2
}
int main() {
    foo();
    std::cout << x << "\n";     // 1，全局作用域
}
```

- 内层作用域优先，逐层往外找，直到全局。

#### 限定查找示例

```cpp
#include <iostream>
int val = 1;
namespace ns {
    int val = 2;
}
int main() {
    std::cout << val << "\n";    // 1，未限定查找
    std::cout << ns::val << "\n"; // 2，限定查找
    std::cout << ::val << "\n";   // 1，:: 表示全局命名空间
}
```

- 限定查找**直接锁定作用域**，不会再去找别的。

#### 特殊情况：类作用域查找

类里面名字查找有一些特殊规则：

- **继承体系**：派生类查找不到时会继续查找基类。
- **作用域隐藏**：派生类成员会隐藏同名基类成员（除非 `using` 显式引入）。
- **友元**：友元函数的可见性取决于定义方式（普通友元 vs 隐藏友元）。
  - **普通友元（非隐藏）**：友元函数可以**只声明在类里面，但定义在外面**。这种函数在全局/命名空间作用域里有一个可见名字，编译器查找时即使没有 ADL 也能找到。
  - **隐藏友元**：如果在类里**直接定义友元函数**（而不是在外面再定义一次），这个函数就只存在于类的关联作用域里，**不会进入普通查找范围**。它只能通过 **ADL（实参依赖查找）**才能被发现。

```cpp
#include <iostream>
struct Base {
    void f(int) { std::cout << "Base::f(int)\n"; }
};
struct Derived : Base {
    void f(double) { std::cout << "Derived::f(double)\n"; }
};
int main() {
    Derived d;
    d.f(1.0); // 调用 Derived::f(double)
    // d.f(1); // Base::f(int) 被隐藏，不在查找结果里
}
```

- 如果想让基类重载也参与，需要 `using Base::f;`。

```cpp
struct X {
    friend bool operator==(const X&, const X&) { return true; } // 隐藏友元
};
int main() {
    X a, b;
    bool eq = (a == b); // 依赖 a/b 的关联类 X，通过 ADL 找到隐藏友元
}
```

#### ADL

未限定查找用于函数调用时，会多一步 **ADL**（Argument-Dependent Lookup）：

- 根据**实参类型**，把相关命名空间/类作用域的函数也加入候选。
- 典型用途：运算符重载、隐藏友元、库算法。

```cpp
namespace math {
    struct Vec {};
    void norm(Vec) {}
}
int main() {
    math::Vec v;
    norm(v); // norm 不在当前作用域，靠 ADL 在 math 里找到
}
```

#### 小结

| 类型         | 示例        | 查找范围                       | 特点                 |
| ------------ | ----------- | ------------------------------ | -------------------- |
| 未限定查找   | `foo()`     | 当前作用域 → 外层作用域 → 全局 | 函数调用时可能加 ADL |
| 限定查找     | `ns::foo()` | 仅在 `ns` 命名空间             | 不会逐层向外         |
| 全局查找     | `::foo()`   | 全局命名空间                   | 常用于避免名字冲突   |
| 类作用域查找 | `obj.f()`   | 先在类里找，再到基类           | 派生类同名会隐藏基类 |
| ADL          | `swap(a,b)` | 实参相关的命名空间/类          | 依赖实参类型触发     |

### 构建候选集

#### 第一步 — 名字查找先行

- 对未限定调用 `f(...)`：先做**未限定查找**（当前作用域 → 外层 → 全局），再**（若是函数调用）触发 ADL** 把实参类型相关命名空间的函数也加入。
- 对限定调用 `ns::f(...)`：只在 `ns` 内查找。

结果：把查到的所有函数（普通函数、函数模板、命名空间内的非成员函数、类内的静态成员函数等）收集为“初始候选集”。

```cpp
namespace lib {
    struct X{};
    void process(X) {}        // 在 lib 命名空间
}
void process(int) {}         // 在全局
int main() {
    lib::X x;
    process(x); // lookup + ADL => 候选集含 lib::process(X)
    process(1); // lookup => 候选集含 ::process(int)
}
```

#### 第二步 — 把成员函数视为带“隐式对象参数”的候选

- 对 `obj.f(a,b)`：所有 `f` 成员（包括不同 cv/ref 限定）都会以“隐式对象参数 + 显式参数”的形式加入候选集。
- 也就是说 `void f() &` 与 `void f() &&` 是两条不同候选，隐式对象参数需匹配（左值或右值、const 与否）。

```cpp
struct S {
    void g() &  { /* candidate: g(this& as lvalue) */ }
    void g() && { /* candidate: g(this&& as rvalue) */ }
};
S s;
s.g();      // 候选里有两条，但只有 g()& 是可行
S{}.g();    // 只有 g()&& 可行
```

#### 第三步 — 对运算符：加入“内置运算符候选”

- 对表达式 `a + b`：编译器不仅查找 `operator+`，**还把符合的内置 operator+ 的实现（带需要的标准转换序列）当作候选**加入。
- 如果类型是自定义类型且库里有非成员 `operator+`，ADL 也会把它加入。

```cpp
struct X {};
X operator+(X, X) { return {}; } // 用户定义
int main() {
    X a, b;
    a + b; // 候选集：内置加法（不匹配） + 用户 operator+(X,X)
}
```

#### 第四步 — 函数模板也在候选集中（待推导）

- 函数模板被加入候选集为模板形式；接下来做**模板参数推导**（TAD）来得到模版实参并将模板与其他候选进行比较。
- 若模板在推导过程中出现 SFINAE/substitution-failure，则该模板会从候选集中“被移除”。

```cpp
void f(int);
template<class T> void f(T);
f(10); // 候选集：f(int) 和 f<T>(T)（推导 T=int）
       // 最终选 f(int)（更精确）
```

SFINAE 例子：

```cpp
template<class T>
auto try_call(T t) -> decltype(t.foo(), void()) { } // 只有有 foo() 的类型才合法
// 当调用 try_call(obj) 且 obj 没有 foo() 时，模板会在推导阶段失败并从候选集中被剔除
```

#### 第五步 — “构造函数” & “类型初始化”是专门的候选情形

- 在做 `T x(a,b)` 或 `T x{...}` 时，候选集是 `T` 的构造函数集合（包括 `initializer_list` 构造函数）。
- 对列表初始化 `{}`，`initializer_list` 构造函数具有特殊优先级（会先考虑）。

```cpp
struct A {
    A(int,int) { }
    A(std::initializer_list<int>) { }
};
A a1(1,2); // 选 A(int,int)
A a2{1,2}; // 选 A(initializer_list)
```

#### 第六步 — “可行候选”的筛选规则

从初始候选集中，编译器把**不符合基本条件**的候选剔除（或标记为不可行）——形成“可行候选集”：

常见剔除条件（简化说明）：

- **实参个数/类型**：参数个数不匹配且无默认实参补齐 → 不可行。
- **转换不可达**：某个实参不能通过允许的转换序列（标准转换 / 用户定义转换 / ellipsis）到对应形参类型 → 不可行。
- **访问控制**：对不可访问（private/protected）成员的调用会被编译器视为不可行（或在后期报不可访问错误）。
- **被删除（=delete）**：被声明为 `=delete` 的重载不会成为可行解（不可调用）。
- **模板 SFINAE**：模板替换失败会把候选去掉。

示例：默认参数使其可行

```cpp
void h(int, int = 0);
h(1); // h(int,int=0) 可行（默认参数补齐）
```

示例：被删除

```cpp
void k(long) = delete;
void k(int);
k(1); // 更好的匹配是 k(int)，如果只有 k(long) 且被 delete，则不能调用
```

#### 第七步 — 用户自定义转换是“转换序列”的一部分，而不是独立候选

- 当某个候选的形参类型不是实参类型时，编译器会尝试**把实参转换成形参类型**。这时可以用到：
  - 标准转换（整型提升、浮点转换、指针转换等）
  - **用户自定义转换**（单参数构造函数或 `operator T()`） — 这*是转换序列的一环*，并不是把构造函数或 `operator` 当作独立的“函数候选”来直接选中（除非正在选择构造函数本身）。
- 重要：用户自定义转换通常比标准转换“代价更大”，在重载决议中优先级较低（除非另一个候选需要更差的转换序列）。

```cpp
struct M {
    explicit M(int);      // explicit 阻止某些隐式转换（视情形）
    operator double() const { return 3.14; } // M -> double
};
void p(M);
void p(double);
M m(1);
p(m); // 候选：p(M)（精确）与 p(double)（通过 m.operator double()）
      // 选 p(M)
```

#### 第八步 — 排序 / 最终选择前的细节

- 经过可行性筛选后，编译器比较每个可行候选的**转换序列优劣**（参数逐一比较）。
- 规则（大致）：
  - 精确匹配优于整型提升，整型提升优于标准转换，标准转换优于用户定义转换，用户定义转换优于省略号 `...`。
  - 非模板与模板的偏好、模板间的偏序也会影响优先。
- 若没有唯一最优候选，则**二义性错误**；若选择到被 `=delete` 或不可访问的候选，会报相应错误（即使它在候选列表里）。

#### 综合示例

```cpp
#include <iostream>
namespace N {
    struct A{};
    void f(A) { std::cout << "N::f(A)\n"; }     // (1) 来自 N（ADL）
}
void f(int) { std::cout << "::f(int)\n"; }      // (2) 全局
template<class T> void f(T) { std::cout << "tmpl f(T)\n"; } // (3) 函数模板

struct S {
    void m() &  { std::cout << "m&\n"; }         // (4a) 成员（左值限定）
    void m() && { std::cout << "m&&\n"; }        // (4b) 成员（右值限定）
    friend void f(S) { std::cout << "hidden f(S)\n"; } // (5) 隐藏友元（只通过 ADL 被找到）
};

int main() {
    N::A a;
    f(a); // 候选集说明：
          // - 从未限定查找得到 ::f(int) (2)  和 tmpl f(T) (3)
          // - ADL 根据实参类型 N::A，还把 N::f(A) (1) 以及 S::friend (5)（若实参为 S）加入
          // 结果：N::f(A) 精确匹配 => 选 (1)

    S s;
    f(s); // 若实参是 S：
          // 候选集：::f(int) (2), tmpl f(T) (3 => T=S), hidden friend f(S) (5)
          // hidden friend 是精确匹配 => 选 (5)

    s.m(); // 候选集（成员）：m()& 与 m()&& 两条。隐式对象参数为左值 => 只有 m()& 可行
    S{}.m(); // 隐式对象为右值 => 只有 m()&& 可行
}
```

### 模板实参推导

函数模板的模板参数推导（TAD，Template Argument Deduction）：

- 目标：从函数调用时的**实参类型（A）**，推导出函数模板参数列表里的**模板形参（T 等）**，从而得到具体化的函数模板实例。
- 推导只依据**函数形参类型（P）**与**实参类型（A）**的对应关系（**不是**基于返回值）。
- 有大量**特殊规则**：引用处理、数组/函数降级、top-level cv 忽略、转发引用（forwarding reference）行为、非推导上下文（non-deduced contexts）、参数包（pack）推导、SFINAE 等。

#### 简化的推导流程

对于每个形参 `P` 与对应实参 `A`：

1. 对 `P` 做形参类型的**模式匹配**（参照标准的多种情况），尝试求出模板参数使 `P` 与 `A` 匹配。
2. 如果能求出一致的模板参数就“成功推导”；若替换过程中产生替换失败（substitution failure），视为候选被移除（SFINAE）。
3. 推导完成后将所有候选（含普通函数、模板函数实例化）进行可行性检查与重载决议。

#### 常见具体规则

##### 基本类型调整

- 当 `P` 不是引用时，对 `A` 做**数组到指针**、**函数到函数指针**的调整（即 `int[]` → `int*`，`void()` → `void(*)()`），再进行匹配。
- 对于非引用的 `P`，**顶层 const/volatile（top-level cv）会被忽略**：`T` 可以匹配 `const int` 时 `T=int`（如果 `P` 是 `T` 而非 `const T`）。

```cpp
template<class T> void f(T);
int arr[3];
f(arr); // T -> int*  （数组退化为指针）
```

##### 万能引用

- 如果 `P` 是引用（`T&`、`const T&`、`T&&` 等），推导规则不同：
  - **一般引用**（如 `const T&`）：若 `A` 是 `X`（左值或右值），推导 `T = X`（去掉引用部分）。
  - **万能引用**：形如 `T&&` 且 `T` 是模板参数（且 `P` 不是被显式 cv 限定或是函数参数的非模板上下文），会出现**特殊规则**：
    - 如果实参是 **左值**，则 `T` 被推导为 `X&`（结果参数类型为 `X& &&` 折叠为 `X&`）。
    - 如果实参是 **右值**，则 `T` 被推导为 `X`。
- 这就是 `std::forward`/完美转发的基础。

```cpp
template<class T> void g(T&&);
int x = 1;
const int cx = 2;
g(x);   // T -> int&  ，参数类型为 int& && -> int&  （因为 x 是左值）
g(1);   // T -> int   ，参数类型为 int&&
g(cx);  // T -> const int&  (保持 const)
```

##### 用户自定义类型的构造/转换不是直接“推导来源”

- 当参数类型不匹配时，编译器会考虑**将实参转换为形参类型**（如使用类的构造函数或 `operator T()`），但这属于**转换序列**的一部分，而不是把这些构造函数本身当作推导模板参数的直接来源（除非正在选择构造函数本身——见 CTAD 部分）。

```cpp
struct S { S(int); operator double(); };
void h(S);
void h(double);
h(1); // 两个候选：h(S)（通过 S(int) 构造）和 h(double)（通过整型->double），按重载规则选最佳
```

##### 非推导上下文

有些位置**不能从类型表达式中推导出模板参数**。常见例子：

- 形如 `template<class T> void f(typename T::type);` —— 此处 `T::type` 是非推导上下文，不能从 `A` 推导 `T`。
- 当 `P` 包含模板-id 且模板-id 的模板参数本身涉及要推导的参数时（复杂规则）。

```cpp
template<class T>
void foo(typename T::type); // 无法从 foo(arg) 推导出 T（需要显式指定 T）
```

##### 参数包的推导

`template<class... Ts> void mk(std::tuple<Ts...>);` 对 `mk(std::tuple<int,double>{})` 会成功推导 `Ts... = {int, double}`。注意变长参数与空包也允许。

```cpp
template<class... Ts>
void mk(std::tuple<Ts...>);
mk(std::tuple<int,double>{}); // Ts... -> int, double
```

##### SFINAE

当用模板参数替换时如果出现不满足（例如用 `decltype(expr)` 时 expr 不合法），该模板仅从候选集中移除，不会报错（允许其他重载继续）。这是实现 enable_if、traits 的基础。

```cpp
template<class T>
auto f(T t) -> decltype(t.foo(), void()) { /* 有 foo() 才可用 */ }
```

##### 显式模板实参与隐式推导的关系

如果调用写了显式的模板实参（例如 `f<int>(x)`），对相应模板参数**不再做推导**，使用提供的实参；其余未显式指定的参数仍按推导规则确定。

```cpp
template<class T> void f(T);
f<int>(3.14); // T = int（用户指定），3.14 会向 int 转换（转换在匹配阶段发生）
```

##### 重载解析与模板的偏序

如果多个模板都可行，编译器会比较哪一个模板对给定实参更“特化”（partial ordering）来决定。常见效果：`foo(T*)` 会比 `foo(T)` 更特化（在传指针时），会被优先选中。

```cpp
#include <iostream>
template<class T> void foo(T) { std::cout<<"T\n"; }
template<class T> void foo(T*) { std::cout<<"T*\n"; }

int main() {
    int *p = nullptr;
    foo(p); // 输出 T* ，因为 foo(T*) 对指针更特化
}
```

#### 常见坑

- 若不确定推导出的类型，**显式写出模板实参**查看编译器错误 / 行为；或者在函数体内用 `static_assert(std::is_same_v<T, ...>)` 临时断言。
- 牢记：**返回类型不参与推导**（除非是以函数模板被直接显式实例化的特殊情形）。
- 对转发引用的推导理解不清会破坏完美转发（牢记左值→T&，右值→T）。
- 对 brace-init-list（花括号初始化）推导要小心：常常触发 `initializer_list` 重载或 CTAD 的 list-initialization 特例（见 CTAD 小节）。

### 类模板实参推导

类模板实参推导（CTAD，Class Template Argument Deduction） 是 C++17 引入的特性：**在创建类模板对象时（写构造表达式）可以省掉尖括号的模板实参，编译器根据构造参数推导出模板实参**。

#### CTAD 的工作原理

- 当看到 `X t(args...);` 且 `X` 是类模板（例如 `std::pair`、`std::vector`、自定义模板类），编译器会：
  1. 收集所有**可用的 deduction guides**（包括隐式生成的导出（来自构造函数）和用户显式声明的导出）。
  2. 用 `args...` 匹配每个 deduction guide 的形参，从而推导出模板参数。
  3. 将推导出的结果代入类模板，得到一个具体化类模板，然后检查构造函数等，最后完成初始化。
- 隐式 deduction guides：编译器会为每个构造函数合成对应的导出（有复杂条件，但常见构造会生成），这就是 `std::pair p(1, 2);` 能推导为 `pair<int,int>` 的原因。

#### 简单例子

```cpp
#include <utility>
auto p = std::pair(1, 2); // CTAD -> std::pair<int,int>
```

#### brace-init-list 与 initializer_list 的优先规则

- 如果使用 `{...}` 列表初始化，并且类有 `initializer_list` 构造，则 CTAD 及构造选择会把 `initializer_list` 构造放在优先考虑的位置（同函数模板的 `initializer_list` 规则）。
- 这导致 `std::vector v{1,2,3};` 推出 `vector<int>`（init-list 构造）。

```cpp
#include <vector>
std::vector v1{1,2,3}; // CTAD -> vector<int>, 使用 initializer_list 构造
std::vector v2(3, 1);  // 另一重载：v2 是 3 个 1 的 vector<int>
std::vector v3{3, 1};  // 这里是 init-list {3,1}，不是“3 个 1”
```

#### 用户自定义 deduction guide

可以给类模板写显式的 deduction guide，形式如下：

```cpp
template<class T, class U>
struct MyPair {
    MyPair(T, U);
};

// 显式 deduction guide：
template<class T, class U>
MyPair(T, U) -> MyPair<T, U>;
```

现在 `MyPair mp(1, 2.0);` 会推导为 `MyPair<int, double>`。

如果定义了显式导出，某些隐式生成的导出可能被抑制或受影响（标准有细节），但常见场景下只需对常用构造写显式导出即可。

#### 什么时候不会发生 CTAD

- 当显式写出模板参数（如 `MyPair<int,double> p(1,2);`），CTAD 不发生。
- 当推导不出唯一且有效的模板参数时（例如多个导出都能匹配但得到不同结果），会产生二义性错误。
- 聚合类在 C++17/C++20 下也有一些特殊的 CTAD 规则，但细节略复杂。

#### CTAD 的示例

```cpp
#include <iostream>

template<class T, class U>
struct P {
    P(T, U) { std::cout << "ctor\n"; }
};

// 编译器自动隐式生成一个导出：P(T,U) -> P<T,U>
// 也可以显式写出（同上）

int main() {
    P p(1, 2.5); // CTAD -> P<int,double>；输出 "ctor"
}
```

#### 常见坑

- **初始化形式不同**（圆括号 vs 花括号）可能导致不同的导出被选中（尤其当存在 `initializer_list` 构造时）。
- **推导失败或二义**时，编译器会报错——有时不易看出是哪个导出导致问题，写显式模板参数或显式导出来调试。
- CTAD 基于构造函数签名，`explicit` 与否会影响构造，但不直接阻止导出——细节由标准决定（通常 implicit 导出仍可生成，但构造是否可调用取决于 explicit/accessible）。

### 可行性检查

当名字查找（包括 ADL）把一堆**候选函数**找出来之后，编译器要做的第一件事就是把这些候选逐个**筛一遍**：能不能以给定的实参 *调用* 这个候选？能的叫 **可行候选（viable candidate）**，不能的就被剔除。可行性检查比“谁更好”更早发生——它只关心“能否调用”，不比较优劣（那是下一步重载决议的事）。

#### 逐步规则

对于候选函数 `F`，做以下检查：

1. **参数个数 / 默认参数 / 参数包**
   - 实参的数量能通过默认实参补齐或参数包匹配对应形参吗？若不能 → **不可行**。
2. **对每个参数是否存在“隐式转换序列”**把该实参变为对应形参？
   - 若某个实参无法转换为形参类型（按语言允许的隐式转换：标准转换、用户自定义转换、指针/数组降级、函数指针转换、`...` 等），则该候选**不可行**。
   - 特殊：用花括号 `{}` 列表初始化会触发特有规则（窄化检查、initializer_list 优先），可能使转换“不成立”从而不可行。
3. **对成员函数：隐式对象参数是否可绑定**
   - 对 `obj.f(...)`，隐式对象（`obj`）也当作第一个参数来匹配：`const`/`volatile` 限定、`&`/`&&` ref 限定必须匹配（左值/右值、constness）。若不能绑定 → **不可行**。
4. **函数是否被标记为 `=delete`**
   - 被 `=delete` 的重载不会成为可行候选。
5. **模板候选是否在推导阶段被移除（SFINAE / constraints）**
   - 函数模板在模板参数推导时若发生替换失败（SFINAE），或约束 `requires` / concepts 未满足，则模板会被从候选集中移除（不可行）。
6. **访问控制**（private/protected）与可行性：
   - 实务上、以及标准的语义上，被访问权限阻挡的候选不会在最终可调用集合中被接受——如果剩下的最终选择是一个不可访问函数，程序是 ill-formed。很多实现把不可访问函数视为不可行以避免把它选中。
7. **其他特殊情形**：构造函数的 `initializer_list` 优先，聚合初始化/聚合推导等可能对可行性产生影响。

如果 `F` 通过了上述检查，就成为 **可行候选**，进入下一步的**重载决议**（比较各自的转换序列优劣来选最佳）。

#### 参数个数 / 默认参数 / 参数包

```cpp
void g(int, int = 0);
void h(int);

g(1); // g 可行（第二个有默认值）
h(1); // h 可行
g();  // 不可行（缺必须参数）
```

参数包例子：

```cpp
template<typename... Ts> void t(Ts...);
t(1,2,3); // 参数包能匹配 3 个实参 -> 可行
```

#### 隐式转换序列是否存在

```cpp
struct A { explicit A(int); }; // explicit 阻止某些隐式构造
void f(A);
f(1); // 若 A(int) 是 explicit，则不能隐式从 int 构造 A -> f(A) 不可行
```

引用绑定：

```cpp
void p(int&); 
void q(const int&);
p(1); // 不能把临时绑定到 非 const lvalue reference -> p 不可行
q(1); // const 引用可绑定临时 -> q 可行
```

用户自定义转换：

```cpp
struct C { operator int(); };
void s(int);
s(C{}); // C::operator int() 可用 -> s(int) 可行
```

#### 列表初始化与窄化

```cpp
void a(int);
a({1});     // 有时可行（构造 int）
a({1.5});   // 列表初始化窄化：double -> int 窄化，可能导致不可行或编译错误
```

同样，若存在 `initializer_list` 重载，它优先参与，可能改变可行性。

#### 隐式对象参数（成员函数的 cv/ref 限定）

```cpp
struct S {
    void m() & { }
    void m() && { }
};
S s;
s.m();    // 隐式对象为左值 -> 只有 m()& 可行
S{}.m();  // 隐式对象为右值 -> 只有 m()&& 可行
```

同理：`const S cs; cs.m();` 只有 `m() const` 可行。

#### =delete 把候选排除

```cpp
void k(int) = delete;
void k(long);
k(1); // k(int) 被 delete -> k(int) 不可行；k(long) 若可转换则可行
```

####  模板替换失败 / Constraints（C++20）

```cpp
template<typename T>
auto foo(T t) -> decltype(t.foo(), void()); // 只有 T 有成员 foo() 时才有效

struct X{};
foo(X{}); // 替换失败（X 没有 foo），模板从候选集中移除 -> 不可行
```

C++20 的 `requires`：

```cpp
template<typename T>
requires requires(T t) { t.foo(); }
void bar(T);

bar(X{}); // requires 未满足 -> bar 不可行
```

#### 访问控制

```cpp
struct B {
private:
    void z(int);
public:
    void z(double);
};
B b;
b.z(1); // 虽然 z(int) 可能匹配，但它是 private -> 不能被外部调用
       // 编译器不会选不可访问的重载作为最终可调用目标
```

### 重载决议

**名字查找**与**可行性检查**做完后，手里剩下一组“可行候选”。接下来编译器要在这些候选里选出**最佳可行函数**。如果没有唯一最佳，就二义性报错。

#### 核心流程

- 对每个可行候选，逐个形参计算一条**隐式转换序列**。
- 给每个候选形成一个“转换序列向量”。
- **逐参数对比**两两候选：某候选如果在**至少一个参数更好**且在**其他所有参数不差**，它就“更好”。
- 若仍难分胜负，进入一系列**加权规则/决胜手**（非模板优先、模板偏序、更受约束的概念、ref/cv 细节等）。
- 仍无唯一最佳 ⇒ **ambiguous**。

#### 转换序列的强弱等级（从好到差）

1. **精确匹配**
   - 类型相同；或仅有顶层 cv 去除、数组/函数到指针退化、同类型引用绑定等。
2. **提升**
   - `bool/char/short -> int`，`float -> double` 等。
3. **标准转换**
   - `int -> double`、`Derived* -> Base*`、限定性变化（更 const）等。
4. **用户自定义转换**
   - 需要构造函数或 `operator T()` 参与。
5. **省略号**
   - 匹配 `...`。最差。

排名先比“等级”，再看更细的 tie-break（见下）。

#### 参数逐项对比：谁“更好”

当比较两个候选 `F` 与 `G`：

- 对每个实参位置 `i`：比较 `F[i]` 与 `G[i]` 的转换序列强弱。
- 如果存在至少一个 `i`，`F[i]` 明显优于 `G[i]`，且对所有 `j`，`G[j]` 不优于 `F[j]`，则 `F` 胜出。
- 如果 `F` 在某些参数更好、`G` 在另一些参数更好 ⇒ **难分胜负**，需要 tie-break 规则；若仍无法决出 ⇒ **二义性**。

#### 常见、实用的比较细则

##### 引用绑定优先级

- 右值调用：
  - 绑定到 `T&&` **优于**绑定到 `const T&`。
- 左值调用：
  - 绑定到 `T&` **优于**绑定到 `const T&`。
- “直接绑定”（无需产生临时物）通常优于经由临时/转换再绑定。

```cpp
void f(const int&); 
void f(int&&);

int x=0;
f(x);   // 选 const int& （没有 int& 重载时）
f(0);   // 选 int&&
```

##### 提升 vs 一般标准转换

- **整型提升**（`short->int`）比一般**标准转换**（`short->double`）更优。

```cpp
void g(long);
void g(double);
short s=1;
g(s); // 选 g(long)（提升优于一般转换）
```

##### 用户自定义转换劣于标准转换

- 若 A 需要构造/转换函数，而 B 只需标准转换，一般选 B。

```cpp
struct M { operator int() const; };
void h(int);    // 标准转换/精确
void h(double); // 需要 int->double（二段）但仍比 通过 UDC 转 double 更优
h(M{});         // 选 h(int)（UDC 到 int 后即止，比 UDC 到 double 再转更优）
```

##### `std::initializer_list` 的特殊性（列表初始化）

- 用 `{}` 调用时，若存在 `initializer_list` 重载，它**优先参与**候选建立；随后仍按上述规则比较。

```cpp
struct A {
  A(int,int);
  A(std::initializer_list<int>);
};
A a1(1,2);   // 选 A(int,int)
A a2{1,2};   // 倾向 A(init_list) 成为候选并常被选中
```

#### 模板相关的决胜手

##### 非模板 vs 模板

- 当两个候选的转换序列**不可区分**时：**非模板函数**优先于**模板特化**。

```cpp
void f(int);
template<class T> void f(T);
f(1); // 两者同为精确匹配 => 选 非模板 f(int)
```

##### 模板偏序（partial ordering）

- 在**函数模板**之间，如果转换序列难分高下，就看**哪个模板更特化**。
- 直观：`f(T*)` 比 `f(T)` 更特化（对指针参数时）。

```cpp
template<class T> void foo(T);
template<class T> void foo(T*);
int* p=nullptr;
foo(p); // 选 foo(T*)（更特化）
```

##### 概念/约束（C++20）

- 两个模板候选都可行时，**更受约束（more constrained）**者优先。

```cpp
template<class T> requires requires(T t){ t.size(); }
void bar(T);

template<class T>
void bar(T); // 无约束

// 对有 size() 的类型，选有 requires 的版本
```

#### 成员函数的隐式对象参数（this）的比较

- `obj.f()` 调用中，`this` 作为“隐式对象参数”也参与比较：
  - 对右值对象，`f() &&` **优于** `f() const&`；
  - 对左值非常量对象，`f() &` **优于** `f() const&`。

```cpp
struct S{
  void run() &  { /*...*/ }
  void run() && { /*...*/ }
  void run() const & { /*...*/ }
};
S s; 
s.run();    // 选 run() &
S{}.run();  // 选 run() &&
```

#### 仍然打不开的平手？继续 tie-break

当转换序列等级一样、逐参数也难分：

- **更小的 cv 增益**更好（更少的限定增加）。
- **派生到基类**转指针/引用：距离更短的转换（更“近”的基类）更好。
- 若还是相同：
  - 非模板 胜 模板；
  - 偏序/约束 继续判；
  - 全都一样 ⇒ **ambiguous**。

默认实参**只影响可行性**（能不能凑够参数），**不参与优劣比较**。

#### 常见二义性示例与消歧手段

```cpp
void k(long); 
void k(double);
// k(1u); // 可能二义（unsigned -> long / double 都是标准转换）

// 消歧：
k(1UL);       // 指定到 long 的方向
k(1.0);       // 指定到 double
k(static_cast<long>(1));
```

列表初始化的二义：

```cpp
struct B{
  B(int,int);
  B(std::initializer_list<int>);
};
// B b{1,2}; // 两者可能都可行但常由 init_list 优先成为最佳；若设计不当会报二义
```

成员/非成员重载的二义：

```cpp
struct X{};
X operator+(X,X);
int main(){
  X a,b;
  // 如果既有成员 operator+ 又有非成员且两者同等好，也可能二义
}
```

#### 一组小例子串起来

```cpp
#include <iostream>
struct W{ operator int() const { return 7; } };

void f(int)          { std::cout<<"f(int)\n"; }
void f(long)         { std::cout<<"f(long)\n"; }
void f(double)       { std::cout<<"f(double)\n"; }
template<class T>
void f(T)            { std::cout<<"f(T)\n"; }

int main(){
  short s=1;
  f(s);        // int 提升优于 double 转换 => f(int)

  f(W{});      // 候选：f(int)（UDC到int），f(long)（UDC+标准），f(double)（UDC+标准），f<T>(W)
               // 最优：f(int)

  f(1);        // 非模板与模板都精确匹配 => 选 非模板 f(int)

  // 二义示例（按平台可能不同）：
  // f(1u);   // unsigned -> long vs unsigned -> double，若位宽导致同级别且不可区分，报二义
}
```

### 动态派发（若是虚函数）

虚函数的调用在编译期确定“要调用哪个签名”，但在运行期根据对象的动态类型选择具体实现（即动态派发）——通常由每个多态对象里的一条指针（vptr）指向类的虚表（vtable）来实现。

#### 最小示例

```cpp
#include <iostream>
struct Base {
    virtual void f() { std::cout << "Base::f\n"; }
    void g()      { std::cout << "Base::g\n"; } // 非虚函数
    virtual ~Base() = default;
};
struct Derived : Base {
    void f() override { std::cout << "Derived::f\n"; }
    void g()         { std::cout << "Derived::g\n"; }
};

int main() {
    Derived d;
    Base* pb = &d;
    pb->f(); // 调用 Derived::f — 动态派发
    pb->g(); // 调用 Base::g   — 静态绑定（非虚）
}
```

输出：

```cpp
Derived::f
Base::g
```

`pb->f()` 运行期查 `pb` 指向对象的真实类型（`Derived`），通过 vtable 找到 `Derived::f` 并调用；`g()` 非虚，编译期绑定到 `Base::g`。

#### 常见实现：vptr / vtable

典型实现（非标准强制，仅常见做法）：

- 每个多态类（含至少一个虚函数）有一张**虚函数表（vtable）**，表项按虚函数声明顺序（及 ABI 规则）放置对应函数指针。
- 每个对象实例通常包含一个**指向该类 vtable 的指针（vptr）**，通常放在对象起始地址（implementation detail, 非语言保证）。
- 虚函数调用（`objptr->virt()`）等价于：取 `objptr->vptr`，从 vtable 对应 slot 取出函数指针，再间接调用它。

ASCII 示意（单继承，简化）：

```txt
Class Derived                    object memory
vtable:                          [ vptr ] -> &Derived_vtable
 [0] &Derived::f
 [1] &Derived::~Derived
...
object bytes:  | vptr (pointer) | data... |
```

多继承 / 虚继承 下的真实布局复杂得多（可能有多个 vptr、多个 vtables、thunk 等）。

#### 动态派发的调用过程

以 `pb->f()` 为例：

1. 编译期：编译器确认 `pb->f()` 这个表达式调用的是 `Base::f()` 这个签名（函数名、参数、cv/ref 等）——**签名在编译期就确定**。
2. 运行期：根据 `pb` 指向对象的动态类型，从 `pb->vptr` 读取对应 vtable 项（slot），取得具体实现的地址（例如 `Derived::f`）并跳转调用。

重载/选择的是“哪个签名”（编译期）；真正执行的是“哪些函数实现”（运行期）。

#### 构造函数 / 析构函数 中的虚调用

在构造/析构过程中，虚呼叫**不会**被派发到派生类实现，而是绑定到当前正在构造/析构的类版本（对象“仍被看作”当前正在初始化/销毁的类型）。

```cpp
#include <iostream>
struct Base {
    Base() { f(); }               // 在 Base ctor 中调用虚函数
    virtual void f() { std::cout << "Base::f\n"; }
    virtual ~Base() { f(); }      // 在 Base dtor 中调用虚函数
};
struct Derived : Base {
    Derived() {}
    void f() override { std::cout << "Derived::f\n"; }
    ~Derived() {}
};

int main() { Derived d; }
```

实际输出通常是：

```cpp
Base::f   // Base ctor 阶段，f() 调用不会转到 Derived
Base::f   // Base dtor 阶段，f() 也指向 Base 的实现
```

- 构造时派生部分尚未构造完毕；析构时派生部分已销毁 —— 编译器保证虚调用只派发到“当前已构造的最派生子对象部分”。
- 如果在构造期间调用纯虚函数且没有提供基类实现，结果可能是未定义或运行时错误。实际可靠做法是不要在 ctor/dtor 中依赖派生类的虚实现。

#### 抽象类、纯虚函数与实现

- 在类中声明 `virtual void f() = 0;` 使类成为抽象类（不能实例化）。
- 纯虚函数**可以**有函数体（`void f() = 0 { /*...*/ }`），这种体可以作为基类的默认实现，并且在 ctor/dtor 同类内被调用。
- 如果纯虚函数没有定义且在构造/析构期间被调用，效果未定义或运行时错误。

```cpp
struct A { virtual void f() = 0; };
void A::f() { /* optional default */ }
```

#### 为什么要 `virtual` destructor

如果通过基类指针删除派生对象，**必须**保证基类析构函数为 `virtual`，否则派生类析构函数不会被调用，导致资源泄漏或未定义行为。

```cpp
struct B { ~B() { std::cout<<"~B\n"; } };
struct D : B { ~D() { std::cout<<"~D\n"; } };

int main() {
    B* p = new D;
    delete p; // UB — D 的析构不会被调用
}
```

#### 多重继承 / 虚继承 下的派发复杂性

多继承（两个基类都有虚函数）

```cpp
#include <iostream>
struct A { virtual void fa() { std::cout<<"A\n"; } };
struct B { virtual void fb() { std::cout<<"B\n"; } };
struct C : A, B {
    void fa() override { std::cout<<"C::fa\n"; }
    void fb() override { std::cout<<"C::fb\n"; }
};
int main() {
    C c;
    A* pa = &c;
    B* pb = &c;
    pa->fa(); // C::fa
    pb->fb(); // C::fb
}
```

实现上：`C` 的对象可能含有**两个子对象视图**（A 子对象 + B 子对象），每个子对象可能有自己的 vptr，指向各自 vtable（或一个 vtable 的不同区域）。当把 `&c` 转换成 `A*` 或 `B*` 时，指针值本身可能需要**偏移**（pointer adjustment），以指向相应子对象。为此，编译器可能生成 *thunk*（小的调整 wrapper）来修正 this 指针，使 override 实现接收正确的 `this`。

在多继承下，虚表项可能不是简单的“函数地址”，而是“调整与函数地址”的组合（ABI 实现细节）。

#### 虚继承

虚继承会在对象布局里引入指向虚基类的指针/偏移，vtable 也会记录这些偏移以便在虚调用时修正 `this`。这部分很复杂，通常依赖 ABI；要意识到：**虚继承会额外增加开销（内存、指针修正）**。

#### covariant 返回类型

虚函数允许派生类覆写时返回更具体的指针/引用类型（协变返回）。

```cpp
struct Base { virtual Base* clone() const { return new Base(*this); } virtual ~Base(){} };
struct Derived : Base {
    Derived* clone() const override { return new Derived(*this); } // 合法，返回类型协变
};
```

#### 去虚化与优化

虚调用看似每次都要间接跳转，但编译器/链接器可以在若干场景下消除（devirtualize）：

- 编译期已知对象动态类型（比如 `Derived d; Base* pb = &d; pb->f();` 编译器能推断 `pb` 指向 `Derived`）
- 函数或类被标记为 `final`（无后续重写）
- 链接时能做全程序/  LTO 分析，确保无别处覆盖
   当去虚化成功，编译器可以做内联等优化，从而消除运行时开销。

#### 指向成员函数指针与虚函数

`void (Base::*pmf)()` 类型可以存放对成员函数的“地址”。通过 `(obj.*pmf)()` 或 `(ptr->*pmf)()` 调用时，若该成员是虚函数，调用仍然遵守虚派发（会发向动态类型的实现）。不同 ABI 对 PMF 的内部表现有不同（可能包含偏移/flags/虚表 slot 索引等），因此 PMF 不能简单地当作普通函数指针使用。

```cpp
void (Base::*pm)() = &Base::f;
(pb->*pm)(); // 依然会触发虚调，调用 Derived::f
```

#### RTTI 与 dynamic_cast 依赖多态

`dynamic_cast` 在向下转型（base* -> derived*）时需要运行时类型信息（RTTI）；RTTI 存储在类型信息表中，并且只有**多态类型**（有虚函数的类）才支持 `dynamic_cast` 的运行期检查。

```cpp
Base* pb = ...;
if (Derived* pd = dynamic_cast<Derived*>(pb)) {
    // 成功 -> pd 不为空
}
```

