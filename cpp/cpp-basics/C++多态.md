## C++ 多态

C++ 中的**多态（Polymorphism）**是面向对象编程（OOP）的核心特性之一，它允许程序在运行时根据对象的实际类型调用对应的方法，从而实现**接口的统一调用，行为的差异化实现**。多态分为两大类：静态多态（编译时多态）、动态多态（运行时多态）。

### 静态多态

静态多态在**编译期间就可以确定调用的函数**，典型方式有：

#### 函数重载

同一作用域中，函数名相同但参数列表不同。

```cpp
void print(int x) { cout << "int: " << x << endl; }
void print(double x) { cout << "double: " << x << endl; }

print(5);    // 输出 int: 5
print(3.14); // 输出 double: 3.14
```

#### 运算符重载

为自定义类型提供类内运算符行为。

```cpp
class Point {
public:
    int x, y;
    Point(int x, int y): x(x), y(y) {}
    Point operator+(const Point& other) {
        return Point(x + other.x, y + other.y);
    }
};
```

#### 模板

泛型编程的一种形式，通过参数化类型实现重用。

```cpp
template<typename T>
T add(T a, T b) {
    return a + b;
}
```

### 动态多态

动态多态的核心是通过**基类指针或引用调用派生类的重写方法**，需要满足以下三个必要条件：

- 继承
- 虚函数
- 基类指针或引用调用派生类对象

```cpp
#include <iostream>
using namespace std;

class Animal {
public:
    virtual void speak() { // 虚函数
        cout << "Animal speaks" << endl;
    }
};

class Dog : public Animal {
public:
    void speak() override { // 重写
        cout << "Dog barks" << endl;
    }
};

void makeSound(Animal* a) {
    a->speak();  // 通过指针调用 → 动态绑定（根据动态类型）
}

void makeSoundRef(Animal& a) {
    a.speak();   // 通过引用调用 → 动态绑定（根据动态类型）
}

int main() {
    Animal a;
    Dog d;

    // ---- 静态绑定：对象直接调用 ----
    a.speak();  // 输出 Animal speaks（静态类型=动态类型=Animal）
    d.speak();  // 输出 Dog barks  （静态类型=动态类型=Dog）

    // ---- 动态绑定：指针调用 ----
    Animal* p1 = &a;  // 静态类型: Animal*  动态类型: Animal*
    Animal* p2 = &d;  // 静态类型: Animal*  动态类型: Dog*

    makeSound(p1);    // 输出 Animal speaks（动态类型=Animal）
    makeSound(p2);    // 输出 Dog barks   （动态类型=Dog）

    // ---- 动态绑定：引用调用 ----
    Animal& r1 = a;   // 静态类型: Animal&  动态类型: Animal&
    Animal& r2 = d;   // 静态类型: Animal&  动态类型: Dog&

    makeSoundRef(r1); // 输出 Animal speaks（动态类型=Animal）
    makeSoundRef(r2); // 输出 Dog barks   （动态类型=Dog）

    return 0;
}
```

- **对象调用虚函数 → 静态绑定**（编译期确定，静态类型=动态类型）。
- **指针或引用调用虚函数 → 动态绑定**（运行时看动态类型）。
- **多态性的根本**：指针/引用的静态类型是基类，但动态类型可能是派生类。


### 虚函数表简述

- 当一个类有虚函数时，编译器会为类生成一个“虚函数表”（vtable），指向所有虚函数的地址。

- 每个对象中会包含一个“虚指针”（vptr）指向该类的虚函数表。

- 调用虚函数时，程序会通过 `vptr` 找到对应的函数地址，实现运行时绑定。

### 抽象类

如果一个类中至少有一个**纯虚函数**（声明格式为 `= 0`），它就是**抽象类**，不能实例化。派生类必须覆盖所有纯虚函数，才能实例化对象。

#### 不能直接实例化对象

```cpp
class A {
    virtual void f() = 0;  // 纯虚函数
};

int main() {
    A a;   // 错误：抽象类不能实例化
}
```

#### 可以有构造函数/析构函数

- 虽然不能直接创建对象，但构造函数和析构函数仍然会被派生类调用。

#### 可以作为基类

- 典型用途就是用来定义接口，派生类必须实现纯虚函数才能实例化：

```cpp
class A {
    virtual void f() = 0;
};

class B : public A {
    void f() override { /* 实现接口 */ }
};

int main() {
    B b;   // 可以实例化，因为 B 实现了 f()
}
```

#### 派生类仍然可能是抽象类

- 如果派生类没有实现基类中的所有纯虚函数，它本身仍然是抽象类。

#### 相关关键字

