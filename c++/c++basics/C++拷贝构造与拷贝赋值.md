##  C++ 拷贝构造与拷贝赋值

### 拷贝构造函数

在 C++ 中，**拷贝构造函数（Copy Constructor）** 是一种特殊的构造函数，用于使用一个已有对象来初始化一个新对象。它的典型声明形式如下：

```cpp
ClassName(const ClassName& other);
```

#### 示例

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

- **拷贝构造函数的第一个参数必须是“对自身类型的**`const`**引用”或“引用”**，不能是按值传递，否则会导致**无限递归调用（编译失败）**。

- 几乎所有正常使用场景下，拷贝构造函数的参数都是 `const T&`。
  - **支持 const 对象复制**： 如果不写 `const`，那 `MyClass obj2 = obj1;` 中如果 `obj1` 是 `const`，就不能调用 `MyClass(MyClass&)`。
  
    > ==C++ 引用匹配规则==
    >
    > - **`const T&` 可以绑定到**：
    >   - 非 `const` 左值对象
    >   - `const` 左值对象
    >   - 临时值（右值）
    > - **`T&`（非常量引用）只能绑定到**：
    >   - **非 `const` 左值对象**
    >   - **不能绑定 const 对象或临时对象**
  - **拷贝操作本质上不应修改源对象**： 加上 `const` 表示“拷贝源是只读的”，更安全、符合语义。
  - **和 STL、标准库兼容性更好**： 所有标准容器类、算法等内部实现都假设拷贝构造是 `const T&`。

#### 拷贝构造函数调用时机

- 用一个对象初始化另一个对象（拷贝初始化）：`Person p2 = p1;`

- 将对象按值传递给函数时。

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

- 从函数按值返回对象时。

```cpp
Person makePerson() {
    Person temp("Bob");
    return temp;  // 返回对象副本，会调用拷贝构造函数（或优化）
}

int main() {
    // 这个返回值会被拷贝到主函数中的变量 b
    Person b = makePerson();  // 这里也会调用拷贝构造函数（或优化）
}
```

#### 合成拷贝构造函数

在 C++ 中，**合成拷贝构造函数（synthesized copy constructor）**是指编译器自动为一个类生成的拷贝构造函数，用于在对象复制时拷贝成员变量。其形式通常如下：

```cpp
ClassName(const ClassName& other);
```

##### 合成拷贝构造函数的生成条件

编译器会**在没有用户自定义拷贝构造函数**的前提下，自动合成一个拷贝构造函数，前提是：

- 所有成员变量的拷贝构造函数也都是可访问的；
  - 成员的拷贝构造是 `private`
  - 成员的拷贝构造是 `protected`，当前类不是子类或友元 
  - 成员类禁止拷贝（被 `delete`）
  - 私有成员类的拷贝构造是 `private`，但当前类不是它的友元
- 没有被 `= delete` 的特殊成员函数影响（例如：移动构造被删除，可能会影响是否合成等）；

| 成员函数             | 写/删/自定义后影响                 |
| -------------------- | ---------------------------------- |
| 拷贝构造（const T&） | 手写后，编译器不再自动生成移动构造 |
| 移动构造（T&&）      | 手写后，编译器不再自动生成拷贝构造 |
| 删除移动构造         | 拷贝构造仍然可以合成（只要合法）   |
| 删除拷贝构造         | 移动构造仍然可以合成（只要合法）   |

- 类中没有继承或成员是不可复制的对象。

| 类型                            | 是否可复制 | 说明                     |
| ------------------------------- | ---------- | ------------------------ |
| `std::mutex`                    | ❌          | 明确删除了拷贝构造和赋值 |
| 自定义类 `A(const A&) = delete` | ❌          | 手动禁用复制             |
| 继承自不可复制基类              | ❌          | 基类拷贝构造被删除或私有 |
| 含有以上类为成员或基类          | ❌          | 传播不可复制性           |

##### 合成拷贝构造函数的行为

- 对所有**非静态成员变量**执行**逐个拷贝（member-wise copy）**；
- 如果有基类，也会调用**基类的拷贝构造函数**；

示例：

```cpp
struct A {
    int x;
};

struct B {
    A a;
    int y;
    // 编译器会自动生成：
    // B(const B& other) : a(other.a), y(other.y) {}
};

void test() {
    B b1 = { {42}, 7 };
    B b2 = b1;  // 调用合成拷贝构造函数
}
```

#### 与默认关键字 `= default` 的关系

可以显示告诉编译器合成一个：

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

- 合成拷贝构造函数是**浅拷贝**，对指针成员变量只拷贝地址，不复制指针所指内容；
- 对于资源管理类（比如类中有 `new` 分配的内存），需要自己定义拷贝构造函数以防止**资源泄漏或双重释放**；
- 在 C++11 之后，如果自定义了**移动构造函数或移动赋值函数**，但没有提供拷贝构造，拷贝构造函数可能不会被自动合成。

