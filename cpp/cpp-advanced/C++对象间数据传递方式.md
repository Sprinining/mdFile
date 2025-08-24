## C++ 对象间数据传递方式

### 暴露公有成员变量

让接收端将数据成员设置为 `public`，源端直接访问或修改这些成员：

```cpp
class Receiver {
public:
    int data;  // 公有成员变量
};

Receiver r;
r.data = 42;  // 源端直接修改
```

- **特点**：源端可以直接访问和修改接收端的成员变量。
- **优点**：语法最简单、无需封装接口、性能最好。
- **缺点**：破坏封装性，易造成数据不一致或滥用，几乎不适用于正式工程。

> **适用场景**：临时结构体、简单 POD 类型、测试代码或性能极端敏感的代码段（但即使如此，也建议使用 `struct` 明确意图）。

### 值传递

```cpp
void processData(MyClass obj); // 传入的是对象的副本
```

- **特点**：调用函数时会拷贝整个对象，开销较大（尤其是对象复杂时）。

- **优点**：安全，函数内修改不影响原对象。

- **缺点**：性能开销大，不适合大对象。

### 引用传递

```cpp
void processData(MyClass& obj);       // 非 const 引用，可修改传入对象
void processData(const MyClass& obj); // const 引用，只读，不可修改
```

- **特点**：不会拷贝对象，传递的是对象的引用（别名）。
- **优点**：高效，避免拷贝开销。引用保证必定有对象，不为空。
- **缺点**：如果是非 const 引用，函数可以修改对象内容，需注意。

### 指针传递

```cpp
void processData(MyClass* obj);
```

- **特点**：传递的是对象的地址，可以为 `nullptr`。
- **优点**：显式指示可能为空，函数内部需要检查指针有效性。
- **缺点**：使用不当可能导致空指针访问或悬空指针。

### 移动语义（C++11 及以后）

```cpp
void processData(MyClass&& obj); // 右值引用，接收将要销毁的对象
```

- **特点**：将对象的资源“搬走”，减少拷贝开销。
- **优点**：高效，适合临时对象或转移所有权场景。
- **缺点**：调用方需明确使用 `std::move`。

#### 什么是移动语义

**移动语义**允许程序“移动”资源的所有权，而不是复制资源本身。它通过引入“右值引用”（rvalue reference）实现，右值引用可以绑定到临时对象，表示该对象的资源可以被“偷走”。

#### 右值引用

```cpp
T&&  // T 是类型，&& 表示右值引用
```

- 普通引用 `T&` 绑定到左值（有名字的变量）

- 右值引用 `T&&` 绑定到右值（临时变量、即将销毁的对象）

#### 移动构造函数和移动赋值运算符

如果定义了类，有指针成员等动态资源，建议自定义：

- 移动构造函数：`MyClass(MyClass&& other);`
- 移动赋值运算符：`MyClass& operator=(MyClass&& other);`

它们从 `other` 对象“接管”资源后，将 `other` 的资源指针置空，避免析构时重复释放。

```cpp
#include <iostream>
#include <cstring>

class String {
private:
    char* data;
public:
    // 构造函数
    String(const char* s = "") {
        std::cout << "Constructing\n";
        data = new char[strlen(s) + 1];
        strcpy(data, s);
    }

    // 拷贝构造函数
    String(const String& other) {
        std::cout << "Copy Constructing\n";
        data = new char[strlen(other.data) + 1];
        strcpy(data, other.data);
    }

    // 移动构造函数
    String(String&& other) noexcept {
        std::cout << "Move Constructing\n";
        data = other.data;      // 直接接管指针
        other.data = nullptr;   // 将原对象置空，防止释放
    }

    // 析构函数
    ~String() {
        std::cout << "Destructing\n";
        delete[] data;
    }

    void print() const {
        if (data) std::cout << data << std::endl;
        else std::cout << "(null)" << std::endl;
    }
};

String createString() {
    String temp("Hello Move");
    return temp;  // 返回临时对象，触发移动构造
}

int main() {
    String s1 = createString();  // 使用移动构造函数
    s1.print();

    String s2("World");
    s2 = createString();         // 这里移动赋值需要自己实现，示例省略
    s2.print();

    return 0;
}
```

