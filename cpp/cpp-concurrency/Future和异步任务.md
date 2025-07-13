## Future和异步任务

当在等待某个异步事件（比如机场广播通知登机）时，这种事件对应C++中的 `future`。`future` 用于表示某个操作的结果将在未来某个时间可用，线程可以等待这个结果。

C++标准库中有两种 `future`：

- **`std::future<T>`**：独占所有权，只能有一个对象持有该结果。
- **`std::shared_future<T>`**：可被多个对象共享，可以被多个线程访问。

两者类似于智能指针中的 `unique_ptr` 和 `shared_ptr`。

### 后台任务的返回值

#### 获取任务返回值

`std::thread` 不能直接获取线程执行函数的返回值，而 `std::async` 返回一个 `std::future`，可以用它来异步执行任务，并稍后获取结果。

```cpp
#include <future>
#include <iostream>
#include <thread>
#include <chrono>

// 模拟一个耗时计算任务
int find_the_answer_to_ltuae() {
    std::this_thread::sleep_for(std::chrono::seconds(2)); // 模拟耗时任务
    return 42;
}

// 模拟其他正在执行的任务
void do_other_stuff() {
    std::cout << "Doing other stuff while waiting...\n";
    std::this_thread::sleep_for(std::chrono::seconds(1));
    std::cout << "Still working...\n";
}

int main() {
    // 启动异步任务
    std::future<int> the_answer = std::async(std::launch::async, find_the_answer_to_ltuae);

    do_other_stuff(); // 执行其他操作（不阻塞主线程）

    // 获取异步任务的结果（阻塞直到完成）
    std::cout << "The answer is " << the_answer.get() << std::endl;

    return 0;
}
```

输出：

```css
Doing other stuff while waiting...
Still working...
The answer is 42
```

- 调用 `get()` 会：

  - 如果任务已经完成，立刻返回结果。

  - 如果任务还没完成，调用线程会**阻塞等待**直到结果准备好。

- `get()` 只能调用一次，之后该 `future` 就失效了。

#### 传递参数

`std::async` 还可以传递参数给函数：

```cpp
#include <string>
#include <future>
#include <iostream>
#include <functional>  // std::ref

// 示例结构体 X，包含成员函数 foo 和 bar
struct X {
  void foo(int i, std::string const& s) {
    std::cout << "X::foo called with " << i << " and " << s << std::endl;
  }
  std::string bar(std::string const& s) {
    std::cout << "X::bar called with " << s << std::endl;
    return s + " from bar";
  }
};

X x;  // 全局对象 x

// 带参数的函数，接受 X 的引用
X baz(X& xref) {
  std::cout << "baz called with X&" << std::endl;
  return xref; // 这里简单返回传入的对象拷贝
}

// 可调用类，移动语义，只能移动不能拷贝
class move_only {
public:
  move_only() {
    std::cout << "move_only default ctor" << std::endl;
  }
  move_only(move_only&&) {
    std::cout << "move_only move ctor" << std::endl;
  }
  move_only& operator=(move_only&&) {
    std::cout << "move_only move assign" << std::endl;
    return *this;
  }
  move_only(move_only const&) = delete;  // 禁止拷贝构造
  move_only& operator=(move_only const&) = delete;  // 禁止拷贝赋值

  void operator()() {
    std::cout << "move_only operator() called" << std::endl;
  }
};

struct Y {
  double operator()(double d) {
    std::cout << "Y::operator() called with " << d << std::endl;
    return d * 2;
  }
};

int main() {
  // 调用成员函数 foo，传入指针 x 和参数
  auto f1 = std::async(&X::foo, &x, 42, "hello");     // 运行 x.foo(42, "hello")

  // 调用成员函数 bar，传入 x 的拷贝和参数
  auto f2 = std::async(&X::bar, x, "goodbye");        // 运行 x_copy.bar("goodbye")

  Y y;

  // 调用 Y 的临时对象 operator()(3.141)
  auto f3 = std::async(Y(), 3.141);

  // 使用 std::ref 引用 y，避免拷贝，调用 y(2.718)
  auto f4 = std::async(std::ref(y), 2.718);

  // 调用函数 baz，传入 x 的引用
  auto f_baz = std::async(baz, std::ref(x));

  // 调用 move_only 的临时对象 operator()
  auto f5 = std::async(move_only());

  // 等待任务完成并获取返回值（有返回值的）
  f1.get();  // foo 返回 void，无返回值
  std::string s = f2.get();  // bar 返回 std::string
  std::cout << "Returned from bar: " << s << std::endl;

  double d1 = f3.get();
  std::cout << "Returned from Y(): " << d1 << std::endl;

  double d2 = f4.get();
  std::cout << "Returned from std::ref(y): " << d2 << std::endl;

  X x2 = f_baz.get();  // baz 返回 X 对象

  f5.get();  // move_only operator() 返回 void

  return 0;
}
```

