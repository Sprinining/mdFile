## C++ 可调用对象与 function

### 可调用对象

在 C++ 中，**可调用对象（Callable Object）\**是指\**可以像函数一样使用圆括号 `()` 进行调用**的对象。C++ 支持多种形式的可调用对象，不只是普通函数。

#### 什么是可调用对象

可调用对象是指可以使用以下语法调用的任何对象：

```cpp
obj(args...);  // ← 这就是“可调用”
```

例如：

- `func(1, 2);`：`func` 是一个可调用对象；
- `lambda(3);`：lambda 是可调用对象；
- `FunctionObject()`：重载了 `operator()` 的对象。

#### C++ 中的可调用对象类型分类

| 类型                         | 示例说明                      |
| ---------------------------- | ----------------------------- |
| ① 函数指针                   | `int (*f)(int)`               |
| ② 普通函数                   | `int add(int a, int b)`       |
| ③ Lambda 表达式              | `[](int x) { return x + 1; }` |
| ④ 函数对象（仿函数）         | 自定义类重载 `operator()`     |
| ⑤ 成员函数指针               | `&MyClass::memberFunction`    |
| ⑥ `std::function` 对象       | `std::function<int(int)>`     |
| ⑦ `std::bind` 生成的绑定对象 | `std::bind(add, 2, _1)`       |

#### 示例演示各种可调用对象

```cpp
#include <iostream>
#include <functional>     // std::function, std::bind, std::invoke
#include <string>
#include <cmath>          // std::pow
using namespace std;

// 通用可调用对象打印器模板函数：
// 调用任意可调用对象 f，传入任意数量的参数 args，
// 并打印调用结果，前面带上名称 name 作为标识。
//
// 模板参数说明：
// - Callable：任意可调用对象类型，如函数指针、lambda、仿函数、成员函数指针等
// - Args...：参数包，表示传递给 Callable 的任意参数列表
//
// 参数说明：
// - name：用于输出时标识调用的名称（例如函数名）
// - f：待调用的可调用对象，使用万能引用（完美转发）保证传参效率和语义正确
// - args...：调用 f 所需的参数，同样完美转发
template<typename Callable, typename... Args>
void callWithPrint(const string& name, Callable&& f, Args&&... args) {
    // std::invoke 是 C++17 新增的统一调用接口，
    // 能自动识别和调用多种可调用对象，包括：
    // - 普通函数和函数指针
    // - lambda 表达式
    // - 成员函数指针（需传入对象实例）
    // - 仿函数（重载了 operator() 的类实例）
    // - std::function 等类型
    //
    // std::forward 用于完美转发参数，保留实参的左值或右值属性，
    // 防止拷贝或类型转换错误，提高效率。
    //
    // 通过这句代码，可以透明地调用任意形式的函数对象，
    // 并输出调用结果。
    cout << name << ": " << std::invoke(std::forward<Callable>(f), std::forward<Args>(args)...) << endl;
}

// ① 函数指针
int add(int a, int b) {
    return a + b;
}
void testFunctionPointer() {
    int (*funcPtr)(int, int) = add;
    callWithPrint("Function Pointer", funcPtr, 3, 4);
}

// ② 普通函数
int multiply(int a, int b) {
    return a * b;
}
void testNormalFunction() {
    callWithPrint("Normal Function", multiply, 5, 6);
}

// ③ Lambda 表达式
void testLambda() {
    auto divide = [](int a, int b) { return a / b; };
    callWithPrint("Lambda", divide, 10, 2);
}

// ④ 仿函数（函数对象）
struct Subtract {
    int operator()(int a, int b) const {
        return a - b;
    }
};
void testFunctionObject() {
    Subtract sub;
    callWithPrint("Function Object", sub, 8, 3);
}

// ⑤ 成员函数指针
struct Calculator {
    int mod(int a, int b) {
        return a % b;
    }
};
void testMemberFunctionPointer() {
    Calculator c;
    int (Calculator:: * func)(int, int) = &Calculator::mod;
    callWithPrint("Member Function Pointer", func, c, 9, 4);
}

// ⑥ std::function 封装任意可调用对象
void testStdFunction() {
    std::function<int(int, int)> f = add;
    callWithPrint("std::function", f, 2, 9);
}

// ➕ std::bind 示例
int power(int base, int exp) {
    int result = 1;
    while (exp--) result *= base;
    return result;
}
void testStdBind() {
    // 使用 std::bind 创建一个“立方”函数对象（只需一个参数）
    // 将原始函数 power(int base, int exp) 的 exp 固定为 3
    // std::placeholders::_1 表示调用 cube 时传入的第一个参数将作为 base
    auto cube = std::bind(power, std::placeholders::_1, 3);

    // cube(2) 实际等价于 power(2, 3)，即 2 的立方
    callWithPrint("std::bind", cube, 2);
}

// std::invoke 示例（展示直接调用 vs std::invoke）
void testStdInvoke() {
    // 普通函数
    callWithPrint("std::invoke (normal function)", add, 7, 5);

    // Lambda
    auto lambda = [](int x, int y) { return x * y; };
    callWithPrint("std::invoke (lambda)", lambda, 3, 4);

    // 仿函数
    Subtract sub;
    callWithPrint("std::invoke (functor)", sub, 10, 4);

    // 成员函数指针
    Calculator c;
    int (Calculator:: * method)(int, int) = &Calculator::mod;
    callWithPrint("std::invoke (member fn ptr)", method, c, 13, 5);
}

// 菜单调用
int main() {
    cout << "请选择要测试的可调用对象类型（输入编号）:\n"
        << "1. 函数指针\n"
        << "2. 普通函数\n"
        << "3. Lambda 表达式\n"
        << "4. 仿函数（函数对象）\n"
        << "5. 成员函数指针\n"
        << "6. std::function\n"
        << "7. std::bind\n"
        << "8. std::invoke\n"
        << "0. 全部测试\n";

    int choice;
    cin >> choice;

    switch (choice) {
    case 1: testFunctionPointer(); break;
    case 2: testNormalFunction(); break;
    case 3: testLambda(); break;
    case 4: testFunctionObject(); break;
    case 5: testMemberFunctionPointer(); break;
    case 6: testStdFunction(); break;
    case 7: testStdBind(); break;
    case 8: testStdInvoke(); break;
    case 0:
        testFunctionPointer();
        testNormalFunction();
        testLambda();
        testFunctionObject();
        testMemberFunctionPointer();
        testStdFunction();
        testStdBind();
        testStdInvoke();
        break;
    default:
        cout << "输入无效" << endl;
    }

    return 0;
}
```

