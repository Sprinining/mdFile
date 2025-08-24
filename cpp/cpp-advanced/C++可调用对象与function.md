## C++ 可调用对象与 function

### 可调用对象

在 C++ 中，**可调用对象（Callable Object）**是指**可以像函数一样使用圆括号 `()` 进行调用**的对象。C++ 支持多种形式的可调用对象，不只是普通函数。

```cpp
obj(args...);  // ← 这就是“可调用”
```

例如：

- `func(1, 2);`：`func` 是一个可调用对象；
- `lambda(3);`：lambda 是可调用对象；
- `FunctionObject()`：重载了 `operator()` 的对象。

#### 分类

| 类型                         | 示例说明                      |
| ---------------------------- | ----------------------------- |
| ① 函数指针（伪函数）         | `int (*f)(int)`               |
| ② 普通函数                   | `int add(int a, int b)`       |
| ③ Lambda 表达式              | `[](int x) { return x + 1; }` |
| ④ 函数对象（仿函数）         | 自定义类重载 `operator()`     |
| ⑤ 成员函数指针               | `&MyClass::memberFunction`    |
| ⑥ `std::function` 对象       | `std::function<int(int)>`     |
| ⑦ `std::bind` 生成的绑定对象 | `std::bind(add, 2, _1)`       |

#### 示例

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

// ⑦ std::bind 示例
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

#### 可调用对象统一性体现：std::invoke

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

模板方式更高效，无运行时开销；`std::function` 更灵活、支持类型擦除。

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

#### 二义性

```cpp
int add(int a, int b) { return a + b; }
double add(double a, double b) { return a + b; }

// 错误示范：
std::function<int(int,int)> f = add;  // 编译错误，二义性
```

其中 `add` 是一个重载函数（多个 `add` 函数），编译器不知道你是想指哪个版本的 `add`，因为仅凭函数名无法推断调用哪个重载函数。这个不确定性就是**二义性（Ambiguity）**。

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

#### 底层实现原理

##### 类型擦除原理

`std::function<R(Args...)>` 内部并不直接存储具体类型 `F`，而是通过**虚函数表或函数指针表**来实现调用。

核心思想：

```cpp
// 模拟 std::function 的基本实现
// R 是返回类型，Args... 是参数类型列表
template<typename R, typename... Args>
class function<R(Args...)> {
    
    // ---------- 类型擦除基类 ----------
    // callable_base 是所有可调用对象的统一接口
    struct callable_base {
        virtual R call(Args...) = 0;           // 统一调用接口，实际调用具体对象
        virtual callable_base* clone() const = 0; // 复制接口，用于拷贝 std::function
        virtual ~callable_base() {}            // 虚析构函数，保证派生类对象正确析构
    };

    // ---------- 可调用对象包装器 ----------
    // 通过模板将任意可调用对象 F 包装成 callable_base
    template<typename F>
    struct callable_wrapper : callable_base {
        F f;  // 保存具体的可调用对象

        // 构造函数，使用完美转发支持左值和右值
        callable_wrapper(F&& fn) : f(std::forward<F>(fn)) {}

        // 重写 call，调用实际的可调用对象
        R call(Args... args) override {
            return f(std::forward<Args>(args)...);
        }

        // 重写 clone，实现对象的深拷贝
        callable_base* clone() const override {
            return new callable_wrapper(f);
        }
    };

    callable_base* obj;  // 指向内部可调用对象（类型擦除后的统一接口）

public:
    // ---------- 构造函数 ----------
    // 支持任意可调用对象（函数指针、lambda、函数对象）
    template<typename F>
    function(F&& f) : obj(new callable_wrapper<F>(std::forward<F>(f))) {}

    // ---------- 调用操作符 ----------
    // 通过类型擦除指针间接调用具体可调用对象
    R operator()(Args... args) {
        return obj->call(std::forward<Args>(args)...);
    }

    // 注意：真实 std::function 还会有析构函数、拷贝构造、移动构造、赋值操作符等
};
```

- `callable_base`

  - 是类型擦除的关键，统一了各种可调用对象的接口。

  - 虚函数实现了 **运行时多态**，无需知道对象具体类型就可以调用。

- `callable_wrapper<F>`

  - 模板包装器，将任意类型 F 转换成 `callable_base` 接口。

  - 支持 **完美转发**，保证参数和返回值类型正确。

  - clone 方法实现了 std::function 的深拷贝能力。

- `obj`

  - 保存内部实际对象的指针（类型擦除后的指针）。

  - 可以是堆上分配的，也可以在真实实现中利用 SOO 优化。

- `operator()`
  - 用户调用 std::function 时，通过类型擦除接口间接调用实际对象。

##### 内存管理：小对象优化 (SOO)

为了提高性能，`std::function` 不总是堆分配：

- **小对象**（一般 <= 3 指针大小）会直接存储在 `std::function` 内部的缓冲区。
- **大对象**会分配在堆上。

这样可以减少频繁的 `new/delete`，提高效率。

##### 调用机制

调用可分两步：

1. 通过类型擦除指针（虚表或函数指针表）找到对应的 `call`。
2. 转发参数到具体的可调用对象。

##### 拷贝与移动

`std::function` 支持拷贝与移动：

- **拷贝**：调用 `clone()` 生成新的 `callable_wrapper`。
- **移动**：直接移动内部对象，避免额外分配。

##### 现代实现中的优化

在最新标准库实现中（如 libc++、libstdc++）：

- 使用**函数指针表而非虚函数**，减少虚表开销。
- SOO 的缓冲区通常为 `3 * sizeof(void*)`。
- 支持**异常安全**的调用和释放。
- 对于不捕获 lambda，会直接存储函数指针，不使用堆。

#### 性能问题

##### 虚函数调用开销

- 经典实现里 `callable_base::call` 是虚函数，每次调用 `operator()` 都通过虚表间接调用。
- 虚函数调用比直接调用函数指针略慢（现代 CPU 分支预测和内联优化可以减轻，但仍存在额外间接调用开销）。
- **影响**：在性能敏感的热点代码（每次循环调用函数）可能有明显开销。

##### 堆分配

- 如果封装的可调用对象较大或无法小对象优化（SOO），`std::function` 会在堆上分配 `callable_wrapper`。
- 堆分配带来的开销：
  1. `new/delete` 本身慢
  2. 可能导致缓存未命中（cache miss）
- **影响**：频繁构造/销毁 `std::function` 的场景性能会下降。

##### 对象拷贝

- `std::function` 默认是深拷贝，调用 `clone()` 创建新对象。
- 对大对象或捕获大量数据的 lambda，拷贝成本较高。
- **优化**：如果对象可移动，可以使用移动构造减少拷贝。

##### 内联限制

- 由于 `std::function` 类型擦除，调用路径间接化，很难让编译器直接内联被封装的可调用对象。
- **影响**：高性能计算场景，无法像直接调用 lambda 或函数对象那样完全内联优化。