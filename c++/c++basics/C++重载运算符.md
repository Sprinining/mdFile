## C++ 重载运算符

在 C++ 中，**重载运算符（Operator Overloading）**允许为自定义类型（类/结构体）定义运算符的行为，从而使对象像内建类型一样参与运算操作。常用于提升代码可读性和可维护性。

### 基本语法

运算符重载的函数格式如下：

```cpp
返回类型 operator运算符(参数列表) {
    // 实现
}
```

它可以是**成员函数**，也可以是**友元函数**或**普通函数**（特别是当左操作数不是当前类对象时）。

### 常见示例

#### 1. **重载加号 `+`（成员函数）**

```cpp
class Point {
public:
    int x, y;

    Point(int x, int y) : x(x), y(y) {}

    Point operator+(const Point& other) const {
        return Point(x + other.x, y + other.y);
    }
};
```

#### 2. **重载等于号 `==`**

```cpp
bool operator==(const Point& other) const {
    return x == other.x && y == other.y;
}
```

#### 3. **重载输入输出运算符 `<<` 和 `>>`（友元函数）**

```cpp
#include <iostream>

class Point {
public:
    int x, y;

    Point(int x = 0, int y = 0) : x(x), y(y) {}

    // 输出运算符重载
    friend std::ostream& operator<<(std::ostream& os, const Point& p);

    // 输入运算符重载
    friend std::istream& operator>>(std::istream& is, Point& p);
};

// 输出格式： (x, y)
std::ostream& operator<<(std::ostream& os, const Point& p) {
    os << "(" << p.x << ", " << p.y << ")";
    return os;
}

// 输入格式：两个整数，自动赋值给 x 和 y
std::istream& operator>>(std::istream& is, Point& p) {
    if (!(is >> p.x >> p.y)) {
        std::cerr << "[输入错误] 请输入两个整数！" << std::endl;
        // 设置输入流为错误状态
        is.setstate(std::ios::failbit);
    }
    return is;
}

int main() {
    Point p;

    std::cout << "请输入一个点的坐标（格式：x y）: ";
    if (std::cin >> p) {
        std::cout << "你输入的点是: " << p << std::endl;
    } else {
        std::cerr << "输入失败，无法解析坐标。" << std::endl;
    }

    return 0;
}
```

- `<<` 和 `>>`（输入输出运算符）在 C++ 中**几乎总是作为非成员函数（通常是友元函数）来重载**。
- 运算符重载应该关注数据的“表示”，而不是格式的“配置”。格式应该交给用户来控制。不应该打印换行符。
- 重载输入运算符应该包含**输入合法性判断**。

#### 4. 重载前置后置的自增运算符

```cpp
#include <iostream>
using namespace std;

class Counter {
    int value;
public:
    Counter(int v = 0) : value(v) {}

    // 前置 ++，返回修改后的对象的引用
    Counter& operator++() {
        ++value;      // 先自增
        return *this;
    }

    // 后置 ++，参数为 int，区分前置和后置
    Counter operator++(int) {
        Counter temp = *this; // 记录自增前的值
        ++value;              // 自增
        return temp;          // 返回自增前的值（值拷贝）
    }

    int getValue() const { return value; }
};

int main() {
    Counter c(5);

    cout << "初始值: " << c.getValue() << "\n";

    ++c;  // 调用前置++
    cout << "前置++后: " << c.getValue() << "\n";

    c++;  // 调用后置++
    cout << "后置++后: " << c.getValue() << "\n";

    return 0;
}
```

- **前置++**没有参数，返回`*this`的引用，表示修改自身后返回。
- **后置++**带一个`int`参数（只是为了区分），返回自增前的旧对象的拷贝。

#### 5. 重载函数调用运算符

###### 最简单的函数调用运算符

```cpp
#include <iostream>
using namespace std;

class Adder {
public:
    int operator()(int a, int b) {
        return a + b;
    }
};

int main() {
    Adder add;
    cout << add(3, 4) << endl;  // 输出 7
    return 0;
}
```

###### 用于 `std::sort` 的自定义排序函数对象

```cpp
#include <iostream>
#include <vector>
#include <algorithm>
using namespace std;

struct Descend {
    bool operator()(int a, int b) {
        return a > b;
    }
};

int main() {
    vector<int> nums = {1, 5, 3, 2, 4};
    sort(nums.begin(), nums.end(), Descend());

    for (int n : nums) cout << n << " ";  // 输出：5 4 3 2 1
    return 0;
}
```