输出：

```css
X::foo called with 42 and helloX::bar called with goodbye
Y::operator() called with 2.718
move_only default ctor
move_only move ctor
move_only move ctor

baz called with X&
move_only operator() called
Y::operator() called with 3.141
Returned from bar: goodbye from bar
Returned from Y(): 6.282
Returned from std::ref(y): 5.436
```

- `std::async` 可以调用普通函数、成员函数、函数对象、lambda 等。
- 对于成员函数，必须传入对象指针或对象副本作为第一个参数。
- `std::ref` 用于传递引用，避免拷贝。
- `move_only` 类型只允许移动，不允许拷贝，演示了传递移动-only对象给 `std::async`。
- `get()` 等待异步任务完成并返回结果（如果有）。

#### 任务执行策略

`std::async` 还能通过 `std::launch` 参数控制任务执行策略：

```cpp
auto f6 = std::async(std::launch::async, Y(), 1.2);  // 在新线程上执行
auto f7 = std::async(std::launch::deferred, baz, std::ref(x));  // 延迟执行，调用 wait() 或 get() 时才执行
auto f8 = std::async(std::launch::deferred | std::launch::async, baz, std::ref(x));  // 由实现选择执行方式
auto f9 = std::async(baz, std::ref(x));
f7.wait();  // 调用延迟执行函数
```

| 调用方式                               | 说明                                   |
| -------------------------------------- | -------------------------------------- |
| `std::async(f)`                        | 默认策略（可能新线程，也可能延迟执行） |
| `std::async(std::launch::async, f)`    | 明确要求在**新线程中立即执行**         |
| `std::async(std::launch::deferred, f)` | 延迟执行，直到调用 `get()` 或 `wait()` |

### future 与任务关联 (`std::packaged_task`)

`std::packaged_task` 把函数或可调用对象和一个 `future` 绑定起来，调用任务时会设置对应的 future 状态，方便任务结果的获取。

```cpp
// 偏特化版本的 std::packaged_task，用于封装一个函数签名：
// std::string(std::vector<char>*, int)
// 表示可以接收两个参数（一个字符向量指针和一个整数），并返回 std::string
template<>
class packaged_task<std::string(std::vector<char>*, int)> {
public:
  // 构造函数：接受任意可调用对象（函数、lambda、函数对象等）
  // 这个对象必须能兼容 std::string(std::vector<char>*, int) 的调用
  template<typename Callable>
  explicit packaged_task(Callable&& f);

  // 获取与该 task 关联的 future 对象
  // 用于获取任务执行后产生的 std::string 类型结果
  std::future<std::string> get_future();

  // 调用操作符重载：调用被封装的函数对象
  // 并将参数传递给它（一个 vector<char>* 指针和一个 int）
  // 执行结果会自动存储到对应的 future 中
  void operator()(std::vector<char>*, int);
};
```

任务可以传递给线程：

