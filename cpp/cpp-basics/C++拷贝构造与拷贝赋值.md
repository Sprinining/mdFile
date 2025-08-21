##  C++ 拷贝构造与拷贝赋值

### 拷贝构造函数

在 C++ 中，**拷贝构造函数（Copy Constructor）** 是一种特殊的构造函数，用于使用一个已有对象来初始化一个新对象。它的典型声明形式如下：

```cpp
ClassName(const ClassName& other);
```

```cpp
#include <iostream>
using namespace std;

class Person {
public:
    string name;

    // 构造函数
    Person(string n) : name(n) {}

    // 拷贝构造函数
    Person(const Person& other) {
        cout << "拷贝构造函数调用" << endl;
        name = other.name;
    }
};

int main() {
    Person p1("Alice");
    Person p2 = p1; // 调用拷贝构造函数
    cout << p2.name << endl;
    return 0;
}
```

- 拷贝构造函数的第一个参数必须是**“对自身类型的 `const` 引用”或“引用”**，不能是按值传递，否则会导致无限递归调用（编译失败）。

- 几乎所有正常使用场景下，拷贝构造函数的参数都是 `const T&`。
  - **支持 const 对象复制**： 如果不写 `const`，那 `MyClass obj2 = obj1;` 中如果 `obj1` 是 `const`，就不能调用 `MyClass(MyClass&)`。
  
    | 引用类型    | 可绑定对象类型                                          | 说明                     |
    | ----------- | ------------------------------------------------------- | ------------------------ |
    | `T&`        | 非 const 左值对象                                       | 常规左值引用             |
    | `const T&`  | 非 const 左值对象、const 左值对象、**右值（临时对象）** | 常量左值引用，可绑定右值 |
    | `T&&`       | 非 const 右值                                           | 右值引用，用于移动语义   |
    | `const T&&` | 右值，可以是 const 或非 const                           | 很少用，通常不直接使用   |
  - **拷贝操作本质上不应修改源对象**： 加上 `const` 表示“拷贝源是只读的”，更安全、符合语义。
  - **和 STL、标准库兼容性更好**： 所有标准容器类、算法等内部实现都假设拷贝构造是 `const T&`。

#### 拷贝构造函数调用时机

##### 用已有对象初始化新对象

```cpp
Person p1("Alice");
Person p2 = p1;    // 拷贝构造
Person p3(p1);     // 拷贝构造
```

##### 按值传参

```cpp
class Person {
public:
    string name;

    Person(string n) : name(n) {}

    Person(const Person& other) {
        cout << "拷贝构造函数被调用" << endl;
        name = other.name;
    }
};

// 当 greet(a) 被调用时，a 会被拷贝一份，传给 p
// 在 greet 里面操作的是 a 的副本，不会影响 a 本身
void greet(Person p) {
    cout << "Hello " << p.name << endl;
}

int main() {
    Person a("Alice");
    greet(a);  // 这里会调用拷贝构造函数
}
```

##### 按值返回对象

```cpp
Person create() {
    Person tmp("Alice");
    return tmp;    // 拷贝构造（可能被 RVO/移动优化）
}
```

#### 合成拷贝构造函数

在 C++ 中，**合成拷贝构造函数（synthesized copy constructor）**是指编译器自动为一个类生成的拷贝构造函数，用于在对象复制时拷贝成员变量。

##### 合成拷贝构造函数的生成条件

编译器会自动生成拷贝构造函数，前提是**满足以下条件**：

1. **类本身没有用户自定义的拷贝构造函数**
   - 如果自己写了拷贝构造函数，编译器就不会再生成。
2. **类成员和基类可拷贝且可访问**
   - 所有**非静态成员**和**基类**的拷贝构造函数必须是可访问的（public/protected 或当前类是友元）。
   - 如果成员的拷贝构造函数是 `private` 且当前类不是友元，或被 `delete`，则不能生成。
