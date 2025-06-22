## C++深拷贝浅拷贝

在 C++ 中，**深拷贝（deep copy）\**和\**浅拷贝（shallow copy）\**是对象复制时的两个重要概念，尤其在类中含有\**指针成员**时特别关键。

### 浅拷贝（Shallow Copy）

- 拷贝的是**指针的值**，也就是让两个对象**共享同一块内存**。

- 如果一个对象释放了内存，另一个对象指针就成了**悬垂指针**（野指针） -> 会出现**双重释放**或**崩溃问题**。

### 深拷贝（Deep Copy）

- 拷贝的是指针所指向的内容，即为新对象**重新分配内存并复制内容**，两个对象互不影响。

### 代码示例

```cpp
#include <iostream>
#include <cstring>
using namespace std;

class Person {
private:
    char* name;

public:
    // 构造函数
    Person(const char* n) {
        name = new char[strlen(n) + 1];
        strcpy(name, n);
    }

    // 浅拷贝（编译器默认生成的拷贝构造函数）会像这样：
    // Person(const Person& other) { this->name = other.name; }

    // ✅ 深拷贝构造函数
    Person(const Person& other) {
        name = new char[strlen(other.name) + 1];
        strcpy(name, other.name);
    }

    // 析构函数
    ~Person() {
        delete[] name;
    }

    void setName(const char* n) {
        strcpy(name, n);
    }

    void show() const {
        cout << "Name: " << name << endl;
    }
};
```

使用示例：

```cpp
int main() {
    Person p1("Alice");
    Person p2 = p1;  // 调用拷贝构造函数

    p2.setName("Bob");

    p1.show();  // Alice
    p2.show();  // Bob

    return 0;
}
```

如果没有手动实现深拷贝，而是使用默认的浅拷贝，上面会导致两个对象共用同一个 `name`，修改 `p2.name` 会影响 `p1.name`，并可能导致内存错误。

### 拷贝相关的三大函数（C++11称为 Rule of Three）

当类有**动态内存资源**时，建议自定义以下三个函数：

1. **拷贝构造函数**（拷贝时调用）
2. **赋值运算符重载函数**（`operator=`）
3. **析构函数**

```cpp
// 示例：赋值运算符的深拷贝
Person& operator=(const Person& other) {
    if (this != &other) {  // 防止自赋值
        delete[] name;
        name = new char[strlen(other.name) + 1];
        strcpy(name, other.name);
    }
    return *this;
}
```

### C++11 之后建议使用 Rule of Five / Rule of Zero

如果还使用**移动语义（move constructor/operator）**，就变成了 Rule of Five。

但在现代 C++ 中，更推荐使用智能指针（如 `std::unique_ptr`、`std::shared_ptr`）来自动管理资源，减少手动拷贝的风险 —— 这就是 **Rule of Zero**（零资源管理）。