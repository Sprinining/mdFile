## C++ 三五法则

### Rule of Three（三法则）

如果一个类需要自己定义以下 **三个特殊成员函数** 中的任何一个，则通常**也应该定义另外两个**：

- **拷贝构造函数** `ClassName(const ClassName&);`
- **拷贝赋值运算符** `ClassName& operator=(const ClassName&);`
- **析构函数** `~ClassName();`

因为：

- 类里有动态分配资源（如裸指针）；
- 编译器默认的拷贝构造和拷贝赋值都是浅拷贝，只复制指针，造成多个对象共享同一资源，可能出现资源重复释放、悬空指针；
- 析构函数负责释放资源，所以必须协调三者正确处理资源管理。

#### 反例：内存泄漏

```cpp
#include <iostream>
using namespace std;

class HasPtr {
public:
    // 构造函数，分配新字符串，深拷贝参数字符串
    HasPtr(const std::string &s = std::string()) : ps(new std::string(s)), i(0) {
    }

    // 析构函数，这里空实现，没有释放 ps 指向的内存
    ~HasPtr() {}

    std::string *ps;  // 指向堆上字符串的裸指针
    int i;
};

int main() {
    HasPtr p1("hello");   // p1拥有自己的字符串，ps指向堆上的"hello"
    {
        HasPtr p2 = p1;   // 调用合成拷贝构造函数，浅拷贝指针ps
                          // p2.ps 和 p1.ps 指向同一块字符串内存
    }                    // p2销毁，析构函数为空，不释放内存
                          // 因此内存依旧有效，没有释放

    // p1.ps 指向有效内存，访问安全
    cout << *(p1.ps) << endl;  // 输出 "hello"
}
```

- 虽然 `HasPtr` 有裸指针成员 `ps`，但析构函数没有释放指针指向的内存，造成内存泄漏；
- 拷贝构造函数是编译器合成的浅拷贝，`p1` 和 `p2` 共享同一块字符串内存；
- `p2` 对象销毁时没有释放内存，`p1.ps` 仍有效；
- 但程序会泄漏分配的字符串内存，不符合资源管理原则。

#### 反例：悬空指针

```cpp
#include <iostream>
using namespace std;

class HasPtr {
public:
    // 构造函数，申请新字符串内存，深拷贝传入的字符串
    HasPtr(const std::string &s = std::string()) : ps(new std::string(s)), i(0) {
    }

    // 析构函数，释放指针指向的内存
    ~HasPtr() { delete ps; }

    std::string *ps;  // 指向堆上字符串的指针
    int i;            // 普通整型成员
};

int main() {
    HasPtr p1("hello");  // p1持有自己独立的字符串"hello"
    {
        HasPtr p2 = p1;  // 调用合成的拷贝构造函数（浅拷贝）
                          // p2.ps 指针和 p1.ps 指向同一块内存
    }                    // p2对象销毁，析构函数调用 delete ps，释放内存

    // p1.ps 指针变为悬空指针，指向已被释放的内存
    // 访问 *(p1.ps) 会产生未定义行为（可能崩溃或打印乱码）
    cout << *(p1.ps) << endl;
}
```

- 合成拷贝构造函数只是浅拷贝指针 `ps`，没有重新分配内存；
- `p2` 析构时释放了指针指向的内存，`p1.ps` 成为悬空指针；
- 后续访问 `p1.ps` 导致未定义行为。

#### 正例

```cpp
#include <iostream>
using namespace std;

class HasPtr {
public:
    HasPtr(const std::string &s = std::string())
        : ps(new std::string(s)), i(0) {}

    // 拷贝构造函数：实现深拷贝，分配新内存
    HasPtr(const HasPtr& other)
        : ps(new std::string(*other.ps)), i(other.i) {}

    // 拷贝赋值运算符：先防止自赋值，释放旧内存，深拷贝新值
    HasPtr& operator=(const HasPtr& other) {
        if (this != &other) {
            delete ps;  // 释放原内存
            ps = new std::string(*other.ps);  // 分配新内存深拷贝
            i = other.i;
        }
        return *this;
    }

    // 析构函数，释放内存
    ~HasPtr() {
        delete ps;
    }

    std::string *ps;
    int i;
};

int main() {
    HasPtr p1("hello");
    {
        HasPtr p2 = p1;  // 调用拷贝构造，深拷贝
    }  // p2析构，释放自己独立的内存，p1内存不受影响
    cout << *(p1.ps) << endl;  // 安全输出 "hello"

    HasPtr p3("world");
    p3 = p1;  // 这里调用了拷贝赋值运算符，p3先释放原内存，再深拷贝p1的数据
    cout << *(p3.ps) << endl;  // 输出 "hello"，p3内容已被p1覆盖
}
```

### Rule of Five（五法则）

C++11 引入了移动语义后，三法则扩展为五法则：

除了以上三种，还要定义：

- **移动构造函数** `ClassName(ClassName&&);`
- **移动赋值运算符** `ClassName& operator=(ClassName&&);`

因为：

