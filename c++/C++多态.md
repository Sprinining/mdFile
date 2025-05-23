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