#### 可调用对象统一性体现：`std::invoke`

从 C++17 开始，`std::invoke` 提供了一个统一的方式调用任何可调用对象：

```cpp
#include <functional>
#include <iostream>
using namespace std;

int add(int a, int b) { return a + b; }

int main() {
    cout << std::invoke(add, 3, 4) << endl;  // 输出 7
}
```

#### 泛型编程中如何写“接受任意可调用对象”的函数

方法一：使用模板参数

```cpp
template<typename F>
void apply(F func) {
    cout << func(10) << endl;
}

apply([](int x) { return x * 3; });  // 输出 30
```

方法二：使用 `std::function`

```cpp
void apply(std::function<int(int)> f) {
    cout << f(10) << endl;
}

apply([](int x) { return x * 3; });  // 输出 30
```

> 区别：模板方式更高效，无运行时开销；`std::function` 更灵活、支持类型擦除。

#### 总结

| 可调用对象类型     | 是否支持状态 | 是否匿名 | 可用于模板      | 可用于 `std::function` |
| ------------------ | ------------ | -------- | --------------- | ---------------------- |
| 函数指针           | ❌            | 否       | ✅               | ✅                      |
| 函数对象（仿函数） | ✅            | 否       | ✅               | ✅                      |
| Lambda             | ✅（可捕获）  | 是       | ✅               | ✅                      |
| 成员函数指针       | ❌            | 否       | ✅               | ✅（需绑定对象）        |
| `std::bind` 结果   | ✅            | 否       | ✅               | ✅                      |
| `std::function`    | ✅            | 否       | ✅（需类型匹配） | N/A                    |

### function

`std::function` 是 C++11 标准库中提供的一个**模板类**，它用来**封装任何可以调用的目标**（函数、函数指针、函数对象、Lambda表达式等），并且能以统一的方式存储和调用它们。

换句话说，`std::function` 是一种通用的“函数包装器”，可以把“可调用对象”作为变量存储下来，后续再调用。

#### 示例

```cpp
#include <iostream>
#include <functional>
#include <map>
#include <string>

// 普通函数
int add(int a, int b) {
    return a + b;
}

// 函数对象（仿函数）
struct Multiply {
    int operator()(int a, int b) const {
        return a * b;
    }
};

// 用 std::function 作为参数，做回调示范
void applyOperation(int x, int y, std::function<int(int, int)> op) {
    std::cout << "Result: " << op(x, y) << std::endl;
}

int main() {
    // 使用 map<string, function> 存储不同的操作函数
    std::map<std::string, std::function<int(int, int)>> ops;

    // 插入普通函数
    ops["add"] = add;

    // 插入 Lambda 表达式
    ops["subtract"] = [](int a, int b) { return a - b; };

    // 插入函数对象
    ops["multiply"] = Multiply();

    // 插入另一个 Lambda 表达式
    ops["mod"] = [](int a, int b) { return a % b; };

    // 访问和调用
    std::cout << "add(2, 3) = " << ops["add"](2, 3) << std::endl;
    std::cout << "subtract(5, 3) = " << ops["subtract"](5, 3) << std::endl;
    std::cout << "multiply(3, 4) = " << ops["multiply"](3, 4) << std::endl;
    std::cout << "mod(10, 3) = " << ops["mod"](10, 3) << std::endl;

    // 使用回调函数演示
    applyOperation(10, 5, ops["add"]);
    applyOperation(10, 5, ops["subtract"]);

    // 遍历 map，调用所有操作
    // C++17 的结构化绑定
    for (const auto& [name, func] : ops) {
        std::cout << name << "(10, 3) = " << func(10, 3) << std::endl;
    }

    return 0;
}
```