- 移动语义允许资源从临时对象“偷取”过来，而不做深拷贝，性能大幅提升；
- 如果需要管理资源，且实现了拷贝操作，一般也需要定义移动操作，避免编译器自动生成的移动函数失效或错误。

#### 示例

```cpp
#include <iostream>
using namespace std;

class HasPtr {
public:
    // 构造函数，申请新字符串内存，深拷贝传入的字符串
    HasPtr(const std::string &s = std::string())
        : ps(new std::string(s)), i(0) {}

    // 拷贝构造函数：深拷贝，分配新内存
    HasPtr(const HasPtr& other)
        : ps(new std::string(*other.ps)), i(other.i) {}

    // 拷贝赋值运算符：防止自赋值，释放旧内存，深拷贝新值
    HasPtr& operator=(const HasPtr& other) {
        if (this != &other) {
            delete ps;  // 释放旧内存
            ps = new std::string(*other.ps);  // 分配新内存深拷贝
            i = other.i;
        }
        return *this;
    }

    // 移动构造函数：接管资源，置空源指针，提升性能
    HasPtr(HasPtr&& other) noexcept
        : ps(other.ps), i(other.i) {
        other.ps = nullptr;  // 置空源，防止析构时释放资源
    }

    // 移动赋值运算符：释放当前资源，接管源资源，置空源指针
    HasPtr& operator=(HasPtr&& other) noexcept {
        if (this != &other) {
            delete ps;          // 释放旧资源
            ps = other.ps;      // 接管资源
            i = other.i;
            other.ps = nullptr; // 置空源，防止重复释放
        }
        return *this;
    }

    // 析构函数，释放内存，防止内存泄漏
    ~HasPtr() {
        delete ps;
    }

    std::string *ps;
    int i;
};

int main() {
    HasPtr p1("hello");

    {
        HasPtr p2 = p1;  // 拷贝构造，深拷贝
    }  // p2析构，释放自己独立内存，不影响p1
    cout << *(p1.ps) << endl;  // 输出 "hello"

    HasPtr p3("world");
    p3 = p1;  // 拷贝赋值，p3释放原内存，深拷贝p1数据
    cout << *(p3.ps) << endl;  // 输出 "hello"

    HasPtr p4 = std::move(p1);  // 移动构造，p4接管p1资源，p1.ps变nullptr
    // p1.ps已被置空，访问会导致异常，不要再用p1.ps

    HasPtr p5("temp");
    p5 = std::move(p3);  // 移动赋值，p5释放原内存，接管p3资源，p3.ps变nullptr

    // 输出 p4 和 p5 中的字符串，确认移动成功
    cout << (p4.ps ? *p4.ps : "p4.ps is null") << endl;  // 输出 "hello"
    cout << (p5.ps ? *p5.ps : "p5.ps is null") << endl;  // 输出 "hello"
}
```

### Rule of Zero（零法则）

- 如果**不直接管理资源**，而是使用 **智能指针**（如 `std::unique_ptr`）、标准容器等 RAII 类型成员，**则不需要自定义以上五个函数**。
- 让编译器自动生成的特殊成员函数就足够了，代码更简洁安全。

#### 示例

```cpp
#include <iostream>
#include <string>
using namespace std;

class HasPtr {
public:
    std::string s;  // 直接用 std::string 管理内存，public 成员
    int i;

    // 使用默认的构造、拷贝、赋值、析构即可，编译器自动生成
    HasPtr(const std::string& str = "") : s(str), i(0) {}
};

int main() {
    HasPtr p1("hello");
    HasPtr p2 = p1;  // 调用编译器合成的拷贝构造函数，深拷贝 std::string
    p2.s = "world";  // 修改 p2，不影响 p1

    cout << "p1.s = " << p1.s << endl;  // 输出 hello
    cout << "p2.s = " << p2.s << endl;  // 输出 world
}
```

- **没有使用裸指针自己管理内存**，而是用标准库里的 `std::string` 类型作为成员变量。
- `std::string` 内部已经封装了动态内存管理，它的构造、拷贝、赋值和析构都正确处理了底层的内存分配和释放。
- 当 `HasPtr` 对象销毁时，`std::string` 成员会自动调用自己的析构函数，释放分配的内存。
- 你没有写自定义的析构函数、拷贝构造函数或赋值操作符，编译器生成的默认版本会按成员逐一调用对应的构造/析构，保证所有资源正确管理。

### 总结

| 法则                   | 需要定义的函数                   | 适用场景                      | 说明                           |
| ---------------------- | -------------------------------- | ----------------------------- | ------------------------------ |
| 三法则 (Rule of Three) | 拷贝构造、拷贝赋值、析构         | C++98，管理裸指针资源         | 管理资源必须正确处理拷贝和释放 |
| 五法则 (Rule of Five)  | 三法则 + 移动构造、移动赋值      | C++11，引入移动语义，性能优化 | 支持移动避免不必要深拷贝       |
| 零法则 (Rule of Zero)  | 不自定义任何，使用智能指针或容器 | 推荐，现代C++写法             | 自动管理资源，简化代码更安全   |