3. **没有阻碍生成的特殊成员函数**
   - 例如移动构造被删除、析构函数是私有且不可访问等，可能影响合成拷贝构造函数的生成。
4. **成员类型可拷贝**
   - 类中不能包含**不可复制的成员**（如 `std::unique_ptr` 或被 delete 的类）。
   - 引用成员也是特殊情况，因为引用必须在构造时初始化。

##### 合成拷贝构造函数的行为

1. **先调用基类的拷贝构造函数**
   - 对所有直接基类按继承顺序调用拷贝构造，保证基类部分被正确复制。
2. **再按声明顺序拷贝非静态成员**
   - 所有非静态成员按在类中出现的顺序，逐一调用拷贝构造函数（内置类型直接复制，类类型调用对应拷贝构造）。
3. **静态成员不参与拷贝**
   - 静态成员属于类，不属于对象，所以合成拷贝构造函数不会拷贝它们。

```cpp
#include <iostream>
#include <string>
using namespace std;

class Base {
public:
    Base(const string& s = "") : name(s) {}
    string name;
};

class Derived : public Base {
public:
    Derived(const string& s = "", int v = 0) 
        : Base(s), value(v) {}
    int value;
};

int main() {
    Derived d1("Alice", 42);
    Derived d2 = d1;  // 调用合成拷贝构造函数

    cout << "d2.name = " << d2.name << endl;   // 基类成员先被拷贝
    cout << "d2.value = " << d2.value << endl; // 然后非静态成员按声明顺序拷贝
}
```

#### default 和 delete

合成函数是编译器在条件允许下自动生成的，`= default` 是程序员显式要求生成默认函数，可以在更多场景下恢复或控制默认行为：

```cpp
struct C {
    int x;
    C(const C&) = default;  // 明确使用合成版本
};
```

也可以禁用：

```cpp
struct D {
    int x;
    D(const D&) = delete;  // 禁止拷贝构造
};
```

#### 注意事项

1. **浅拷贝问题**
   - 合成拷贝构造函数对**指针成员**只拷贝地址，不拷贝指针所指内容。
   - 可能导致**双重释放或悬空指针**。
   - 解决：需要自己实现深拷贝，或者用 RAII 类型（如 `std::string`、`std::vector`、`std::unique_ptr` 等）。
2. **资源管理类要自定义**
   - 对有资源管理的类（内存、文件句柄、网络连接等）必须提供自定义拷贝构造和拷贝赋值函数，否则可能引发资源泄漏或重复释放。
3. **C++11 之后移动语义影响**
   - 如果类自定义了**移动构造/移动赋值函数**，但未提供拷贝构造，编译器可能**不会自动合成拷贝构造函数**。
   - 这可能导致无法按值传递对象，或者编译错误。
4. **基类与成员可访问性**
   - 合成拷贝构造函数要求**所有基类和非静态成员的拷贝构造函数都是可访问的**。
   - 如果某个成员的拷贝构造是 `private` 或被 `delete`，合成拷贝构造**不会生成**。
5. **引用成员限制**
   - 类中有**引用成员**（如 `int&`）时，必须自定义拷贝构造函数，因为引用必须在构造时初始化。
6. **静态成员不拷贝**
   - 静态成员属于类，不属于对象，因此不会参与拷贝构造。
7. **异常安全**
   - 如果成员拷贝可能抛出异常，需要注意异常安全（尤其是资源管理类）。

#### 如何避免拷贝构造开销

##### 引用传参

用引用（`T&` 或 `const T&`）代替值传递，避免调用拷贝构造。

```cpp
#include <iostream>
using namespace std;

class Person {
public:
    string name;
    Person(string n) : name(n) {}
};

void greet(const Person& p) {  // 引用传参，避免拷贝
    cout << "Hello " << p.name << endl;
}

int main() {
    Person a("Alice");
    greet(a);  // 不会调用拷贝构造
}
```

##### 移动语义（C++11）

