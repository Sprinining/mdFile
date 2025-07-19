## C++ INT类重载实现及设计细节

《STL 源码剖析》1.9.4 节代码：

```cpp
#include <iostream>

using namespace std;

class INT {
    friend ostream& operator<<(ostream& os, const INT& i);
public:
    // 构造函数，初始化成员变量
    INT(int i) : i_(i) {}

    // 前置自增运算符 ++I
    INT& operator++() {
        ++(this->i_);    // 成员变量自增
        return *this;    // 返回当前对象的引用（允许连写 ++(++I)）
    }

    // 后置自增运算符 I++
    const INT operator++(int) {
        INT temp = *this;   // 复制当前对象，保存旧值
        ++(*this);          // 调用前置++，实现自增
        return temp;        // 返回旧值（值传递）
    }

    // 前置自减运算符 --I
    INT& operator--() {
        --(this->i_);
        return *this;
    }

    // 后置自减运算符 I--
    const INT operator--(int) {
        INT temp = *this;
        --(*this);
        return temp;
    }

    // 解引用运算符 *I
    int& operator*() const {
        // 虽然函数是 const，但这里用强制类型转换去掉 const 限制，
        // 让调用者通过 *I 可以修改 i_
        // 这样写编译器可能警告或报错，属于“破坏 const 语义”，不推荐
        return (int&)i_;
    }

private:
    int i_;   // 内部存储的整数值
};

// 重载 << 操作符，方便输出 INT 对象
ostream& operator<<(ostream& os, const INT& i) {
    os << '[' << i.i_ << ']';
    return os;
}

int main() {
    INT I(5);

    cout << I++;   // 输出原值 [5]，I 自增为 6
    cout << ++I;   // I 自增为 7，输出 [7]
    cout << I--;   // 输出原值 [7]，I 自减为 6
    cout << --I;   // I 自减为 5，输出 [5]
    cout << *I;    // 通过解引用操作符，输出 5
}
```

- **前置++/--** 返回的是对象自身的引用 `INT&`，支持链式操作，效率高。
- **后置++/--** 返回的是操作前的值，先保存临时对象再调用前置++/--。
  - `++(*this);` 和 `--(*this);` 递归调用前置成员函数，代码复用，避免重复实现。
  - 也可以换成 `++i_;` 和 `--i_;`。
- **`operator*() const` 返回 `int&` 并强制去除 const**，这是为了演示，但通常违背 const 语义，生产代码应避免。
  - 如果 `i_` 是 `const int`，而用 `(int&)i_`，就是强行去掉 `const`，**这是非常危险的**，可能导致未定义行为。
  - 如果 `i_` 不是 `const`，`return (int&)i_;` 和 `return i_;` 两者没区别，但写法二更简洁、符合规范。
- `friend ostream& operator<<` 方便打印，访问私有成员。

- 区分前置和后置版本

  - **前置自增运算符**声明为：

    ```cpp
    INT& operator++();  // 无参数，前置++
    ```

  - **后置自增运算符**声明为：

    ```cpp
    const INT operator++(int);  // 参数是 int 类型，占位参数，表示后置++
    ```

  - C++标准规定，后置++/--操作符要带一个 `int` 参数，但**调用时不传值**。

  - 这个参数只是用来“区分”函数签名的，**并不会使用到**。