#### 默认拷贝构造函数

| 名称             | 定义方式             | 本质行为 | 区别点                   |
| ---------------- | -------------------- | -------- | ------------------------ |
| 合成拷贝构造函数 | 什么都不写           | 浅拷贝   | 编译器隐式生成           |
| 默认拷贝构造函数 | `= default` 明确指定 | 浅拷贝   | 程序员显式要求编译器合成 |

#### 自定义拷贝构造函数的典型用途

如果的类中包含**指针**或管理**动态资源（如内存、文件、网络句柄等）**，就应该自定义拷贝构造函数来实现**深拷贝（deep copy）**。

```cpp
class MyArray {
private:
    int* data;
    int size;

public:
    MyArray(int s) : size(s) {
        data = new int[size];
    }

    // 拷贝构造函数 - 深拷贝
    MyArray(const MyArray& other) : size(other.size) {
        data = new int[size];
        for (int i = 0; i < size; ++i)
            data[i] = other.data[i];
    }

    ~MyArray() {
        delete[] data;
    }
};
```

#### 如何避免拷贝构造开销

##### 引用传参

默认传参是「值传递」，会调用拷贝构造函数。但如果用「**引用**」来传递参数，就不会拷贝。

```cpp
class Person {
public:
    string name;
    Person(string n) : name(n) {}

    Person(const Person& other) {
        cout << "拷贝构造函数调用" << endl;
        name = other.name;
    }
};

void greet(const Person& p) {  // 使用 const 引用避免拷贝
    cout << "Hello " << p.name << endl;
}

int main() {
    Person a("Alice");
    greet(a);  // 不会调用拷贝构造函数
}
```

为什么加 `const`？

- 防止函数修改 `a`。
- 允许函数接收临时对象（如 `greet(Person("Temp"))`）。
  - C++ 为了安全性，只允许把临时对象绑定到 `const T&`。
  - 不允许绑定到 `T&（非常量引用）`，因为不能修改临时对象。

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

- 如果一个类型同时有**拷贝构造**和**移动构造**，当对象是**右值（临时对象、将亡值）\**时，编译器会优先调用\**移动构造函数**。

- 当对象是**左值**时，调用的还是**拷贝构造函数**。

- 如果没有定义移动构造函数，或者移动构造不可用（被删除或不可访问），才会调用拷贝构造函数。

移动构造 vs 拷贝构造

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

表示：将 `other` 的值赋给当前对象（`*this`），并返回对当前对象的引用。

#### 合成拷贝赋值运算符

如果用户没有显式定义赋值运算符，**编译器会自动合成一个**，前提是：

- 所有成员的拷贝赋值运算符也都是可访问的；
- 没有成员被 `=delete`；
- 没有某些限制（如成员是不可复制对象）；

合成形式：

```cpp
T& operator=(const T& other);
```

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

注意：

- 如果定义了 **移动赋值函数、析构函数、拷贝构造函数等**，其他特殊成员函数可能不会自动生成（遵循「Rule of Five」）
- 可以使用 `= default` 显式要求编译器生成：

```cpp
A& operator=(const A&) = default;
```

也可以禁止赋值：

```cpp
A& operator=(const A&) = delete;
```

#### 重载拷贝赋值运算符

可以重载拷贝赋值运算符以实现自定义的资源管理逻辑，例如深拷贝、日志打印、自管理内存等。

```cpp
class MyClass {
public:
    int* data;

    MyClass(int val = 0) {
        data = new int(val);
    }

    // 拷贝赋值运算符
    MyClass& operator=(const MyClass& other) {
        if (this != &other) {             // 处理自赋值
            delete data;                  // 清除旧资源
            data = new int(*other.data);  // 分配并拷贝新资源
        }
        return *this;
    }

    ~MyClass() {
        delete data;
    }
};
```

- 返回类型是 `T&`（允许链式赋值）
- 参数必须是 `const T&`
- 一定要检查 `this != &other`（防止自赋值破坏）

### 对比

#### 拷贝构造函数 VS 拷贝赋值运算符

| 特性             | 拷贝构造函数                           | 拷贝赋值运算符                               |
| ---------------- | -------------------------------------- | -------------------------------------------- |
| 目的             | **创建一个对象**，并用已有对象初始化它 | **将一个已有对象的值赋给另一个已存在的对象** |
| 典型签名         | `T(const T& other);`                   | `T& operator=(const T& other);`              |
| 返回值类型       | 无返回值                               | 返回 `T&`（支持链式赋值）                    |
| 调用时机         | 对象定义时： `T b = a;`                | 对象已存在后赋值： `b = a;`                  |
| 对象状态         | 用于**构造新对象**                     | 用于**更新已存在对象**                       |
| 可省略调用       | ✅ 是，可被优化掉（RVO/NRVO）           | ❌ 否，赋值行为不可省略                       |
| 是否可自动合成   | ✅ 是                                   | ✅ 是                                         |
| 是否会检查自赋值 | ❌ 一般不需处理                         | ✅ 推荐处理（`if (this != &other)`)           |