如果一个对象是**临时的**、马上就要销毁了，那就没有必要复制它的资源，而是可以“**移动**”它的资源到新对象中。

```cpp
class MyArray {
public:
    int* data;
    int size;

    MyArray(int s) : size(s) {
        data = new int[size];
        cout << "构造" << endl;
    }

    // 拷贝构造（深拷贝）
    MyArray(const MyArray& other) {
        cout << "拷贝构造" << endl;
        size = other.size;
        data = new int[size];
        for (int i = 0; i < size; ++i)
            data[i] = other.data[i];
    }

    // 移动构造函数（转移资源）
    MyArray(MyArray&& other) noexcept {
        cout << "移动构造" << endl;
        data = other.data;
        size = other.size;
        other.data = nullptr;  // 防止析构时重复释放
        other.size = 0;
    }

    ~MyArray() {
        delete[] data;
    }
};

MyArray createArray() {
    MyArray temp(10);  // 临时对象
    return temp;       // 会触发移动构造
}

int main() {
    MyArray a = createArray();  // 移动构造，而不是拷贝
}
```

有了移动构造函数，编译器优先选用移动构造：

- 如果一个类型同时有**拷贝构造**和**移动构造**，当对象是**右值（临时对象、将亡值）**时，编译器会优先调用**移动构造函数**。

- 当对象是**左值**时，调用的还是**拷贝构造函数**。

- 如果没有定义移动构造函数，或者移动构造不可用（被删除或不可访问），才会调用拷贝构造函数。

| 特性     | 拷贝构造函数           | 移动构造函数（C++11）    |
| -------- | ---------------------- | ------------------------ |
| 参数类型 | `const T&`             | `T&&`（右值引用）        |
| 复制行为 | 分配新资源并复制       | 把资源“转移”给新对象     |
| 性能     | 较慢（复制内容）       | 快（只是转移指针）       |
| 触发条件 | 对临时对象初始化新对象 | 优先触发（如果定义了它） |

### 拷贝赋值运算符

拷贝赋值运算符是一个特殊的成员函数，用于定义对象之间通过 `=` 进行赋值的行为：

```cpp
T& operator=(const T& other);
```

将 `other` 的值赋给当前对象（`*this`），并返回对当前对象的引用。

#### 拷贝赋值运算符调用时机

拷贝赋值运算符（`operator=`）的调用时机主要是 **已有对象被另一个对象赋值时**，而不是初始化。

##### 对已有对象赋值

```cpp
Person p1("Alice");
Person p2("Bob");

p2 = p1;  // 调用拷贝赋值运算符
```

- `p2` 已经存在
- 用 `p1` 的内容覆盖 `p2` 的内容
- 会调用拷贝赋值函数（`operator=(const Person&)`）

##### 函数返回值赋值

```cpp
Person foo() { return Person("Temp"); }

Person p;
p = foo();   // 调用拷贝赋值运算符（可能被移动赋值优化）
```

- 函数返回一个对象给已有对象
- 调用拷贝赋值或移动赋值

#### 合成拷贝赋值运算符

如果用户没有显式定义赋值运算符，**编译器会自动合成一个**，前提是：

1. 类本身没有自定义拷贝赋值运算符

- 如果自己写了 `operator=(const ClassName&)`，编译器就不会再生成。

2. 基类和成员可赋值

- 所有**直接基类**的拷贝赋值运算符必须是可访问且可调用的。
- 所有**非静态成员**的拷贝赋值运算符必须是可访问且可调用的。
- 如果成员或基类是 `const`、引用类型或者其拷贝赋值被 `delete`，合成拷贝赋值就无法生成。

3. 特殊成员函数影响

- 如果类定义了**移动构造或移动赋值函数**，但未定义拷贝构造/拷贝赋值，编译器可能**不会自动生成**拷贝赋值函数（C++11 以后）。
- 编译器生成的函数会按成员逐一调用**拷贝赋值运算符**。

其行为通常是**逐成员赋值**（浅拷贝），如下所示：