- `createString()` 返回一个临时对象 `temp`，它是右值，调用时优先使用移动构造函数。

- 移动构造函数将 `temp` 的内部指针直接“偷走”，避免拷贝字符串内容，提高性能。

- 运行时会看到“Move Constructing”字样，证明移动语义生效。

#### 两种构造函数触发条件

| 触发条件                 | 调用函数     | 说明                         |
| ------------------------ | ------------ | ---------------------------- |
| 用左值初始化新对象       | 拷贝构造函数 | 复制已有对象                 |
| 用右值初始化新对象       | 移动构造函数 | 资源转移，避免复制           |
| 函数参数传值（传入左值） | 拷贝构造函数 | 复制实参                     |
| 函数参数传值（传入右值） | 移动构造函数 | 移动实参资源                 |
| 显式调用 `std::move`     | 移动构造函数 | 强制将左值转换成右值调用移动 |

### 拷贝构造或赋值构造

两个对象间直接赋值或初始化：

```cpp
MyClass obj2 = obj1;  // 拷贝构造
obj2 = obj1;          // 拷贝赋值
```

- **特点**：生成新对象的副本。
- **优点**：语义清晰，数据安全隔离。
- **缺点**：拷贝成本高。

### 通过成员函数或接口方法传递

一个对象调用另一个对象的方法，传递数据：

```cpp
obj2.setData(obj1.getData());
```

- **特点**：通过接口控制数据访问和修改。
- **优点**：封装良好，灵活可控。
- **缺点**：依赖接口设计。

###  友元函数或友元类

当两个类需要紧密访问对方私有成员时：

```cpp
class MyClass {
    friend void processData(const MyClass& obj1, MyClass& obj2);
};
```

- **特点**：直接访问私有成员。
- **优点**：适合紧密耦合逻辑。
- **缺点**：破坏封装性，慎用。

### 序列化与反序列化

将对象数据序列化成中间格式（如 JSON、二进制流），再由另一个对象解析处理。

- **适合场景**：跨进程、跨机器通信，持久化存储等。

### 回调函数

- **源端**（调用方）定义一套回调函数约定（函数签名，包括参数和返回值类型）。

- **接收端**实现符合该签名的函数，通常是静态成员函数（也可以是普通函数、函数对象、lambda 等）。

- 将该静态成员函数的函数指针传递给源端，源端通过这个指针回调调用接收端的处理逻辑。

- 源端和接收端松耦合，通过函数指针或函数对象实现灵活的通信。

```cpp
#include <iostream>

// 源端接口，接收回调函数
class Source {
public:
    using Callback = int(*)(int, int);

    void setCallback(Callback cb) {
        callback = cb;
    }

    void doWork() {
        if (callback) {
            int result = callback(2, 3);  // 调用回调函数
            std::cout << "Callback result: " << result << std::endl;
        }
    }

private:
    Callback callback = nullptr;
};

// 接收端
class Receiver {
public:
    // 符合回调签名的静态成员函数
    static int callbackFunc(int a, int b) {
        std::cout << "Receiver::callbackFunc called with " << a << " and " << b << std::endl;
        return a + b;
    }
};

int main() {
    Source src;
    src.setCallback(&Receiver::callbackFunc);  // 传入回调函数指针
    src.doWork();  // 调用回调函数

    return 0;
}
```

#### 特点与优点

- **灵活**，可以替换不同的回调函数实现不同的处理逻辑。
- **松耦合**，源端不依赖于接收端的具体类型，只依赖函数签名。
- **适用于事件驱动、异步任务、插件式架构**。
- 静态成员函数可作为普通函数指针传递，不带隐式的 `this` 指针，调用简单。

#### 需要注意

- 静态成员函数不能访问非静态成员变量和函数，如果需要访问，通常会传入指向对象的指针作为参数。
- 如果要绑定非静态成员函数，需使用 `std::function` 和 `std::bind`，或者现代 C++ 的 lambda 表达式。
- 回调函数参数和返回值类型必须严格匹配，否则会导致调用错误。