| 关键字     | 作用                       |
| ---------- | -------------------------- |
| `virtual`  | 声明虚函数，启用动态多态   |
| `override` | 明确表示重写，避免误操作   |
| `final`    | 禁止进一步重写（C++11 起） |
| `= 0`      | 定义纯虚函数，创建抽象类   |

### 接口

接口（Interface）是只包含纯虚函数的抽象类，用于定义行为规范而不提供具体实现。

| 比较项     | 接口（Interface）          | 抽象类（Abstract Class）             |
| ---------- | -------------------------- | ------------------------------------ |
| 成员       | 只包含纯虚函数和虚析构函数 | 可以有数据成员、普通函数、构造函数等 |
| 用途       | 只定义行为                 | 可作为基类提供部分实现               |
| 多继承支持 | 可安全多继承（接口组合）   | 可多继承，但需注意菱形继承问题       |
| 实例化     | 不可直接实例化             | 不可直接实例化（除非纯虚函数都实现） |

### 常见问题

#### 为什么构造函数不能是虚函数

因为在构造函数执行期间，虚函数机制（vtable/vptr）尚未准备好或不完整，无法实现多态行为。

##### 构造函数的职责是“初始化”对象

构造函数的主要目标是：

- 分配内存；
- 初始化数据成员；
- 设置 vptr（虚函数指针）；

也就是说，**vptr 是在构造过程中才设定的**，而不是之前就有的。

##### 虚函数依赖于 vtable/vptr

- 多态调用的前提是：**对象已有 vptr，并且它正确地指向了 vtable**；
- 然而在构造函数体内：
  - vptr 尚未指向最终的派生类的 vtable；
  - 即使设置了，也只指向当前构造函数所属类的 vtable（不是派生类的）；
- 所以，如果构造函数是虚函数，在派生类构造过程中就无法正常解析该函数应该调用哪个版本。

##### 调用构造函数时对象尚未完全构造完成

- 构造时是“由上到下”构造的：
  - 先构造基类 -> 再构造成员 -> 再构造派生类；

- 若构造函数是虚函数，就可能在对象未构造完成时通过多态机制“调用派生类的构造函数”；

- 这不安全！因为派生类的数据成员尚未初始化，调用派生类版本可能出错或未定义行为。

##### 举个危险的例子

假设语法上允许虚构造函数：

```cpp
class Base {
public:
    // 假设构造函数是虚函数
    virtual Base() {
        f();  
    }
    // f() 必须是虚函数，才能用这个例子体现“构造函数虚调用导致的问题”
    virtual void f() { std::cout << "Base::f\n"; }
};

class Derived : public Base {
public:
    Derived() {}
    void f() override { std::cout << "Derived::f\n"; }
};
```

如果构造函数是虚函数（语法上是不允许的，只是假设），且构造函数中调用了虚函数 `f()`，那么在构造期间调用哪个版本的 `f()` 是不明确且危险的：

- 构造 `Derived` 对象时，`Base` 的构造函数会先运行；
- 如果 `Base::Base()` 中调用 `f()`（假设是虚函数），会调用哪个版本？
  - 如果调用 `Derived::f()`，这时 `Derived` 的部分还没初始化，会导致错误！
  - 所以 C++ 编译器干脆不允许构造函数是虚函数。

#### 构造函数内部能调用虚函数吗

- **构造函数内部**是**可以语法上调用虚函数的**
-  **但这不是多态调用（即不通过 vtable），而是静态绑定 —— 调用当前类的版本**，而不是派生类的重写版本。

#### 为什么基类析构函数需要是虚函数

在 C++ 中，**基类的析构函数需要声明为虚函数（`virtual`）**，是为了确保在通过**基类指针删除派生类对象时**，可以正确地调用派生类的析构函数，从而避免**资源泄漏**和**未定义行为**。

##### 错误写法

```cpp
class Base {
public:
    ~Base() {
        std::cout << "Base destructor\n";
    }
};

class Derived : public Base {
public:
    ~Derived() {
        std::cout << "Derived destructor\n";
    }
};

int main() {
    Base* ptr = new Derived();
    delete ptr; // 只调用 Base 的析构函数，Derived 的析构函数不会被调用
    return 0;
}
```

输出：

```css
Base destructor
```

此时 **`Derived` 的析构函数没有被调用**，如果它管理了动态资源（如 new 出来的指针、文件句柄等），就会造成**资源泄漏**。

##### 正确写法

将基类析构函数声明为 `virtual`：

``` cpp
class Base {
public:
    virtual ~Base() {
        std::cout << "Base destructor\n";
    }
};

class Derived : public Base {
public:
    ~Derived() {
        std::cout << "Derived destructor\n";
    }
};

int main() {
    Base* ptr = new Derived();
    delete ptr; // 会先调用 Derived 析构，再调用 Base 析构
    return 0;
}
```

