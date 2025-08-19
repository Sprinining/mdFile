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