```cpp
class A {
public:
    int x;
    std::string y;
};
// 编译器会自动生成如下函数：
A& A::operator=(const A& other) {
    this->x = other.x;
    this->y = other.y;
    return *this;
}
```

- 可以使用 `= default` 显式要求编译器生成：

```cpp
A& operator=(const A&) = default;
```

也可以禁止赋值：

```cpp
A& operator=(const A&) = delete;
```

### 对比

#### 拷贝构造函数 VS 拷贝赋值运算符

| 特性             | 拷贝构造函数                           | 拷贝赋值运算符                               |
| ---------------- | -------------------------------------- | -------------------------------------------- |
| 目的             | **创建一个对象**，并用已有对象初始化它 | **将一个已有对象的值赋给另一个已存在的对象** |
| 典型签名         | `T(const T& other);`                   | `T& operator=(const T& other);`              |
| 返回值类型       | 无返回值                               | 返回 `T&`（支持链式赋值）                    |
| 调用时机         | 对象定义时： `T b = a;`                | 对象已存在后赋值： `b = a;`                  |
| 对象状态         | 用于**构造新对象**                     | 用于**更新已存在对象**                       |
| 可省略调用       | 是，可被优化掉（RVO/NRVO）             | 否，赋值行为不可省略                         |
| 是否会检查自赋值 | 一般不需处理                           | 推荐处理（`if (this != &other)`)             |

示例代码：

```cpp
#include <iostream>

struct T {
    int* data;

    // 构造
    T(int val = 0) {
        data = new int(val);
        std::cout << "Default Constructor\n";
    }

    // 拷贝构造
    T(const T& other) {
        data = new int(*other.data);
        std::cout << "Copy Constructor\n";
    }

    // 拷贝赋值
    T& operator=(const T& other) {
        if (this != &other) {
            delete data;
            data = new int(*other.data);
        }
        std::cout << "Copy Assignment\n";
        return *this;
    }

    // 移动构造
    T(T&& other) noexcept {
        data = other.data;
        other.data = nullptr;
        std::cout << "Move Constructor\n";
    }

    // 移动赋值
    T& operator=(T&& other) noexcept {
        if (this != &other) {
            delete data;
            data = other.data;
            other.data = nullptr;
        }
        std::cout << "Move Assignment\n";
        return *this;
    }

    ~T() {
        delete data;
        std::cout << "Destructor\n";
    }
};

int main() {
    T a(10);
    T b = a;              // Copy Constructor
    T c;
    c = a;                // Copy Assignment
    T d = std::move(a);   // Move Constructor
    T e;
    e = std::move(b);     // Move Assignment
}
```

如果基类的析构函数是 deleted 或不可访问（如 private），那么派生类无法合成移动构造函数，移动构造函数会被隐式地定义为 deleted。

C++ 合成移动构造函数的前提之一是：基类的移动构造函数必须是可访问的且未被删除，且基类的析构函数必须是可访问的（即不是 private/deleted）。

这是因为在合成派生类的移动构造函数时，它必须调用：

- `Base(Base&&)`（移动构造基类）
- `~Base()`（将来销毁时也需要访问）

如果这些函数**不可访问或被删除**，那派生类也**无法移动构造**，因为它没法移动或销毁那部分基类。

### 初始化类型

#### 按语义分类