#### 拷贝构造函数 vs 拷贝赋值运算符 vs 移动构造函数 vs 移动赋值运算符

| 特性                    | 拷贝构造函数 `T(const T&)`  | 拷贝赋值运算符 `T& operator=(const T&)` | 移动构造函数 `T(T&&)`  | 移动赋值运算符 `T& operator=(T&&)`         |
| ----------------------- | --------------------------- | --------------------------------------- | ---------------------- | ------------------------------------------ |
| **目的**                | 用已有对象初始化新对象      | 将已有对象的值赋给已存在对象            | 用将亡对象初始化新对象 | 将将亡对象的值赋给已存在对象               |
| **参数类型**            | `const T&`（左值引用）      | `const T&`                              | `T&&`（右值引用）      | `T&&`                                      |
| **何时调用**            | 定义新对象时传入左值        | 已存在对象被赋值左值                    | 定义新对象时传入右值   | 已存在对象被赋值右值                       |
| **对象状态**            | 正在构造                    | 已构造                                  | 正在构造               | 已构造                                     |
| **是否涉及资源拷贝**    | ✅ 是（深/浅拷贝）           | ✅ 是                                    | ❌ 通常“掏走资源”       | ❌ 通常“掏走资源”                           |
| **是否有返回值**        | ❌ 无                        | ✅ 有（返回 `*this`）                    | ❌ 无                   | ✅ 有（返回 `*this`）                       |
| **典型用途**            | 复制传参、返回值优化失败时  | 覆盖已有对象（如 `a = b;`）             | 避免不必要的复制       | 优化临时对象赋值（如 `a = std::move(b);`） |
| **是否自动生成**        | ✅ 是（符合条件时）          | ✅ 是                                    | ✅ 是（符合条件时）     | ✅ 是（符合条件时）                         |
| **是否可删除/默认声明** | ✅ 支持 `=delete / =default` | ✅ 支持                                  | ✅ 支持                 | ✅ 支持                                     |
| **常用策略**            | Rule of 5                   | Rule of 5                               | Rule of 5              | Rule of 5                                  |

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

### 初始化类型

#### 按语义分类（标准定义的初始化类型）

| 初始化方式                             | 简介说明                                                     | 示例                          |
| -------------------------------------- | ------------------------------------------------------------ | ----------------------------- |
| **默认初始化**default-initialization   | 用于未显式初始化的变量（如类成员或局部变量），是否被初始化取决于类型和上下文 | `int x;``MyClass obj;`        |
| **值初始化**value-initialization       | 初始化为“零”或调用默认构造函数，常用于 `T obj{};` 或 `T obj = T();` | `int x{};``T obj = T();`      |
| **拷贝初始化**copy-initialization      | 使用 `=` 语法进行初始化，允许调用拷贝构造、隐式类型转换等    | `T obj = other;`              |
| **直接初始化**direct-initialization    | 使用括号语法初始化，优先匹配构造函数                         | `T obj(arg);`                 |
| **列表初始化**list-initialization      | 使用花括号 `{}`，可以分为“直接列表初始化”和“拷贝列表初始化”  | `T obj{arg};``T obj = {arg};` |
| **聚合初始化**aggregate-initialization | 针对聚合类型，按成员顺序使用 `{}` 初始化，无需构造函数       | `Point p = {1, 2};`           |
| **零初始化**zero-initialization        | 所有字节置为 0，仅适用于静态存储对象或 `value-init` 时被用作子步骤 | `static int x;`               |
| **引用绑定初始化**reference binding    | 初始化引用，可能涉及临时对象绑定                             | `const T& ref = value;`       |

#### 按语法分类（写法维度）

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

#### 实用对比重点

| 关键点                       | 直接初始化 (`T obj(arg)`) | 拷贝初始化 (`T obj = arg`) | 列表初始化 (`{}`)               |
| ---------------------------- | ------------------------- | -------------------------- | ------------------------------- |
| 是否调用构造函数             | ✅                         | ✅                          | ✅（更严格）                     |
| 是否支持隐式转换             | ✅                         | ✅                          | 视情况而定                      |
| 是否允许 narrowing           | ✅                         | ✅                          | ❌ 会报错（如 `{3.14}` → `int`） |
| 是否支持 `explicit` 构造函数 | ✅                         | ❌                          | 直接 `{}` 可以，`=` 不行        |