```cpp
#include <deque>      // std::deque，用于任务队列
#include <mutex>      // std::mutex, std::lock_guard，用于线程安全
#include <future>     // std::packaged_task, std::future
#include <thread>     // std::thread
#include <utility>    // std::move

// 全局互斥锁，用于保护任务队列
std::mutex m;

// 用于存放待 GUI 线程执行的任务（打包好的可调用对象）
std::deque<std::packaged_task<void()>> tasks;

// 模拟 GUI 消息处理与关闭信号（由调用者实现）
bool gui_shutdown_message_received();      // 是否收到关闭指令
void get_and_process_gui_message();        // 处理 GUI 消息

// GUI 后台线程执行函数
void gui_thread() { // ① GUI 主循环函数
  while (!gui_shutdown_message_received()) { // ② 没收到退出信号时循环
      get_and_process_gui_message();          // ③ 先处理 GUI 的原生消息（如点击事件等）

    std::packaged_task<void()> task;        // 任务对象
    {
      std::lock_guard<std::mutex> lk(m);    // 加锁保护共享队列

      if (tasks.empty())                    // ④ 如果当前没有新任务
        continue;

      task = std::move(tasks.front());      // ⑤ 取出队首任务并移交所有权
      tasks.pop_front();                    // 从队列中移除该任务
    }

    task();  // ⑥ 执行任务（调用被包装的函数）
  }
}

// 启动 GUI 后台线程
std::thread gui_bg_thread(gui_thread);

// 向 GUI 线程提交任务的接口（线程安全）
template<typename Func>
std::future<void> post_task_for_gui_thread(Func f) {
  // ⑦ 将传入的函数 f 封装为 packaged_task（用于将来执行并生成结果）
  std::packaged_task<void()> task(f);

  // ⑧ 从打包的任务中获取对应的 future（用于异步等待任务完成）
  std::future<void> res = task.get_future();

  // ⑨ 加锁后将任务放入队列，供 GUI 线程稍后取出并执行
  std::lock_guard<std::mutex> lk(m);
  tasks.push_back(std::move(task));

  // ⑩ 返回 future，调用方可以调用 res.get() 等待任务完成
  return res;
}
```

### 使用 `std::promise`

`std::promise` 是 C++ 标准库中的一个模板类，定义在 `<future>` 头文件里，主要用于线程间的异步通信，负责“承诺”将来某个时间点会提供一个值或异常。它与 `std::future` 配合使用，形成一种生产者-消费者模型。

#### 作用

- **生产者角色**：`std::promise` 用于在线程间传递结果。生产者线程通过它设置计算结果或者异常。
- **消费者角色**：`std::future` 用于接收异步计算的结果，等待或者获取值。

#### 主要功能

- **设置值**：通过 `set_value()` 将异步操作的结果传递给关联的 `std::future`。
- **设置异常**：通过 `set_exception()` 将异常信息传递给 `std::future`，使得消费者可以捕获异步操作中的异常。
- **获取关联的 future**：调用 `get_future()`，获得和该 promise 关联的 `std::future` 对象。

#### 示例 1

```cpp
#include <iostream>
#include <future>
#include <thread>
#include <exception>

// 生产者函数，负责计算并通过 promise 设置结果或异常
void producer(std::promise<int> p) {
    try {
        // 模拟计算过程，得到结果 42
        int result = 42;
        p.set_value(result);  // 将结果设置到 promise 中，使关联的 future 可获取
    } catch (...) {
        // 如果发生异常，将异常信息传递给关联的 future
        p.set_exception(std::current_exception());
    }
}

int main() {
    std::promise<int> p;           // 创建一个 promise 对象，负责设置异步计算结果
    std::future<int> f = p.get_future();  // 获取和 promise 关联的 future，用于异步接收结果

    // 创建一个线程，执行生产者函数，注意通过 std::move 传递 promise（promise 不可复制）
    std::thread t(producer, std::move(p));

    try {
        int value = f.get();       // 阻塞等待，直到生产者设置了结果或异常，获取计算结果
        std::cout << "Result: " << value << std::endl;
    } catch (const std::exception& e) {
        // 如果生产者传递了异常，则捕获并打印异常信息
        std::cout << "Exception caught: " << e.what() << std::endl;
    }

    t.join();                     // 等待生产者线程结束
    return 0;
}
```

- `std::promise` 和 `std::future` 一一对应，通过 `get_future()` 绑定。
- `set_value()` 和 `set_exception()` 只能调用一次，再调用会导致异常。
- 如果 `std::promise` 被销毁而没有设置值或异常，关联的 `std::future` 调用 `get()` 会抛出 `std::future_error` 异常。
- 适用于需要异步计算并跨线程传递结果的场景。

#### 示例 2

`std::promise` 和 `std::future` 配合可以手动设置异步结果，适合异步事件管理，比如网络连接多个端口数据的收发。