| 初始化方式         | 说明                                                         | 示例                           |
| ------------------ | ------------------------------------------------------------ | ------------------------------ |
| **默认初始化**     | 用于未显式初始化的变量（类成员或局部变量），是否被初始化取决于类型和上下文 | `int x;` `MyClass obj;`        |
| **值初始化**       | 初始化为“零”或调用默认构造函数，常用于 `T obj{};` 或 `T obj = T();` | `int x{};` `T obj = T();`      |
| **拷贝初始化**     | 使用 `=` 语法进行初始化，允许调用拷贝构造函数或进行隐式类型转换 | `T obj = other;`               |
| **直接初始化**     | 使用括号语法初始化，优先匹配构造函数                         | `T obj(arg);`                  |
| **列表初始化**     | 使用花括号 `{}`，分为“直接列表初始化”和“拷贝列表初始化”      | `T obj{arg};` `T obj = {arg};` |
| **聚合初始化**     | 针对聚合类型，按成员顺序使用 `{}` 初始化，无需构造函数       | `Point p = {1, 2};`            |
| **零初始化**       | 所有字节置为 0，仅适用于静态存储对象或作为值初始化的子步骤   | `static int x;`                |
| **引用绑定初始化** | 初始化引用，可能涉及临时对象绑定                             | `const T& ref = value;`        |

#### 按语法分类

| 写法                   | 所属初始化类型（可能）                   |
| ---------------------- | ---------------------------------------- |
| `T obj;`               | 默认初始化（局部变量）或零初始化（静态） |
| `T obj = value;`       | 拷贝初始化                               |
| `T obj(value);`        | 直接初始化                               |
| `T obj{};`             | 值初始化 / 直接列表初始化                |
| `T obj = {};`          | 值初始化 / 拷贝列表初始化                |
| `T obj = T();`         | 值初始化（经典 idiom）                   |
| `T obj = {a, b};`      | 拷贝列表初始化                           |
| `T obj{a, b};`         | 直接列表初始化                           |
| `T arr[] = {1, 2, 3};` | 聚合初始化（数组）                       |
| `MyStruct s = {1, 2};` | 聚合初始化（聚合类）                     |

#### 实用对比

| 关键点                       | 直接初始化 (`T obj(arg)`) | 拷贝初始化 (`T obj = arg`) | 列表初始化 (`{}`)                 |
| ---------------------------- | ------------------------- | -------------------------- | --------------------------------- |
| 是否调用构造函数             | 是                        | 是                         | 是（更严格）                      |
| 是否支持隐式转换             | 是                        | 是                         | 视情况而定                        |
| 是否允许 narrowing           | 是                        | 是                         | 否，会报错（如 `{3.14}` → `int`） |
| 是否支持 `explicit` 构造函数 | 是                        | 否                         | 直接 `{}` 可以，`=` 不行          |

```cpp
struct A {
    A(int) {}             // 普通构造函数
    explicit A(double) {} // 显式构造函数
};

A a1 = 1;      // 拷贝初始化，调用 A(int)，隐式转换允许
A a2(1);       // 直接初始化，调用 A(int)
A a3 = 1.5;    // 拷贝初始化，尝试调用 A(double)，失败：explicit 构造函数不可用于拷贝初始化
A a4(1.5);     // 直接初始化，调用 explicit A(double)

A a5 = {1};    // 拷贝列表初始化，explicit 构造函数不可用
A a6{1};       // 直接列表初始化，explicit 构造函数可用
```

### 拷贝初始化

#### 拷贝初始化的语法形式

```cpp
T obj = expr;
```

- `T` 是目标对象类型
- `expr` 是用于初始化的表达式，可以是 `T` 类型的对象、其他类型的值、临时对象等

#### 拷贝初始化的工作机制

- 编译器会尝试使用 `expr` 通过隐式转换生成一个类型为 `T` 的临时对象（或直接就是 `T` 类型对象）
- 然后用这个临时对象调用 `T` 的拷贝构造函数（或移动构造函数）来初始化 `obj`
- 编译器允许通过隐式类型转换构造 `T` 对象，所以 `expr` 不必是 `T` 类型
- 现代编译器通常会进行**复制省略**（Copy Elision），优化掉临时对象，直接初始化 `obj`，避免调用拷贝构造

#### 拷贝初始化与直接初始化的区别