###### 捕获状态的函数对象（比函数指针强）

```cpp
#include <iostream>
using namespace std;

class MultiplyBy {
    int factor;
public:
    MultiplyBy(int f) : factor(f) {}
    int operator()(int x) const {
        return x * factor;
    }
};

int main() {
    MultiplyBy mul3(3);
    cout << mul3(10) << endl;  // 输出 30
    return 0;
}
```

###### 结合 `std::function` 和 Lambda（现代写法）

```cpp
#include <iostream>
#include <functional>
using namespace std;

int main() {
    function<int(int, int)> f = [](int a, int b) {
        return a * b;
    };

    cout << f(6, 7) << endl;  // 输出 42
    return 0;
}
```

### 可重载和不可重载的运算符

| 运算符类别       | 运算符符号                        | 是否可重载 | 建议重载   | 备注                               |
| ---------------- | --------------------------------- | ---------- | ---------- | ---------------------------------- |
| **算术运算符**   | `+`, `-`, `*`, `/`, `%`           | ✅ 可重载   | 推荐       | 常用且直观                         |
| **赋值运算符**   | `=`, `+=`, `-=`, `*=`, `/=`, `%=` | ✅ 可重载   | 推荐       | `=` 必须重载                       |
| **自增自减**     | `++`, `--`                        | ✅ 可重载   | 推荐       | 前置和后置均可                     |
| **关系运算符**   | `==`, `!=`, `<`, `>`, `<=`, `>=`  | ✅ 可重载   | 推荐       |                                    |
| **逻辑运算符**   | `&&`, `||`, `!`                   | ✅ 可重载   | 一般不建议 | 破坏短路求值，语义易混淆           |
| **位运算符**     | `&`, `|`, `^`, `~`, `<<`, `>>`    | ✅ 可重载   | 一般不建议 | 书上建议避免重载，避免语义混淆     |
| **成员访问**     | `->`                              | ✅ 可重载   | 视情况     | 常用于智能指针等                   |
| **下标访问**     | `[]`                              | ✅ 可重载   | 推荐       | 必须成员函数                       |
| **函数调用**     | `()`                              | ✅ 可重载   | 推荐       | 必须成员函数                       |
| **逗号运算符**   | `,`                               | ✅ 可重载   | 一般不建议 | 重载后改变求值顺序，易引起代码混淆 |
| **间接成员访问** | `.*`                              | ❌ 不可重载 | —          | C++ 标准禁止重载                   |
| **条件运算符**   | `?:`                              | ❌ 不可重载 | —          |                                    |
| **作用域解析**   | `::`                              | ❌ 不可重载 | —          |                                    |
| **成员访问**     | `.`                               | ❌ 不可重载 | —          |                                    |
| **大小写转换**   | `sizeof`, `typeid`, `alignof`     | ❌ 不可重载 | —          |                                    |

### 作为成员或者非成员

| 运算符                       | 通常作为成员函数         | 通常作为非成员函数（友元）  |
| ---------------------------- | ------------------------ | --------------------------- |
| `=`（赋值）                  | ✅ 必须成员               | ❌                           |
| `[]`（下标）                 | ✅ 必须成员               | ❌                           |
| `()`（函数调用）             | ✅ 必须成员               | ❌                           |
| `->`                         | ✅ 必须成员               | ❌                           |
| 一元运算符 `++ -- - * &`     | ✅ 推荐成员               | ❌（除非左操作数是内置类型） |
| 二元运算符 `+ - * / %`       | 可成员，也可非成员       | ✅ 非成员常用于对称运算      |
| 比较运算符 `== != < > <= >=` | ❌ 推荐非成员             | ✅ 非成员（通常为友元）      |
| 输入输出 `<< >>`             | ❌ 不能成员（左侧不是类） | ✅ 非成员（通常为友元）      |
| 赋值类运算符 `+= -= *=` 等   | ✅ 推荐成员               | ❌                           |

#### 判断标准

##### 是否必须是成员函数

有些运算符语法要求必须为成员函数：

1. `operator=`（赋值运算符）

```cpp
MyClass& operator=(const MyClass&);
```

