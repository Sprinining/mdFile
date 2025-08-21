## C++虚函数表

C++ 中的虚函数表（vtable）是实现**运行时多态性（polymorphism）**的核心机制。它是编译器在支持虚函数时使用的一种内部技术。

### 什么是虚函数表

**虚函数表（vtable）**是一个指针数组，每个数组元素都是指向某个类的**虚函数实现**的指针。这个表是由编译器在编译时生成的，并用于支持运行时的**动态绑定（dynamic dispatch）**。

每个包含虚函数的类，编译器都会为其生成一个虚函数表。每个对象在内部会有一个指针（叫做 **vptr**），指向该类对应的虚函数表。

### 虚函数调用机制

以一个类层次结构为例：

```cpp
class Base {
public:
    virtual void foo() { std::cout << "Base::foo\n"; }
    virtual void bar() { std::cout << "Base::bar\n"; }
};

class Derived : public Base {
public:
    void foo() override { std::cout << "Derived::foo\n"; }
    void bar() override { std::cout << "Derived::bar\n"; }
};
```

执行如下代码：

```cpp
Base* p = new Derived();
p->foo();
```

背后发生的事情：

1. **编译时**，编译器无法确定调用哪个版本的 `foo`，因为 `p` 是指向 `Base` 的指针。
2. **运行时**，`p` 实际指向的是 `Derived` 对象，其 `vptr` 指向的是 `Derived` 的 vtable。
3. **通过 vptr 查表**，找到 `foo` 的函数地址，最终调用 `Derived::foo()`。

### 虚函数表的组织结构

Base 的 vtable：

| 偏移 | 函数指针       |
| ---- | -------------- |
| 0    | Base::foo 地址 |
| 1    | Base::bar 地址 |

Derived 的 vtable：

| 偏移 | 函数指针          |
| ---- | ----------------- |
| 0    | Derived::foo 地址 |
| 1    | Derived::bar 地址 |

每个对象内部结构大致如下（伪结构）：

```cpp
class Base {
    void** vptr;  // 指向虚函数表
    ...
};
```

- **vtable 与 vptr**

  - 只要类中有虚函数，编译器就会生成 **vtable**（虚函数表）。

  - 即使虚函数没有被重写，只要存在，也会生成 vtable。

  - 每个类一张 vtable，被该类所有对象共享；每个对象有一个 **vptr** 指向对应的 vtable。
  - 多继承时每个基类都有一个 vptr（可能有多个 vtable）

- **构造函数与析构函数中的虚函数调用**

  - 在构造函数或析构函数内部调用虚函数**不会发生多态**。

  - 这是因为在对象构造或销毁过程中，派生类部分可能尚未构造或已经销毁。

  - 调用的始终是**当前类自己的版本**（静态绑定）。

- **静态绑定 vs 动态绑定**

  - **静态绑定（Static Binding）**：编译时确定函数地址，例如普通函数或构造/析构函数内部调用虚函数。

  - **动态绑定（Dynamic Binding）**：运行时根据对象的实际类型确定函数地址，虚函数实现多态依赖动态绑定。

- 多继承与 vptr/vtable

  - **非虚基类**

    - 每个非虚基类子对象在派生类对象中独立存在。
  
    - 如果基类有虚函数，每个子对象有自己的 **vptr** 指向对应的 vtable。

    - 所以多继承对象可能有多个 vptr 和 vtable。

  
  - **虚基类**
  
    - 虚基类在整个继承体系中只有一份子对象（共享内存）。
  
    - vptr 也只保留一份，避免重复。

###  验证虚函数表存在

用如下方法手动“探测”虚函数表内容：

```cpp
#include <iostream>
#include <iomanip>  // std::hex, std::showbase

// 定义函数指针类型，指向无参、无返回值函数
using Fun = void(*)();

// ------------------------------
// 基类 Base，包含两个虚函数
// ------------------------------
class Base {
public:
    virtual void f() { std::cout << "Base::f\n"; }
    virtual void g() { std::cout << "Base::g\n"; }
};

// ------------------------------
// 派生类 Derived，重写 f，继承 g
// ------------------------------
class Derived : public Base {
public:
    void f() override { std::cout << "Derived::f\n"; }
    // g() 继承 Base::g
};

// ------------------------------
// 打印对象的虚函数表（vtable）
// ------------------------------
void printVTable(void* obj, const std::string& name, int count) {
    std::cout << "\n[" << name << " 对象的 vtable]\n";

    // 获取对象的 vptr（指向 vtable 的指针）
    Fun* vtable = *(Fun**)obj;

    // 遍历前 count 个虚函数指针，打印地址并调用
    for (int i = 0; i < count; ++i) {
        std::cout << "vtable[" << i << "] = "
                  << std::hex << std::showbase
                  << reinterpret_cast<void*>(vtable[i])
                  << " -> 调用结果：";
        vtable[i]();  // 调用虚函数
    }
}

int main() {
    Base b;
    Derived d;

    // 打印 Base 和 Derived 对象的 vtable
    printVTable(&b, "Base", 2);
    printVTable(&d, "Derived", 2);

    return 0;
}
```
输出：

```txt
[Base 对象的虚函数表 vtable 信息]
vtable[0] = 00007FF68F34123A -> 调用结果：Base::f
vtable[0x1] = 00007FF68F3411F9 -> 调用结果：Base::g

[Derived 对象的虚函数表 vtable 信息]
vtable[0] = 00007FF68F3414B5 -> 调用结果：Derived::f
vtable[0x1] = 00007FF68F3411F9 -> 调用结果：Base::g
```

- 未重写的函数（如 `Base::g`）地址相同，继承不变。
- 被重写的函数（如 `Derived::f`）地址不同，指向新的实现。
- 注意事项
  - `Fun* vtable = *(Fun**)obj;` 利用对象开头存储 vptr 的特性，强制转换为函数指针数组指针，然后解引用即可得到虚函数表地址。
  - 这种访问方式是“未定义行为”的一部分，不保证在所有编译器或优化等级下一致，仅用于**学习和调试目的**。
  - 在类中添加数据成员或者改变虚函数的顺序，都会影响 vtable 的结构。