| 初始化方式 | 语法示例        | 是否允许调用 `explicit` 构造函数 | 是否调用拷贝构造函数                 |
| ---------- | --------------- | -------------------------------- | ------------------------------------ |
| 拷贝初始化 | `T obj = expr;` | 不允许                           | 通常会调用，但可能被省略             |
| 直接初始化 | `T obj(expr);`  | 允许                             | 不调用拷贝构造，直接调用对应构造函数 |
| 列表初始化 | `T obj{expr};`  | 允许                             | 不调用拷贝构造，调用对应构造函数     |

- **`T(...)` / `T{...}` / `T = ...` / `T = {...}` 都是调用普通构造函数（或转换构造函数），不是拷贝构造。**
- **只有用已有对象初始化新对象（`T t2 = t1;`）时，才会真正调用拷贝构造。**

#### 拷贝初始化发生的时机

- 使用 `=` 定义变量
- 将一个对象作为实参传递给一个非引用类型的形参
- 从一个返回类型为非引用类型的函数返回一个对象
- 用花括号列表初始化一个数组中的元素或一个聚合类中的成员，也是拷贝初始化

#### 拷贝初始化为啥不能用 explict?

- 本质原因：为了防止意外调用显式构造函数。
- `explicit` 的含义本身就是“**不允许隐式调用**”。而拷贝初始化（`T obj = arg;`）**是隐式初始化语法**。
- `直接初始化` 和 `直接列表初始化` 是“显式语法”，允许调用 `explicit` 构造函数。

#### 拷贝初始化一定会调用拷贝构造函数吗？

虽然**名字叫“拷贝初始化”**，但**“拷贝初始化”并不总是调用拷贝构造函数**，它只是语法形式为 `T obj = something;` 的一种初始化方式，**实际调用什么构造函数、是否优化构造，全看上下文**。

可能的实际行为

| 场景                                      | 是否调用拷贝构造函数 | 说明                                                         |
| ----------------------------------------- | -------------------- | ------------------------------------------------------------ |
| `T obj = otherT;`（`otherT` 是 `T` 类型） | **是**               | 典型的拷贝构造场景，调用 `T(const T&)`                       |
| `T obj = value;`（`value` 是其他类型）    | **否**               | 会寻找匹配的转换构造函数 `T::T(U)`，若 `explicit` 则需显式调用 |
| `T obj = T(123);`                         | **否（常优化掉）**   | 理论上会产生临时对象再拷贝，但编译器通常应用**复制省略（RVO）** |
| `T obj = funcReturningT();`               | **否（常优化掉）**   | 返回临时对象，若开启 **RVO/NRVO**，拷贝构造会被省略          |
| `T obj = {123};`（列表初始化）            | **否**               | 属于**拷贝列表初始化**，直接调用合适的构造函数，不经过拷贝构造 |

只有**用已有同类型对象初始化新对象**（`T obj = otherT;`）时，才会真正调用拷贝构造。其余情况要么调用转换构造，要么直接优化掉拷贝，要么走列表初始化路径。

### 交换操作

#### swap 函数应该调用 swap，而不是 std::swap

```cpp
#include <iostream>
#include <string>
#include <utility> // for std::swap

// 自定义类 HasPtr
class HasPtr {
    // 声明 swap 为友元函数，使其可以访问私有成员
    friend void swap(HasPtr&, HasPtr&);
private:
    std::string *ps;
    int i;
};

// 自定义 swap(HasPtr&, HasPtr&)，用于高效交换 HasPtr 成员
inline void swap(HasPtr& lhs, HasPtr& rhs) {
    using std::swap;
    // 调用标准库 swap 交换指针和 int
    swap(lhs.ps, rhs.ps);
    swap(lhs.i, rhs.i);
}

// 包含 HasPtr 成员的类 Foo
class Foo {
public:
    HasPtr h;
};

// swap1: 强制使用 std::swap
void swap1(Foo &lhs, Foo &rhs) {
    // 这里直接写 std::swap，不允许 ADL 查找用户自定义 swap 函数
    // 最终会调用 std::swap(lhs, rhs)，即执行拷贝构造 + 析构（可能效率较低）
    std::swap(lhs, rhs);
}

// swap2: 推荐方式，支持 ADL 查找
void swap2(Foo &lhs, Foo &rhs) {
    using std::swap;
    // 此处 swap(lhs, rhs) 会触发 ADL：
    // 如果用户为 Foo 或其成员类型（如 HasPtr）定义了 swap，则优先使用这些版本
    // 否则才退回使用 std::swap
    swap(lhs, rhs);
}
```