#### 重载的函数与 `std::function` 中的二义性（Ambiguity）

```cpp
int add(int a, int b) { return a + b; }
double add(double a, double b) { return a + b; }

// 错误示范：
std::function<int(int,int)> f = add;  // 编译错误，二义性
```

其中 `add` 是一个重载函数（多个 `add` 函数），编译器不知道你是想指哪个版本的 `add`，因为仅凭函数名无法推断调用哪个重载函数。这个不确定性就是 **二义性**。

解决办法：

```cpp
#include <iostream>
#include <functional>

// 重载函数
int add(int a, int b) {
    return a + b;
}

double add(double a, double b) {
    return a + b;
}

int main() {
    // 1. 用 static_cast 显式转换解决二义性
    std::function<int(int,int)> f1 = static_cast<int(*)(int,int)>(add);
    std::cout << "static_cast: " << f1(3, 4) << std::endl;

    // 2. 用 Lambda 包装，显式调用具体重载
    std::function<int(int,int)> f2 = [](int x, int y) {
        return add(x, y);  // 编译器根据参数类型推断调用 int 版本
    };
    std::cout << "lambda: " << f2(5, 6) << std::endl;

    // 3. 先存函数指针变量，再赋值给 std::function
    int (*pAdd)(int,int) = add;  // 指向 int 版本
    std::function<int(int,int)> f3 = pAdd;
    std::cout << "func pointer: " << f3(7, 8) << std::endl;

    return 0;
}
```

- **方法1：`static_cast`**
   直接告诉编译器选用哪个具体签名的重载，消除二义性。
- **方法2：Lambda**
   Lambda 是一个匿名函数，可在内部调用重载函数，参数匹配由编译器推断，无需转换。
- **方法3：函数指针变量**
   用函数指针变量先显式指定重载版本，再赋给 `std::function`。

#### `std::function` 的底层实现原理（简要）

- `std::function` 是一个类型擦除（type-erasure）机制的典型应用。
- 它内部维护一个指向“可调用对象”的指针，这个对象可以是普通函数指针、函数对象、Lambda 等。
- 对调用者隐藏具体类型，只暴露统一的调用接口。
- 实现上通常用一个基类接口（抽象类）来封装调用操作，具体的可调用对象继承它，实现调用操作。
- 通过虚函数表（vtable）实现运行时多态调用。
- 还有小对象优化（small buffer optimization），避免频繁堆分配，提高性能。

#### 性能问题

- **灵活性带来开销**：由于使用了类型擦除和虚函数调用，`std::function` 的调用比直接调用函数指针或内联函数稍慢。
- **堆分配开销**：如果封装的可调用对象体积较大，`std::function` 需要在堆上分配内存，导致分配和释放的性能损失。
- **小对象优化（SBO）**：`std::function` 通常有内置的小缓冲区（一般几十字节），用于存放小型可调用对象，避免堆分配，性能提升明显。
- **调用频繁、性能敏感场景**：如果函数调用非常频繁，且对性能要求极高，建议避免使用 `std::function`，改用函数指针或模板参数传递函数。
- **拷贝成本**：`std::function` 对象拷贝时，底层可调用对象也需要被拷贝，可能带来额外开销。

#### 没有`std::function` 之前，如何实现类似功能

##### 1. **函数指针（Function Pointers）**

这是最基础的机制，C语言时代就有：

```cpp
int (*funcPtr)(int, int) = add;
funcPtr(2, 3);
```

**限制**：

- 只能指向普通函数（静态函数），不能指向捕获了外部变量的 Lambda，也不能指向函数对象。
- 不能直接封装状态（如函数对象内的成员变量）。

##### 2. **函数对象（Functors）**

写一个类重载 `operator()`：

```cpp
struct Multiply {
    int operator()(int a, int b) const {
        return a * b;
    }
};
Multiply multiply;
multiply(2,3);
```

**问题**：

- 不同函数对象类型不同，不能用同一个变量存储。
- 只能通过模板实现灵活传递。

##### 3. **模板函数（Template Functions）**

通过模板参数传入不同的可调用对象，实现“泛型回调”：

```cpp
template<typename Func>
void process(int x, int y, Func op) {
    std::cout << op(x, y) << std::endl;
}
```

调用时：

```cpp
process(2, 3, add);
process(2, 3, Multiply());
process(2, 3, [](int a, int b){ return a - b; });
```

**问题**：

- 这是编译时多态，函数模板每种不同类型都会生成不同代码（代码膨胀）。
- 不能存储异构的可调用对象到同一个变量中。
- 不能在运行时动态改变行为。

##### 4. **自己实现类型擦除**

一些大型库或者框架会自己实现类似 `std::function` 的类型擦除机制，把各种调用形式封装成统一接口。

**但这很复杂**，C++11 标准引入了 `std::function`，提供标准化、通用且高效的解决方案。