```cpp
struct A {
    A(int) {}
    explicit A(double) {}
};

A a1 = 1;      // 拷贝初始化，调用 A(int)
A a2(1);       // 直接初始化，调用 A(int)
A a3 = 1.5;    // 拷贝初始化，调用 A(double)，但不能用 explicit！
A a4(1.5);     // 直接初始化，explicit 构造函数可用

A a5 = {1};    // 拷贝列表初始化（不能用 explicit）
A a6{1};       // 直接列表初始化（可用 explicit）
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

#### 拷贝初始化发生的时机

- 使用 `=` 定义变量
- 将一个对象作为实参传递给一个非引用类型的形参
- 从一个返回类型为非引用类型的函数返回一个对象
- 用花括号列表初始化一个数组中的元素或一个聚合类中的成员，也是拷贝初始化

#### 拷贝初始化为啥不能用explict?

- 本质原因：为了防止意外调用显式构造函数。
- `explicit` 的含义本身就是“**不允许隐式调用**”。而拷贝初始化（`T obj = arg;`）**是隐式初始化语法**。
- `直接初始化` 和 `直接列表初始化` 是“显式语法”，允许调用 `explicit` 构造函数。

#### 拷贝初始化一定会调用拷贝构造函数吗？

虽然**名字叫“拷贝初始化”**，但 **“拷贝初始化”并不总是调用拷贝构造函数**，它只是语法形式为 `T obj = something;` 的一种初始化方式，**实际调用什么构造函数、是否优化构造，全看上下文**。

可能的实际行为（几个典型场景）

| 场景                                      | 是否调用拷贝构造函数   | 说明                                            |
| ----------------------------------------- | ---------------------- | ----------------------------------------------- |
| `T obj = otherT;`（`otherT` 是 `T` 类型） | ✅ 是，调用拷贝构造     | 最常见的拷贝构造使用场景                        |
| `T obj = value;`（`value` 是其他类型）    | ❌ 否，可能调用转换构造 | 会寻找 `T::T(U)` 形式的构造函数（可能隐式转换） |
| `T obj = T(123);`                         | ❌ 否，可能被优化       | 编译器常常应用 **复制省略（copy elision）**     |
| `T obj = funcReturningT();`               | ❌ 否，可能被优化       | 如果启用了 NRVO（返回值优化），拷贝构造会被省略 |
| `T obj = {123};`（列表初始化）            | ❌ 否，使用花括号构造   | 这是**拷贝列表初始化**，不调用拷贝构造          |

### 交换操作

#### `swap` 函数应该调用 `swap`，而不是 `std::swap`

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

// ✅ 推荐使用 swap2 的写法，因为它支持 ADL，可以调用用户为 Foo 或其成员提供的自定义 swap 函数
// ❌ 不推荐 swap1 的写法，在有自定义 swap 的类中会丢失优化机会
```

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

这个技巧的核心思路是：

1. **参数按值传递**：调用这个函数时，会自动对传入参数 `rhs` 调用一次**拷贝构造函数**（产生一个副本 `rhs`）。
2. **交换资源**：使用 `swap(*this, rhs)`，交换当前对象的资源和副本对象的资源。
3. **结束后 rhs 离开作用域，被析构**，它原本持有的（旧的）资源会被自动释放。

这样，对象 `*this` 拥有了新内容，旧内容随着 `rhs` 的销毁而安全释放。

为什么这样写？

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
    if (this != &rhs) {              // 处理自赋值
        delete ps;                   // 释放原资源
        ps = new std::string(*rhs.ps); // 分配新资源
        i = rhs.i;                   // 拷贝数据成员
    }
    return *this;
}
```

 特点：

| 问题点       | 说明                                             |
| ------------ | ------------------------------------------------ |
| ❌ 冗长       | 要显式写释放、分配逻辑                           |
| ❌ 容易出错   | 少写 `if (this != &rhs)` 就炸了                  |
| ❌ 异常不安全 | `new` 抛异常后，原资源已释放，程序处于不一致状态 |
| ✅ 性能略优   | 避免一次副本（copy-and-swap 多了一次构造）       |

| 对比项     | 传统写法                 | copy-and-swap                    |
| ---------- | ------------------------ | -------------------------------- |
| 代码简洁性 | ❌ 需要写释放、分配、拷贝 | ✅ 只需要一行 swap                |
| 异常安全   | ❌ 不安全，容易资源泄露   | ✅ 拷贝失败不影响原对象           |
| 自赋值处理 | ❌ 需要显式判断           | ✅ swap 不怕自赋值                |
| 可维护性   | ❌ 难维护                 | ✅ 高内聚低耦合                   |
| 依赖       | 无额外要求               | 需要定义 `swap`                  |
| 性能       | ✅ 少一次构造             | ❌ 多一次副本（但可由编译器优化） |