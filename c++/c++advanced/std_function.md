## std_function

`std::function` 是 C++11 标准库中提供的一个**模板类**，它用来**封装任何可以调用的目标**（函数、函数指针、函数对象、Lambda表达式等），并且能以统一的方式存储和调用它们。

换句话说，`std::function` 是一种通用的“函数包装器”，可以把“可调用对象”作为变量存储下来，后续再调用。

### 具体使用例子

```cpp
#include <iostream>
#include <functional>
#include <vector>

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
    // 1. 存储普通函数
    std::function<int(int, int)> func = add;
    std::cout << "add(2, 3) = " << func(2, 3) << std::endl;

    // 2. 存储 Lambda 表达式
    func = [](int a, int b) { return a - b; };
    std::cout << "lambda(5, 3) = " << func(5, 3) << std::endl;

    // 3. 存储函数对象
    func = Multiply();
    std::cout << "multiply(3, 4) = " << func(3, 4) << std::endl;

    // 4. 使用 std::function 作为参数，实现回调
    applyOperation(10, 5, add);
    applyOperation(10, 5, [](int a, int b) { return a / b; });

    // 5. 存储并调用多个不同操作
    std::vector<std::function<int(int,int)>> ops = {add, Multiply(), [](int a, int b) { return a % b; }};
    for (auto& op : ops) {
        std::cout << op(10, 3) << std::endl;
    }

    return 0;
}
```

### `std::function` 的底层实现原理（简要）

- `std::function` 是一个类型擦除（type-erasure）机制的典型应用。
- 它内部维护一个指向“可调用对象”的指针，这个对象可以是普通函数指针、函数对象、Lambda 等。
- 对调用者隐藏具体类型，只暴露统一的调用接口。
- 实现上通常用一个基类接口（抽象类）来封装调用操作，具体的可调用对象继承它，实现调用操作。
- 通过虚函数表（vtable）实现运行时多态调用。
- 还有小对象优化（small buffer optimization），避免频繁堆分配，提高性能。

### 性能问题

- **灵活性带来开销**：由于使用了类型擦除和虚函数调用，`std::function` 的调用比直接调用函数指针或内联函数稍慢。
- **堆分配开销**：如果封装的可调用对象体积较大，`std::function` 需要在堆上分配内存，导致分配和释放的性能损失。
- **小对象优化（SBO）**：`std::function` 通常有内置的小缓冲区（一般几十字节），用于存放小型可调用对象，避免堆分配，性能提升明显。
- **调用频繁、性能敏感场景**：如果函数调用非常频繁，且对性能要求极高，建议避免使用 `std::function`，改用函数指针或模板参数传递函数。
- **拷贝成本**：`std::function` 对象拷贝时，底层可调用对象也需要被拷贝，可能带来额外开销。

### 没有`std::function` 之前，如何实现类似功能

#### 1. **函数指针（Function Pointers）**

这是最基础的机制，C语言时代就有：

```cpp
int (*funcPtr)(int, int) = add;
funcPtr(2, 3);
```

**限制**：

- 只能指向普通函数（静态函数），不能指向捕获了外部变量的 Lambda，也不能指向函数对象。
- 不能直接封装状态（如函数对象内的成员变量）。

#### 2. **函数对象（Functors）**

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

#### 3. **模板函数（Template Functions）**

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

#### 4. **自己实现类型擦除**

一些大型库或者框架会自己实现类似 `std::function` 的类型擦除机制，把各种调用形式封装成统一接口。

**但这很复杂**，C++11 标准引入了 `std::function`，提供标准化、通用且高效的解决方案。