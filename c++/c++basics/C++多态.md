## C++多态

C++ 中的**多态（Polymorphism）\**是面向对象编程（OOP）的核心特性之一，它允许程序在运行时根据对象的实际类型调用对应的方法，从而实现\**接口的统一调用，行为的差异化实现**。多态分为两大类：

### 静态多态（编译时多态）

静态多态在**编译期间就可以确定调用的函数**，典型方式有：

#### 1. 函数重载（Function Overloading）

同一作用域中，函数名相同但参数列表不同。

```cpp
void print(int x) { cout << "int: " << x << endl; }
void print(double x) { cout << "double: " << x << endl; }

print(5);    // 输出 int: 5
print(3.14); // 输出 double: 3.14
```

#### 2. 运算符重载（Operator Overloading）

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

#### 3. 模板（Templates）

泛型编程的一种形式，通过参数化类型实现重用。

```cpp
template<typename T>
T add(T a, T b) {
    return a + b;
}
```

### 动态多态（运行时多态）

动态多态的核心是通过**基类指针或引用调用派生类的重写方法**，需要满足以下三个必要条件：

1. **继承（Inheritance）**
2. **虚函数（Virtual Function）**
3. **基类指针或引用调用派生类对象**

```cpp
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
    a->speak();  // 根据对象实际类型调用方法
}

int main() {
    Animal a;
    Dog d;
    makeSound(&a); // 输出 Animal speaks
    makeSound(&d); // 输出 Dog barks（动态多态）
}
```

### 虚函数表（vtable）机制简述

- 当一个类有虚函数时，编译器会为类生成一个“虚函数表”（vtable），指向所有虚函数的地址。

- 每个对象中会包含一个“虚指针”（vptr）指向该类的虚函数表。

- 调用虚函数时，程序会通过 `vptr` 找到对应的函数地址，实现运行时绑定。

### 纯虚函数与抽象类

如果一个类中至少有一个**纯虚函数**（声明格式为 `= 0`），它就是**抽象类**，不能实例化。

```cpp
class Shape {
public:
    virtual void draw() = 0;  // 纯虚函数
};

class Circle : public Shape {
public:
    void draw() override {
        cout << "Draw Circle" << endl;
    }
};
```

### 相关关键字

| 关键字     | 作用                       |
| ---------- | -------------------------- |
| `virtual`  | 声明虚函数，启用动态多态   |
| `override` | 明确表示重写，避免误操作   |
| `final`    | 禁止进一步重写（C++11 起） |
| `= 0`      | 定义纯虚函数，创建抽象类   |

### 使用建议

- **基类的析构函数**应当设为 `virtual`，以确保通过基类指针删除派生类对象时能正确析构。

```cpp
class Base {
public:
    virtual ~Base() {}
};
```

通过**基类指针**来管理一个**派生类对象**时，如果基类的析构函数不是 `virtual`，那么**只会调用基类的析构函数，派生类的析构函数不会被调用**，从而导致**资源泄漏或逻辑不完整**。

没有 `virtual`：`delete p` 时只调用了 `Base` 的析构函数（**静态绑定**）。

有 `virtual`：`delete p` 时会通过 **虚函数表（vtable）** 找到正确的析构顺序（**动态绑定**）。

### C++接口

C++ 接口就是一个只包含纯虚函数（pure virtual functions）的抽象类。

| 比较项     | 接口（Interface）      | 抽象类（Abstract Class）             |
| ---------- | ---------------------- | ------------------------------------ |
| 成员       | 只包含纯虚函数和虚析构 | 可以有数据成员、普通函数、构造函数等 |
| 用途       | 只定义行为             | 可作为基类提供部分实现               |
| 多继承支持 | ✅ （模拟接口组合）     | ✅（需小心菱形继承）                  |
| 实例化     | ❌ 不可                 | ❌ 不可（除非纯虚函数都被实现）       |

### 为什么 C++ 构造函数不能是虚函数

因为在构造函数执行期间，虚函数机制（vtable/vptr）尚未准备好或不完整，无法实现多态行为。

#### 深入原理分析

##### 1. **构造函数的职责是“初始化”对象**

构造函数的主要目标是：

- 分配内存；
- 初始化数据成员；
- 设置 vptr（虚函数指针）；

也就是说，**vptr 是在构造过程中才设定的**，而不是之前就有的。

##### 2. **虚函数依赖于 vtable/vptr**

- 多态调用的前提是：**对象已有 vptr，并且它正确地指向了 vtable**；
- 然而在构造函数体内：
  - vptr 尚未指向最终的派生类的 vtable；
  - 即使设置了，也只指向当前构造函数所属类的 vtable（不是派生类的）；
- 所以，如果构造函数是虚函数，在派生类构造过程中就无法正常解析该函数应该调用哪个版本。

##### 3. **调用构造函数时对象尚未完全构造完成**

- 构造时是“由上到下”构造的：
  - 先构造基类 -> 再构造成员 -> 再构造派生类；

- 若构造函数是虚函数，就可能在对象未构造完成时通过多态机制“调用派生类的构造函数”；

- 这不安全！因为派生类的数据成员尚未初始化，调用派生类版本可能出错或未定义行为。

#### 举个危险的例子（如果允许是虚函数）

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

### 构造函数内部能调用虚函数吗

- **构造函数内部**是**可以语法上调用虚函数的**
-  **但这不是多态调用（即不通过 vtable），而是静态绑定 —— 调用当前类的版本**，而不是派生类的重写版本。