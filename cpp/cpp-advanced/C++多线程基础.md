## C++多线程基础

### 1. 多线程基础

多线程是指一个程序中同时运行多个执行流（线程），能够充分利用多核CPU，提高程序并发性和效率。C++11 标准引入了官方的多线程支持，主要在 `<thread>`, `<mutex>`, `<condition_variable>` 等头文件中提供相关API。

### 2. 主要类和组件

#### 2.1 `std::thread`

- 表示一个线程对象。
- 构造时传入线程执行函数和参数。
- 线程启动后自动并发运行。

**示例：**

```cpp
#include <iostream>
#include <thread>

void func() {
    std::cout << "Hello from thread!" << std::endl;
}

int main() {
    std::thread t(func);  // 创建并启动线程t执行func
    t.join();             // 等待线程t执行完毕
    return 0;
}
```

- `join()`：等待线程结束，阻塞主线程直到子线程完成。
- `detach()`：使线程与主线程分离，线程后台运行，不能等待。

#### 2.2 线程参数传递

- 线程函数可以带参数。
- `std::thread` 构造函数可传入参数，会完美转发给线程函数。

**示例：**

```cpp
void printNum(int x) {
    std::cout << "Number: " << x << std::endl;
}

int main() {
    std::thread t(printNum, 10);
    t.join();
}
```

#### 2.3 线程返回值

`std::thread` 函数本身不支持直接返回值。

若需要线程返回值，一般用：

- `std::promise` 和 `std::future`
- 或者 `std::async`

#### 2.4 `std::mutex`（互斥锁）

用于保护共享资源，防止数据竞争。

**示例：**

```cpp
#include <mutex>
#include <thread>
#include <iostream>

int counter = 0;
std::mutex mtx;

void increment() {
    for(int i = 0; i < 1000; ++i) {
        std::lock_guard<std::mutex> lock(mtx);
        ++counter;
    }
}

int main() {
    std::thread t1(increment);
    std::thread t2(increment);
    t1.join();
    t2.join();
    std::cout << "Counter = " << counter << std::endl;  // 正确值2000
}
```

- `std::lock_guard` 是RAII风格的锁，作用域结束自动解锁。
- `mutex` 保证同一时间只有一个线程访问被保护代码段。

#### 2.5 `std::unique_lock`

比 `lock_guard` 更灵活，支持手动加锁、解锁、延迟加锁等。

#### 2.6 `std::condition_variable`（条件变量）

用于线程间通知和等待。

**示例：**

```cpp
#include <condition_variable>
#include <mutex>
#include <thread>
#include <iostream>

std::mutex mtx;
std::condition_variable cv;
bool ready = false;

void worker() {
    std::unique_lock<std::mutex> lock(mtx);
    cv.wait(lock, []{ return ready; });  // 等待ready为true
    std::cout << "Worker thread proceed\n";
}

int main() {
    std::thread t(worker);

    {
        std::lock_guard<std::mutex> lock(mtx);
        ready = true;
    }
    cv.notify_one();  // 通知worker线程

    t.join();
}
```

### 3. 线程的生命周期管理

- 创建线程后，必须调用 `join()` 或 `detach()`，否则程序会异常终止。
- `join()` 阻塞等待线程结束。
- `detach()` 线程独立运行，主线程不等待。

### 4. 线程同步和竞态条件

- 多线程共享数据时，必须使用锁（如mutex）避免竞态条件。
- 竞态条件会导致数据不一致和未定义行为。

### 5. `std::async` 和 `std::future`

- `std::async` 可以异步启动任务，自动管理线程。
- `std::future` 可用于获取异步任务返回值。

**示例：**

```cpp
#include <future>
#include <iostream>

int compute() {
    return 42;
}

int main() {
    std::future<int> fut = std::async(std::launch::async, compute);
    int result = fut.get();  // 阻塞等待结果
    std::cout << "Result: " << result << std::endl;
}
```

### 6. 线程相关的常用函数和特性

- `std::this_thread::sleep_for()`：线程睡眠指定时间
- `std::this_thread::get_id()`：获取当前线程id
- `std::thread::hardware_concurrency()`：返回系统支持的并发线程数（硬件线程数）

### 7. 总结

| 组件                      | 功能               | 备注                  |
| ------------------------- | ------------------ | --------------------- |
| `std::thread`             | 创建线程           | 需手动 join 或 detach |
| `std::mutex`              | 互斥锁保护共享数据 | 避免竞态              |
| `std::lock_guard`         | 简单锁管理，RAII   | 作用域自动加解锁      |
| `std::unique_lock`        | 更灵活锁管理       | 支持延迟加锁、解锁    |
| `std::condition_variable` | 线程间等待和通知   | 用于条件同步          |
| `std::async`/`future`     | 异步任务和返回值   | 方便简洁地获取结果    |

