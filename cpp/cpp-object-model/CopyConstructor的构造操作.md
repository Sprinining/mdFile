## Copy Constructor 的构造操作

### 拷贝构造函数的作用

**拷贝构造函数（Copy Constructor）** 用于：

- 用一个已有对象初始化新对象
- 函数按值传参或返回对象时调用
- 显式拷贝对象

典型形式：

```cpp
class A {
public:
    A(const A& rhs);
};
```

### Default Memberwise Initialization

当一个类 **没有提供显式拷贝构造函数** 时，用同类型对象初始化新对象：

```cpp
MyClass obj1;
MyClass obj2 = obj1; // 使用合成拷贝构造
```

内部机制

1. 编译器合成的拷贝构造函数会使用 **default memberwise initialization**
2. **memberwise initialization** 的含义：
   - 对象的每个 **非静态成员**都会被“逐个初始化”
   - 对于 **内置类型成员**（int、float、指针等），直接复制其值
   - 对于 **成员对象（class 类型）**，递归调用其拷贝构造函数，而不是按位复制

> 也就是说，对象的每个成员会按照其类型逐个调用构造函数（内置类型直接复制，类类型递归调用拷贝构造），确保对象结构完整。

### Bitwise Copy Semantics

当一个类 **没有定义显式拷贝构造函数** 时：

- **编译器可能会合成一个拷贝构造函数**
- **前提条件**：类 **能够表现出 bitwise copy semantics（按位拷贝语义）**

> 换句话说，如果类的成员或基类存在某些特性，使得按位拷贝会破坏对象完整性或多态行为，则 **编译器不会合成拷贝构造**，必须用户显式提供。

### 不支持按位拷贝的四种情况

#### **类内含有一个成员对象，而该成员对象的类声明有拷贝构造**

- 无论是用户显式声明还是编译器合成。
- 说明成员对象自身必须调用拷贝构造，不能按位拷贝。

```cpp
struct Buffer {
    int* data;
    Buffer(const Buffer& rhs) { data = new int(*rhs.data); } // 显式拷贝构造
};

struct Container { 
    Buffer buf; 
};

Container c1{Buffer{42}};
Container c2 = c1; // 调用 Buffer 的拷贝构造
```

#### **类继承自一个基类，而该基类存在拷贝构造**

- 无论显式声明还是编译器合成。
- 派生类拷贝构造必须调用基类拷贝构造函数。

```cpp
struct Base { 
    int x; 
    Base(const Base& rhs) : x(rhs.x) {} // 显式拷贝构造
};

struct Derived : Base { 
    int y; 
};

Derived d1;
Derived d2 = d1; // 调用 Base 的拷贝构造
```

#### **类声明了一个或多个虚函数**

- 对象中会有 vptr，按位拷贝会破坏虚函数表指针。

##### 同类对象之间的拷贝

```cpp
MyClass obj1;
MyClass obj2 = obj1; // 同类对象
```

- 如果类 **可以表现出 bitwise copy semantics**，编译器可以直接按位复制内存（bitwise copy）
- 内置类型、普通成员变量直接复制即可
- **类类型成员**或有特殊行为的成员会递归调用其拷贝构造
- vptr 对象是同类对象，指向同一虚表，按位拷贝安全

##### 基类对象拷贝派生类对象

```cpp
Derived d;
Base b = d; // 基类对象用派生类对象初始化
```

- 发生 **对象切片**：只拷贝 Base 子对象
- **vptr 必须重新设置**，指向 Base 的虚表，而不能直接复制 Derived 的 vptr
- 否则虚函数调用可能错误
- 编译器生成的合成拷贝构造会安全处理 vptr 和基类子对象

#### **类派生自继承链中有一个或多个虚基类**

- 虚基类子对象由最派生类负责初始化
- 按位拷贝会破坏虚基类唯一性

##### 同类对象拷贝

```cpp
MyClass a;
MyClass b = a; // 同类对象
```

- 如果类可以 **表现出 bitwise copy semantics**，编译器可以按位复制内存（内置类型直接复制，成员对象递归调用拷贝构造）
- vptr 和虚基类不会破坏对象结构

##### 基类对象拷贝派生类对象

```cpp
struct VBase { int a; };
struct B : virtual VBase { int b; };
struct C : virtual VBase { int c; };
struct D : B, C { int d; };

D d;
B b = d; // 基类对象 B 用派生类 D 初始化
```

- `b` 是 **新的 B 类型对象**

- **B 子对象** 会被拷贝（按 B 的合成拷贝构造）

- **虚基类子对象（VBase）**：
  - 在 B b 中，虚基类仍然是 **自己的 VBase 子对象**（B 对象内有一份 VBase 子对象）
  - 并 **不是 D 内那一份 VBase 子对象**
  
- 因此 `b.a` 和 `d.a` 是不同的内存

- 按位拷贝 D 的 B 子对象到 b 的 B 子对象时，必须保证 **b 内的 VBase 子对象被正确初始化**，不能直接复制 D 内的 VBase，否则会破坏虚基类唯一性原则

以上任何一种情况都会让 bitwise copy 语义失效，合成拷贝构造函数仍然存在，但会按 **memberwise initialization** 逐成员调用拷贝构造，而不是直接按位复制。