```cpp
#include <future>
#include <iostream>
#include <map>
#include <queue>
#include <string>

// 模拟数据类型
using payload_type = std::string;  // 传入和传出的数据类型

struct data_packet {
    int id;               // 数据包ID，用于匹配promise
    payload_type payload; // 具体数据
};

struct outgoing_packet {
    payload_type payload;         // 要发送的数据
    std::promise<bool> promise;  // 发送完成通知的promise
};

// 连接的简化模拟
class Connection {
public:
    int id;  // 连接标识
    std::queue<data_packet> incoming_queue;   // 收到的数据队列
    std::queue<outgoing_packet> outgoing_queue; // 待发送数据队列

    // 记录与数据包ID对应的promise（模拟一个map）
    std::map<int, std::promise<payload_type>> promises_map;

    // 检查是否有传入数据
    bool has_incoming_data() {
        return !incoming_queue.empty();
    }

    // 取出一个传入数据包
    data_packet incoming() {
        data_packet dp = incoming_queue.front();
        incoming_queue.pop();
        return dp;
    }

    // 获取对应ID的promise引用
    std::promise<payload_type>& get_promise(int id) {
        return promises_map[id];  // 如果不存在会自动创建
    }

    // 检查是否有要发送的数据
    bool has_outgoing_data() {
        return !outgoing_queue.empty();
    }

    // 获取队首待发送数据
    outgoing_packet top_of_outgoing_queue() {
        return outgoing_queue.front();
    }

    // 发送数据（模拟）
    void send(const payload_type& payload) {
        std::cout << "Sending data: " << payload << std::endl;
    }

    // 从发送队列弹出已发送数据
    void pop_outgoing() {
        outgoing_queue.pop();
    }
};

// 判断是否完成（简单模拟，所有连接都空了就完成）
bool done(const std::vector<Connection*>& connections) {
    for (auto& c : connections) {
        if (c->has_incoming_data() || c->has_outgoing_data())
            return false;
    }
    return true;
}

// 处理所有连接
void process_connections(std::vector<Connection*>& connections) {
    while (!done(connections)) {   // ① 主循环
        for (auto& connection : connections) {   // ② 遍历连接

            // 处理传入数据
            if (connection->has_incoming_data()) {  // ③
                data_packet data = connection->incoming();  // 读取数据包

                // 取到promise，通知等待线程数据已准备好
                std::promise<payload_type>& p = connection->get_promise(data.id);
                p.set_value(data.payload);  // ④ 设置promise，future会就绪
            }

            // 处理传出数据
            if (connection->has_outgoing_data()) {  // ⑤
                outgoing_packet data = connection->top_of_outgoing_queue();
                connection->send(data.payload);       // 发送数据
                data.promise.set_value(true);         // ⑥ 发送成功，通知future

                connection->pop_outgoing();            // 弹出已发送数据包
            }
        }
    }
}

// 测试示例
int main() {
    Connection c1;
    c1.id = 1;

    // 模拟接收一个数据包，ID = 42
    c1.incoming_queue.push({42, "Hello from client"});

    // 模拟要发送的数据
    std::promise<bool> send_promise;
    std::future<bool> send_future = send_promise.get_future();
    c1.outgoing_queue.push({"Reply to client", std::move(send_promise)});

    // 准备连接列表
    std::vector<Connection*> connections = {&c1};

    // 在另一线程模拟业务等待传入数据
    std::future<payload_type> receive_future = c1.get_promise(42).get_future();

    // 启动处理线程
    std::thread processor(process_connections, std::ref(connections));

    // 业务线程等待数据到来
    std::cout << "Waiting for incoming data..." << std::endl;
    std::string received = receive_future.get();  // 阻塞直到promise设置值
    std::cout << "Received data: " << received << std::endl;

    // 业务线程等待发送完成
    bool send_ok = send_future.get();
    std::cout << "Send success: " << std::boolalpha << send_ok << std::endl;

    processor.join();

    return 0;
}
```

