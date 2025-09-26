## C++ 初始化析构顺序

### 类成员的初始化顺序

初始化顺序规则：

1. 类成员变量的初始化总是按照它们在类中出现的**声明顺序**进行，而不会受构造函数初始化列表中书写顺序的影响。
2. 析构顺序与初始化顺序相反。

```cpp
#include <iostream>
using namespace std;

struct A {
    A() { cout << "A constructor\n"; }
    ~A() { cout << "A destructor\n"; }
};

struct B {
    B() { cout << "B constructor\n"; }
    ~B() { cout << "B destructor\n"; }
};

class Test {
    A a;
    B b;

public:
    Test() : b(), a() {  // 初始化列表顺序无效！仍按 a -> b 顺序初始化
        cout << "Test constructor\n";
    }
    ~Test() {
        cout << "Test destructor\n";
    }
};
```

输出：

```txt
A constructor
B constructor
Test constructor
Test destructor
B destructor
A destructor
```

### 继承关系中的构造和析构顺序

构造顺序：

1. **先构造基类**
2. 然后按顺序构造**成员对象**
3. 最后构造**派生类本身**

析构顺序：

与构造顺序**完全相反**，先析构派生类，再析构成员，再析构基类。

示例：

```cpp
#include <iostream>
using namespace std;

struct Base {
    Base() { cout << "Base constructor\n"; }
    ~Base() { cout << "Base destructor\n"; }
};

struct Member {
    Member() { cout << "Member constructor\n"; }
    ~Member() { cout << "Member destructor\n"; }
};

struct Derived : public Base {
    Member m;
    Derived() { cout << "Derived constructor\n"; }
    ~Derived() { cout << "Derived destructor\n"; }
};
```

输出：

```txt
Base constructor
Member constructor
Derived constructor
Derived destructor
Member destructor
Base destructor
```

### 静态成员对象的初始化与析构

 类内静态成员：

- 静态成员变量在**类的作用域外定义并初始化**
- 生命周期：从程序开始时初始化（或首次使用时），到程序结束

```cpp
class MyClass {
public:
    static int count;
};

int MyClass::count = 0;
```

静态成员变量的构造和析构顺序受**全局/静态对象初始化顺序规则**影响，**跨文件访问要谨防静态初始化顺序问题（Static Initialization Order Fiasco）**。

> #### 什么是“全局/静态对象初始化顺序”规则？
>
> 全局对象、静态局部对象、静态成员变量，它们的初始化遵循以下规则：
>
> - 同一翻译单元（即同一个 `.cpp` 文件）中的静态/全局对象，按照**它们在代码中声明的顺序**初始化。
> - **析构顺序与构造顺序相反**。
> - **不同翻译单元之间的全局/静态对象，其初始化顺序是未定义的！**
>
> 这就意味着：**无法保证 A.cpp 中的全局对象比 B.cpp 中的先初始化。**
>

### 局部对象的构造与析构

局部变量（自动存储）：

- 进入作用域构造
- 离开作用域析构

```cpp
void func() {
    A a;
    B b;
}
// 输出：A 构造 -> B 构造 -> B 析构 -> A 析构
```

### 数组中对象的构造和析构顺序

数组成员：

- 构造按**数组顺序**
- 析构按**逆序**

```cpp
A arr[3];
// 构造顺序：arr[0], arr[1], arr[2]
// 析构顺序：arr[2], arr[1], arr[0]
```

### new/delete 创建的对象

```cpp
A* a = new A();  // 构造
delete a;        // 析构
```

- 用 `new` 创建的对象必须用 `delete` 手动析构（除非用智能指针如 `std::unique_ptr`）
- 用 `new[]` 创建的数组，必须用 `delete[]` 释放

### SIOF

**Static Initialization Order Fiasco（SIOF）** 是 C++ 中的一个经典问题，指**不同编译单元（.cpp 文件）中的静态变量**的初始化顺序**不确定**，导致程序可能崩溃或行为异常。

在 C++ 中，**静态/全局对象的初始化顺序在不同翻译单元间是不确定的**。如果一个静态/全局对象在其构造过程中访问了另一个尚未完成初始化的静态/全局对象，程序将产生**未定义行为**。这可能导致程序崩溃、数据错误或其他难以预测的问题。

为避免这种情况，常用的解决方案之一是使用“懒汉式”局部静态对象（函数内部的 `static` 变量），它们保证在首次调用时初始化，从而确保对象的初始化顺序受控且安全。

#### 示例：全局对象（无static修饰）

`A.h`

```cpp
#pragma once
class B;  // 前向声明

class A {
public:
    A();
    void doSomething();
};

extern A a;  // 声明外部定义的全局对象 a
```

`B.h`