输出：

```css
Derived destructor
Base destructor
```

当通过**基类指针删除派生类对象**时：

- 若基类析构函数**不是虚函数**，只会调用基类析构函数；
- 若基类析构函数**是虚函数**，会根据实际对象类型**触发虚函数机制（vtable）**，从而**调用完整的析构过程（先派生后基类）**。

##### 析构函数将阻止合成移动操作

- 只要类显式声明析构函数（普通或虚析构），编译器就不会隐式生成移动构造函数和移动赋值运算符。
- 如果需要移动操作，必须显式定义或使用 `= default` 移动构造/移动赋值运算符

#### 为什么成员模板函数不能是 virtual 的

##### 虚函数机制是基于“已知签名”的

虚函数机制的本质是：

- 编译期建立**虚函数表（vtable）**；
- 每个类的 vtable 中存储的是**固定函数签名**（即参数类型、返回值都完全确定）的函数指针；
- 运行时通过虚函数表实现动态派发。

##### 模板函数的签名在编译期才确定

成员模板函数本质上是：

- **泛型代码**；
- 每次调用都会根据**调用时传入的模板参数**生成**不同版本的函数**（即实例化）；

> 换句话说，**模板函数不是真正的函数，而是函数生成器**，它不具备唯一的签名，只有在使用时才实例化成具体函数。

##### 虚函数表不支持“无限多的未知函数签名”

由于虚函数要求在编译时就将函数指针放进 vtable，但：

- 模板函数的数量是**无限种可能**（`foo<T>()`, `foo<U>()`, ...）；
- 编译器根本无法预知你将来会用哪些模板参数，也就**无法为每一个模板函数实例预留 vtable 插槽**。

因此，**无法把一个模板成员函数放进虚函数表，也就不能是 `virtual` 的**。

##### 替代方案：实现模板 + 虚函数的行为

###### 类型擦除（Type Erasure）

- **思路**：将不同类型的对象抽象成统一接口类型，在不知道具体类型的情况下调用它们。
- **典型应用**：策略模式、命令模式、事件回调等。

```cpp
class Base {
public:
    virtual void call(int x) = 0; // 统一接口
    virtual ~Base() {}
};

template<typename Func>
class Derived : public Base {
    Func f; // 保存任意可调用对象
public:
    Derived(Func func) : f(func) {}
    void call(int x) override { f(x); }
};

int main() {
    std::vector<std::unique_ptr<Base>> vec;

    vec.push_back(std::make_unique<Derived>([](int x){ std::cout << "lambda 1: " << x << "\n"; }));
    vec.push_back(std::make_unique<Derived>([](int x){ std::cout << "lambda 2: " << x*2 << "\n"; }));

    for (auto& obj : vec) obj->call(10); // 多态调用
}
```

###### 模板派生类 + 虚接口

- **思路**：定义抽象接口类，模板派生类持有任意类型的数据或对象，并实现虚函数。
- **用途**：封装任意类型的数据，让它们统一通过接口处理。

```cpp
struct Interface {
    virtual void process() = 0;
    virtual ~Interface() = default;
};

template <typename T>
class Impl : public Interface {
    T data;
public:
    Impl(T d) : data(d) {}
    void process() override {
        // 使用 data 做操作
    }
};
```

###### 区别总结

| 方案                       | 核心用途                       | 模板作用                       | 调用方式       |
| -------------------------- | ------------------------------ | ------------------------------ | -------------- |
| 类型擦除 (`Derived<Func>`) | 封装可调用对象（函数、lambda） | 将任意可调用对象适配为统一接口 | 多态调用虚函数 |
| 模板派生类 (`Impl<T>`)     | 封装任意数据类型               | 持有数据并实现接口逻辑         | 多态调用虚函数 |

### 继承类型转换规则

#### 派生 → 基类（向上转换 / Upcast）

- 安全且隐式允许。
- 指针或引用都可直接转换。

```cpp
struct Base {};
struct Derived : Base {};

Derived d;
Base* pb = &d;   // 隐式
Base& rb = d;     // 隐式
```

#### 基类 → 派生（向下转换 / Downcast）

- 可能不安全，必须显式使用 `dynamic_cast`（有虚函数）或 `static_cast`（确保类型正确）。
- 通过指针或引用进行转换。

```cpp
Base* pb = new Derived;
Derived* pd = dynamic_cast<Derived*>(pb); // 安全，如果 pb 实际指向 Derived
```

#### 同一继承层次的 sibling 类型

- 不能直接转换，需要先向上转换到公共基类，再向下转换到目标类型。

