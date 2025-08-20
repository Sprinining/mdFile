## C++ 函数对象

### 函数对象（仿函数）

- 函数对象（仿函数）（Function Object，Functors）其实就是**重载了 `operator()` 的类或结构体**的实例。

- 它表现得像函数一样，可以用 `()` 括号调用，但本质是一个对象，可以有成员变量和状态。

- 优点是它可以存储状态，比如调用时用到的参数、计数器、配置等。

**函数对象既可以无状态（Multiply）也可以带状态（Counter）**，并且都能像函数一样调用：

```cpp
#include <iostream>

// 无状态函数对象：执行乘法
struct Multiply {
    int operator()(int a, int b) const {
        return a * b;
    }
};

// 带状态的函数对象：计数调用次数
struct Counter {
    int count = 0;  // 内部状态

    void operator()() {
        ++count;
        std::cout << "Called " << count << " times" << std::endl;
    }
};

int main() {
    // 使用无状态函数对象
    Multiply multiply;
    int result = multiply(3, 4);  // 调用了 multiply.operator()(3, 4)
    std::cout << "Multiply result: " << result << std::endl;  // 输出 12

    // 使用带状态的函数对象
    Counter counter;
    counter();  // 输出：Called 1 times
    counter();  // 输出：Called 2 times
    counter();  // 输出：Called 3 times

    return 0;
}
```

### 函数指针（伪函数）

- 伪函数通常就是指**函数指针（Function Pointer）**，是指向函数的指针变量。

- 它可以指向普通函数，调用时通过指针间接调用函数。

```cpp
int add(int a, int b) {
    return a + b;
}

int (*funcPtr)(int, int) = add;  // 函数指针指向 add 函数
int result = funcPtr(2, 3);      // 通过函数指针调用函数
```

有时候人们也称它为“伪函数”，意思是它是对函数的引用（指针），而不是一个真正的对象。

### 函数对象 vs 函数指针 vs lambda

| 特性            | 函数对象（仿函数） | 函数指针       | Lambda 表达式     |
| --------------- | ------------------ | -------------- | ----------------- |
| 是否可调用      | 是                 | 是             | 是                |
| 是否可保存状态  | 是（成员变量）     | 否             | 是（捕获变量）    |
| 类型            | 类类型             | 指针类型       | 匿名闭包类类型    |
| 可用于 STL 算法 | 是                 | 是（但无状态） | 是（常用于 sort） |
| 内联优化可能性  | 高                 | 低（间接调用） | 高                |

### 函数对象 vs std::function

```cpp
#include <functional>

struct Multiply {
    int operator()(int a, int b) const {
        return a * b;
    }
};

int main() {
    function<int(int, int)> f = Multiply();  // 用 std::function 接收仿函数
    cout << f(6, 7) << endl;  // 输出 42
}
```

- `std::function` 是一种类型擦除容器；
- 它可以接收函数对象、函数指针、lambda；
- 函数对象可以与之很好地结合，统一成接口参数。

### 标准库中的函数对象

C++ STL 提供了一些常用函数对象：

```cpp
#include <functional>

greater<int>()(3, 2);  // 返回 true，相当于 3 > 2
less<int>()(3, 2);     // 返回 false，相当于 3 < 2
equal_to<int>()(3, 3); // 返回 true
```

这些定义在 `<functional>` 中，常用于模板泛型编程。

### 函数对象的实际应用场景

- 配合 `sort`、`for_each`、`transform` 等算法
- 封装可调用逻辑，提供**函数接口但拥有对象状态**
- 实现策略模式、回调机制
- 在 STL 容器中按需定制行为（如 `priority_queue`）