```cpp
#pragma once
class A;  // 前向声明

class B {
public:
    B();
    void doSomething();
};

extern B b;  // 声明外部定义的全局对象 b
```

`A.cpp`

```cpp
#include <iostream>
#include "B.h"
#include "A.h"

A::A() {
    std::cout << "A constructed\n";
    b.doSomething();  // 使用全局对象 b
}

void A::doSomething() {
    std::cout << "A does something\n";
}

A a;  // 定义全局对象 a
```

`B.cpp`

```cpp
#include <iostream>
#include "B.h"
#include "A.h"

B::B() {
    std::cout << "B constructed\n";
    a.doSomething();  // 使用全局对象 a
}

void B::doSomething() {
    std::cout << "B does something\n";
}

B b;  // 定义全局对象 b
```

`main.cpp`

```cpp
#include <iostream>

int main() {
    std::cout << "Main running\n";
    return 0;
}
```

运行结果可能是（顺序由链接器决定）：

##### 情况 1

```txt
A constructed
B does something
B constructed
A does something
Main running
```

情况 1 的流程：

1. 程序启动，进入全局初始化阶段。

2. 编译器决定：先初始化 `a`（即先调用 `A::A()`）。

3. 进入 `A::A()`：

   - 输出 `"A constructed"`

   - 调用 `b.doSomething()`，此时：
     - `b` 已经是个“已分配但尚未构造”的对象（注意：构造函数还没跑）
     - 于是 `B::doSomething()` 被调用 → 输出 `"B does something"`

4. `A::A()` 完成。

5. 回到初始化流程，继续构造 `b`：

   - 现在正式执行 `B::B()`，输出 `"B constructed"`

   - 调用 `a.doSomething()` → 输出 `"A does something"`

6. 全局对象构造完毕 → `main()` 开始 → 输出 `"Main running"`

为什么 `"B constructed"` 在 `"B does something"` 之后？

在 C++ 中，对象创建分两步：

1. **分配内存**
   - 编译器为全局变量 `b` 分配地址空间。
   - 此时指针可以访问，但对象还没初始化。
2. **调用构造函数**
   - 执行 `B::B()`，初始化成员，输出 `"B constructed"`。
   - 只有构造函数执行完，对象才算完全构造。

```cpp
A::A() {
    std::cout << "A constructed\n";
    b.doSomething();  // b 已分配内存，但构造函数尚未执行
}
```

- **内存已分配**，所以语法上可调用 `b.doSomething()`
- **构造未完成**，b 处于未初始化状态
- 访问未构造对象成员 → **未定义行为**，可能输出 `"B does something"`，也可能崩溃

##### 情况 2

```txt
B constructed
Segmentation fault (core dumped)
```

如果程序启动时，先构造了 `b`：

1. 执行 `B::B()` 构造函数
2. 构造函数内部访问了 `a.doSomething()`
3. 此时 `a` 的构造函数 `A::A()` 还**没有被调用过**
4. 所以 `a` 所指代的内存**可能还没初始化、vtable 还没绑定、数据成员未定义**
5. 最终可能导致：
   - **访问未初始化内存**
   - **程序崩溃（段错误）**
   - **调用了未绑定的虚函数（vtable 还没设置）**
   - **输出错乱甚至死锁**（如果是多线程对象）

#### 正确做法

用“懒汉式”静态局部对象。

`A.h`

```cpp
#pragma once

class B;  // 前向声明

class A {
public:
    A();
    void doSomething();

    void init();  // 延迟初始化，避免递归
};

A& getA();  // 获取单例对象
```

`B.h`

```cpp
#pragma once

class A;  // 前向声明

class B {
public:
    B();
    void doSomething();

    void init();
};

B& getB();
```

`A.cpp`

```cpp
#include <iostream>
#include "A.h"
#include "B.h"

A::A() {
    std::cout << "A constructed\n";
}

void A::doSomething() {
    std::cout << "A does something\n";
}

void A::init() {
    // 延迟调用 B 的方法，避免构造时递归
    getB().doSomething();
}

A& getA() {
    static A a;  // 局部静态，线程安全且懒加载
    return a;
}
```

`B.cpp`

```cpp
#include <iostream>
#include "B.h"
#include "A.h"

B::B() {
    std::cout << "B constructed\n";
}

void B::doSomething() {
    std::cout << "B does something\n";
}

void B::init() {
    getA().doSomething();
}

B& getB() {
    static B b;
    return b;
}
```

`main.cpp`

```cpp
#include <iostream>
#include "A.h"
#include "B.h"

int main() {
    std::cout << "Main running\n";

    // 显式触发初始化，避免构造函数递归调用
    getA().init();
    getB().init();

    return 0;
}
```

打印输出：

```txt
Main running
A constructed
B constructed
B does something
A does something
```