- 推荐使用 swap2 的写法，因为它支持 `ADL`，可以调用用户为 Foo 或其成员提供的自定义 swap 函数
- 不推荐 swap1 的写法，在有自定义 swap 的类中会丢失优化机会
- `ADL` 全称是 **Argument-Dependent Lookup**，中文常叫 **实参依赖查找**。这是 C++ 的一个名字查找规则，用来决定调用函数时 **额外查找哪些命名空间/类作用域**。

#### 拷贝并交换

```cpp
#include <iostream>

class HasPtr {
public:
    HasPtr &operator=(HasPtr);

    friend void swap(HasPtr &, HasPtr &);

private:
    std::string *ps;
    int i;
};

inline void swap(HasPtr &lhs, HasPtr &rhs) {
    using std::swap;
    swap(lhs.ps, rhs.ps); // 交换指针
    swap(lhs.i, rhs.i);   // 交换值
}

HasPtr &HasPtr::operator=(HasPtr rhs) {
    swap(*this, rhs);
    return *this;
}
```

假设有：

```cpp
HasPtr a;
HasPtr b;
a = b;  // 会发生什么？
```

流程如下：

1. `b` 被值传递为参数 `rhs`，调用拷贝构造函数生成临时副本 `rhs`。
2. `swap(*this, rhs)`：即交换 `a` 和 `rhs` 的资源。
3. `rhs` 被销毁，原本 `a` 的旧资源被释放。
4. `a` 拥有了 `b` 的内容（副本）。

##### 核心思路

- **参数按值传递**：调用这个函数时，会自动对传入参数 `rhs` 调用一次**拷贝构造函数**（产生一个副本 `rhs`）。
- **交换资源**：使用 `swap(*this, rhs)`，交换当前对象的资源和副本对象的资源。
- **结束后 rhs 离开作用域，被析构**，它原本持有的（旧的）资源会被自动释放。

这样，对象 `*this` 拥有了新内容，旧内容随着 `rhs` 的销毁而安全释放。

##### 为什么这样写？

- 异常安全

  - 任何异常都发生在拷贝阶段（参数传进来前就已经拷贝好了），

  - 如果失败，原对象不变，保证**强异常安全保证**（Strong Exception Guarantee）。

- 代码复用
  - 只需要定义一个 `swap` 和拷贝构造函数，就能实现安全的赋值逻辑，无需重复资源释放和分配代码。

- 自给自足，简洁优雅

  - 避免手动检查自赋值 `if (this != &rhs)`。

  - 避免资源泄露和中间状态出错。

  - 使用标准的 `swap` 机制管理所有资源交接。

#### 对比传统写法

传统写法：手动释放并复制资源

```cpp
HasPtr& HasPtr::operator=(const HasPtr& rhs) {
    if (this != &rhs) {                // 处理自赋值
        delete ps;                     // 释放原资源
        ps = new std::string(*rhs.ps); // 分配新资源
        i = rhs.i;                     // 拷贝数据成员
    }
    return *this;
}
```

- **冗长**：需要显式编写资源的释放与重新分配逻辑，代码啰嗦。

- **容易出错**：如果忘记写 `if (this != &rhs)` 这样的自赋值检测，很容易导致资源被提前释放，引发错误。
- **异常不安全**：在分配新资源时，`new` 一旦抛出异常，旧资源已经释放，程序会陷入不一致状态。
- **性能略优**：这种写法少了一次副本构造，比 copy-and-swap 略省一次拷贝，但安全性差。