- 连接 `Connection` 内部维护了 `std::promise`，用于传入数据通知。
- 监听线程（`process_connections`）收到数据后，调用 `promise.set_value()`，通知等待的业务线程。
- 业务线程持有对应的 `future`，通过 `future.get()` 阻塞等待数据。
- 同理，发送数据后，通过 `promise.set_value(true)` 通知发送是否成功。
- 通过 `promise` / `future` 机制，实现了线程间异步通信和同步等待。

### 将异常存储于 `future` 中

当异步任务发生异常时，异常会被存储到 `future` 中，调用 `get()` 时会重新抛出。

```cpp
#include <iostream>
#include <future>
#include <cmath>
#include <stdexcept>

// 计算平方根函数，如果传入负数会抛出异常
double square_root(double x) {
  if (x < 0) {
    throw std::out_of_range("x<0");  // 传入负数时抛出异常
  }
  return sqrt(x);  // 计算平方根
}

int main() {
  // 异步调用square_root函数，传入参数-1
  auto f = std::async(square_root, -1);

  try {
    // 获取异步结果，调用get()时会阻塞直到结果准备好
    // 如果被异步调用的函数抛异常，这里会重新抛出异常
    double y = f.get();  
  } catch (const std::exception& e) {
    // 捕获并打印异步调用时传递的异常信息
    std::cout << "Caught exception: " << e.what() << std::endl;
  }

  return 0;
}

```

- `std::async` 异步执行函数 `square_root(-1)`，函数内部会抛异常。
- `f.get()` 阻塞等待结果，如果异步函数抛异常，则 `get()` 会重新抛出该异常。
- `try-catch` 块捕获异常，打印异常信息。这样异步执行的异常能够安全传递到调用者线程。

用 `std::promise` 设置异常：

```cpp
// 声明一个外部的 std::promise<double> 对象，表示异步操作的承诺
extern std::promise<double> some_promise;

try {
  // 尝试计算一个值，并将结果设置到 promise 中
  some_promise.set_value(calculate_value());
} catch(...) {
  // 如果计算过程中抛出异常，捕获当前异常并存储到 promise 中
  // 这样与该 promise 关联的 future 线程在调用 get() 时会抛出此异常
  some_promise.set_exception(std::current_exception());
}
```

或者直接设置异常：

```cpp
some_promise.set_exception(std::make_exception_ptr(std::logic_error("foo")));
```

注意，如果 `std::promise` 或 `std::packaged_task` 销毁时没有设置值或异常，会自动存储 `std::future_error` 异常，通知对应的 future “承诺破裂”（broken promise）。

### 多线程的等待 (`std::shared_future`)

`std::future` 只能有一个所有者，调用 `get()` 后它就失效了，不适合多个线程共享同一结果。

`std::shared_future` 支持拷贝，多个线程可以持有相同的 future 副本，安全读取结果。

```cpp
#include <future>
#include <cassert>

int main() {
  std::promise<int> p;                       // 创建一个 promise，用来传递 int 类型的值
  std::future<int> f = p.get_future();       // 从 promise 获取对应的 future 对象
  assert(f.valid());                         // 1. future 对象 f 是有效的（合法的）

  std::shared_future<int> sf(std::move(f));  // 将 future f 移动构造为 shared_future sf，转移所有权
  assert(!f.valid());                        // 2. 原 future f 已被移动，变为无效（不合法）
  assert(sf.valid());                        // 3. shared_future sf 现在是有效的，拥有原来的同步状态

  return 0;
}
```

也可以直接从 promise 获取 `shared_future`：

```cpp
std::promise<std::string> p;
std::shared_future<std::string> sf(p.get_future());
```

或者用 `future` 的 `share()` 成员函数：

```cpp
auto sf = p.get_future().share();
```

这种方式方便在多个线程中共享复杂类型结果，如下例：

```cpp
std::promise<std::map<SomeIndexType, SomeDataType, SomeComparator, SomeAllocator>::iterator> p;
auto sf = p.get_future().share();
```

### 总结

- `std::future` 和 `std::async` 实现异步计算和等待结果。
- `std::packaged_task` 将任务和 `future` 绑定，适合任务队列和线程池。
- `std::promise` 用于手动设置异步结果，适合网络等事件驱动的异步场景。
- 异常可以被存储到 `future` 中，调用 `get()` 时重新抛出。
- 多线程共享异步结果使用 `std::shared_future`，避免数据竞争。