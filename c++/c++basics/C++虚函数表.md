## C++虚函数表

C++ 中的虚函数表（vtable）是实现**运行时多态性（polymorphism）**的核心机制。它是编译器在支持虚函数时使用的一种内部技术。

### 一、什么是虚函数表（vtable）？

**虚函数表（vtable）**是一个指针数组，每个数组元素都是指向某个类的**虚函数实现**的指针。这个表是由编译器在编译时生成的，并用于支持运行时的**动态绑定（dynamic dispatch）**。

每个包含虚函数的类，编译器都会为其生成一个虚函数表。每个对象在内部会有一个指针（叫做 **vptr**），指向该类对应的虚函数表。

### 二、虚函数调用机制流程

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

### 三、vtable 的组织结构

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

### 四、vtable 的一些关键细节

#### 1. 只要类中有虚函数，编译器就会生成 vtable。

即使一个虚函数没有被重写，只要存在，就会生成 vtable。

#### 2. 每个类一张 vtable，共享使用；每个对象一个 vptr。

#### 3. 构造函数和析构函数中的虚函数调用是静态绑定的。

- **静态绑定（Static Binding）**：编译时就确定函数调用地址。例如普通函数调用。

- **动态绑定（Dynamic Binding）**：运行时根据实际对象类型确定函数调用地址。虚函数实现多态靠的就是动态绑定。

- 在构造函数和析构函数内部调用虚函数时，不会发生多态，调用的是当前类自己的版本（即静态绑定），而不是派生类中重写后的版本（即动态绑定）。

> 1. 构造函数阶段：
>
> 当执行 `Base()` 构造函数时，对象还**只是 Base 类型**，此时派生类 `Derived` 的成员还没构造好。为了**避免访问未初始化的成员**，**虚函数调用被编译器强制降级为静态绑定**，也就是调用 `Base::call()`。
>
> 2. 析构函数阶段：
>
> 析构是**从派生类向基类**逐层析构的。
>
> 当执行 `Base` 的析构函数时，派生类 `Derived` 的部分已经被销毁了，此时也不能调用 `Derived::call()`，否则可能访问已销毁的内存。
>
> 所以，**析构函数中虚函数调用也降级为静态绑定**，只会调用 `Base::call()`。

```cpp
class A {
public:
    A() { foo(); }  // 非虚调用
    virtual void foo() { std::cout << "A::foo\n"; }
};

class B : public A {
public:
    void foo() override { std::cout << "B::foo\n"; }
};

B b;  // 调用的是 A::foo，而不是 B::foo！
```

因为构造期间 B 的 vptr 尚未设置。

4. 多继承时每个基类都有一个 vptr（可能有多个 vtable）

```cpp
class A {
public:
    virtual void foo() {}
};

class B {
public:
    virtual void bar() {}
};

class C : public A, public B {
public:
    void foo() override {}
    void bar() override {}
};
```

`C` 对象中将包含两个 `vptr`，分别指向 A 和 B 的虚函数表。

###  五、简单验证 vtable 存在（用指针分析）

用如下方法手动“探测”虚函数表内容：

```cpp
#include <iostream>
#include <iomanip>  // 用于 std::hex 和 std::showbase 来格式化地址输出

// 定义函数指针类型，指向无参、无返回值的函数
typedef void(*Fun)();

// ------------------------------
// 基类 Base，包含两个虚函数 f 和 g
// ------------------------------
class Base {
public:
    virtual void f() { std::cout << "Base::f\n"; }  // 虚函数1
    virtual void g() { std::cout << "Base::g\n"; }  // 虚函数2
};

// ------------------------------
// 派生类 Derived，从 Base 派生
// 只重写了虚函数 f，没有重写 g
// ------------------------------
class Derived : public Base {
public:
    void f() override { std::cout << "Derived::f\n"; }  // 重写 f()
    // g() 没有重写，继承 Base::g 的实现
};

/*
 * 工具函数：打印某个对象的虚函数表（vtable）内容
 * 参数：
 *   - obj: 任意类对象的地址（作为 void* 传入）
 *   - name: 类名，用于打印提示
 *   - count: 预估虚函数数量，用于遍历虚函数表（如 Base 和 Derived 都有两个虚函数）
 */
void printVTable(void* obj, const std::string& name, int count) {
    std::cout << "\n[" << name << " 对象的虚函数表 vtable 信息]\n";

    /*
     * C++ 对象模型中：
     *   - 对于含虚函数的类对象，内存的开头存储一个指向 vtable 的指针（vptr）
     *   - vtable 是一个函数指针数组，每个指针指向虚函数的真实实现地址
     *
     * 以下代码做了两步：
     *   1. 将对象指针 obj 强制转换为 Fun** 类型（即函数指针的指针）
     *   2. 解引用后得到 vtable 的首地址
     */
    Fun* vtable = *(Fun**)obj;

    // 遍历 vtable 表中前 count 个虚函数指针，打印地址并调用
    for (int i = 0; i < count; ++i) {
        std::cout << "vtable[" << i << "] = "
                  << std::hex << std::showbase                // 设置为十六进制并显示 0x 前缀
                  << reinterpret_cast<void*>(vtable[i])       // 打印函数地址（转换为 void* 避免按函数格式解释）
                  << " -> 调用结果：";

        vtable[i]();  // 调用该虚函数（通过函数指针）
    }
}

int main() {
    Base b;      // 创建 Base 类对象
    Derived d;   // 创建 Derived 类对象（继承自 Base）

    // 打印 Base 对象的 vtable，预计有两个虚函数：f 和 g
    printVTable(&b, "Base", 2);

    // 打印 Derived 对象的 vtable，f 被重写，g 继承自 Base
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

- 每个函数地址如 `0x56522c647aa0` 是实际的代码段地址（在程序的虚拟内存空间里）。

- 虚函数表（vtable）是一个函数指针数组，这些地址是编译期确定、链接时布置的，**运行时通过 vptr 引用**。

- 虽然地址每次编译可能不同，但你会发现：

  - `Base::g` 的地址在 Base 和 Derived 中是一样的（继承未修改）；

  - `f()` 被重写时，Derived 的 `vtable[0]` 地址和 Base 的不同，说明指向不同函数实现。

 注意事项

- 这种访问方式是“未定义行为”的一部分，不保证在所有编译器或优化等级下一致，仅用于**学习和调试目的**。
- 在类中添加数据成员或者改变虚函数的顺序，都会影响 vtable 的结构。