- 因为赋值表达式 `a = b` 要**修改对象 `a` 的内部状态**。
- 语言规范要求：**赋值运算符左侧必须是对象本身（非 const）**，并且右侧的参数不能影响左侧对象的构造。
- 非成员函数没有权限直接访问并修改左侧对象（`a`）的内部状态。

2. `operator[]`（下标访问运算符）

```cpp
T& operator[](size_t i);
```

- 表达式 `a[i]` 会被编译器解释为 `a.operator[](i)`。
- **下标运算符的左侧必须是类对象**（即你定义的 `a`）才能调用这个函数。
- 如果写成非成员函数，就无法绑定 `a` 为 `this` 对象。
- 如果一个类包含下标运算符，则它通常会定义两个版本。分别是：

```cpp
T& operator[](size_t index);           // 非 const 版本，允许修改元素
const T& operator[](size_t index) const; // const 版本，保证只读访问
```

3. `operator()`（函数调用运算符）

```cpp
ReturnType operator()(参数列表);
```

- 表达式 `a(...)` 会被解释为 `a.operator()(...)`。
- 这意味着调用者 `a` 是函数对象，必须是类实例本身。
- 只有成员函数才能将 `a` 作为 `this` 指针调用。

##### 是否需要访问私有成员

如果写的运算符需要访问类的私有成员，**非成员函数需要加 friend**，否则无法访问。

##### 是否左右操作数都对称

**两个操作数的类型是否相同**，或者**是否具有互换性**（例如 `a + b` 和 `b + a` 是否都有意义）。这个特性会影响把运算符重载写成成员函数，还是非成员函数。

###### 对称操作数：类型相同或意义对等

```cpp
class Point {
public:
    int x, y;
    Point(int x, int y): x(x), y(y) {}

    Point operator+(const Point& other) const {
        return Point(x + other.x, y + other.y);
    }
};

int main() {
    Point a(1, 2), b(3, 4);
    Point c = a + b; // OK：a.operator+(b)
}
```

- 左右都是 `Point` 类型，**对称**；
- 所以你可以选择成员函数或非成员函数（都可以）；
- 甚至你还可以让用户写 `b + a`，没有语义冲突。

**结论**：操作数对称时，两边谁在前都没问题，**成员函数/非成员函数都可以**。

###### 非对称操作数：一边必须是类，一边是内置类型

```cpp
class Point {
public:
    int x;
    Point(int x): x(x) {}

    // 成员函数：支持 Point + int
    Point operator+(int val) const {
        return Point(x + val);
    }

    // 非成员函数：支持 int + Point
    friend Point operator+(int val, const Point& p) {
        return Point(val + p.x);
    }
};
```

```cpp
int main() {
    Point p(10);
    auto a = p + 5;  // ✅ 成员函数调用
    auto b = 5 + p;  // ✅ 友元函数调用
}
```

- `p + 5`：类对象在左，成员函数可以处理；
- `5 + p`：类对象在右，不能写成 `5.operator+(p)`，所以必须写成非成员函数。

**结论**：操作数非对称时（如 `int + Point`），要用 **非成员函数** 来支持类对象在右侧的情况。

###### 对称运算符的一个实际应用：比较运算符

```cpp
class Person {
public:
    int age;

    Person(int a): age(a) {}

    // friend 比较函数
    friend bool operator==(const Person& a, const Person& b) {
        return a.age == b.age;
    }

    friend bool operator<(const Person& a, const Person& b) {
        return a.age < b.age;
    }
};
```

这里的 `==` 和 `<`：

- 两边都是 `Person` 类型；
- 所以左右对称，完全可以写成非成员函数；
- 甚至推荐这样写，因为：
  - 语义自然；
  - 支持隐式类型转换；
  - 可支持 `std::sort`、`std::set` 等 STL 要求的比较。

##### 是否左操作数不是自定义类型

```cpp
std::ostream& operator<<(std::ostream&, const MyClass&); // ostream 是左侧，不能写成员函数
```

所以像 `<< >>` 的输入输出运算符只能是**非成员函数**。

#### 最佳实践建议

- 成员函数：用于 **修改自身或本身是主角的运算符**（如 `=`, `+=`, `[]`, `()`）。
- 非成员函数（通常配合 friend）：用于 **对称或左操作数不是类对象的运算符**（如 `+`, `==`, `<<`）。