```cpp
struct A {};
struct B : A {};
struct C : A {};

B b;
C* pc = static_cast<C*>(static_cast<A*>(&b)); // 不安全，需谨慎
```

#### 多重继承 / 虚继承

- 转换规则与上面类似，但可能涉及偏移调整。
- 使用 `dynamic_cast` 可以安全处理指针/引用。

### 虚函数与默认实参

虚函数与默认实参在 C++ 中并不绑定在一起。

#### 默认实参

- 默认实参是在**函数声明处**为某些参数指定的默认值。
- 在**调用函数的地方**，如果调用者未提供某个参数，就会使用这个默认值。
- **默认实参的绑定在编译期完成，依据的是静态类型。**

#### 虚函数 + 默认实参

- 虚函数调用是运行时决定（动态绑定），但默认实参使用是编译时决定（静态绑定）。

- 这就可能导致“调用了子类的函数，但参数却是基类的默认值”。

```cpp
#include <iostream>
using namespace std;

class Base {
public:
    virtual void func(int x = 1) {
        cout << "Base::func, x = " << x << endl;
    }
};

class Derived : public Base {
public:
    void func(int x = 2) override {
        cout << "Derived::func, x = " << x << endl;
    }
};

int main() {
    Derived d;
    Base* p = &d;
    p->func();  // 调用哪个函数？x 是多少？
    return 0;
}
```

输出结果：

```cpp
Derived::func, x = 1
```

- `p->func()` 调用了 `Derived::func()` —— 这是**虚函数机制**决定的。
- 但参数 `x` 的值却是 `1` —— 这是因为默认参数 `x=1` 是 **p 的静态类型 `Base*`** 决定的。

#### 最佳实践建议

- **不要在虚函数中使用默认参数**（特别是基类与派生类给出的默认值不同）。
- 如果确实需要默认值逻辑，**手动传参**或**改用函数重载**更安全。

### 回避虚函数的机制

#### 什么是“回避虚函数”

C++ 支持虚函数的多态机制，正常情况下：

```cpp
Base* p = new Derived();
p->foo(); // 会动态绑定，调用 Derived::foo()
```

而**“回避虚函数”**是指：**明知道 `foo` 是虚函数，但我们想强制调用某个特定类（通常是基类）中的版本，而不让编译器做动态绑定。**

#### 常见的“回避虚函数”方式

##### 通过作用域限定符调用

```cpp
class Base {
public:
    virtual void foo() { std::cout << "Base::foo\n"; }
};

class Derived : public Base {
public:
    void foo() override { std::cout << "Derived::foo\n"; }
};

Derived d;
d.Base::foo();  // 回避虚函数机制，强制调用 Base::foo
```

- 虽然 `foo` 是虚函数，但使用 `Base::foo()` 明确指定了要调用哪一版本。

- 这是**静态绑定**，**回避了虚函数的动态分派机制**。

##### 通过基类名调用指针版本（不推荐）

```cpp
Base* p = new Derived();
p->Base::foo();  // 不推荐，但合法，静态调用 Base::foo
```

- 一般很少这样用，因为多数情况下只希望通过作用域访问“对象内的某个特定实现”。

##### 在基类构造函数或析构函数中调用虚函数

```cpp
class Base {
public:
    Base() {
        foo();  // 虽然是虚函数，但这里调用的是 Base::foo
    }
    virtual void foo() { std::cout << "Base::foo in constructor\n"; }
};

class Derived : public Base {
public:
    void foo() override { std::cout << "Derived::foo\n"; }
};
```

- 在构造函数和析构函数中，**即使调用虚函数，也不会发生多态**。
- 原因是：对象尚未构造完成（或正在析构），动态类型信息不完整。
- 这也是为什么在构造/析构函数中调用虚函数是不推荐的设计。

##### 通过强制类型转换绕过（危险）

```cpp
Derived d;
Base& br = d;
static_cast<Base&>(br).foo();  // 强制转换为 Base 引用再调用
```

- 会调用 `Base::foo()`，因为强制类型转换之后使用的是 `Base` 的静态类型。

- 实际上这类似于作用域限定，但更绕，**可读性差，不推荐**。

#### 回避虚函数的场景

1. **性能敏感**：虚函数调用有 vtable 查找开销，循环热点代码尽量用模板或静态多态。
2. **类层次简单**：不需要多态，直接用普通成员函数或模板即可。
3. **对象大小严格**：虚函数增加 vptr，占内存，不适合嵌入式或缓存敏感场景。
4. **无需动态派发**：调用在编译期可确定，模板或 inline 函数更快。
5. **生命周期复杂**：避免通过基类指针删除派生对象，智能指针或类型擦除更安全。