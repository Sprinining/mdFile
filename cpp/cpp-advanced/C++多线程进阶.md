## C++多线程进阶

### 1. 异步任务 `std::async` 和 `std::future`

```cpp
#include <future>
#include <iostream>

int compute() {
    return 123;
}

int main() {
    auto fut = std::async(std::launch::async, compute);
    std::cout << "Result = " << fut.get() << std::endl;  // 阻塞直到返回
}
```

- `std::async` 可自动创建线程执行任务。

- `std::future` 用于获取异步任务返回值。

### 2. 原子操作 (`std::atomic`)

```cpp
#include <atomic>
#include <thread>
#include <vector>
#include <iostream>

std::atomic<int> atomicCounter(0);

void atomicIncrement() {
    for (int i = 0; i < 1000; ++i) {
        atomicCounter.fetch_add(1, std::memory_order_relaxed);
    }
}

int main() {
    std::vector<std::thread> threads;
    for(int i = 0; i < 10; ++i)
        threads.emplace_back(atomicIncrement);
    for(auto& t : threads)
        t.join();

    std::cout << "atomicCounter = " << atomicCounter.load() << std::endl;  // 10000
}
```

- `std::atomic` 提供无锁线程安全的变量操作。

- 避免使用mutex带来的开销。

### 3. C++ 内存模型简介

C++11引入了内存模型，定义了多线程环境下变量访问的顺序和可见性。

`std::memory_order` 枚举定义了不同内存序：

- `memory_order_relaxed`：不保证顺序，仅保证原子性。
- `memory_order_acquire` / `memory_order_release`：用于同步操作。
- `memory_order_seq_cst`：默认严格顺序保证。

了解内存模型对写高性能多线程程序至关重要。

### 4. 线程池与实践技巧

#### 4.1 简易线程池示例

线程池能避免频繁创建销毁线程，提高性能。

```cpp
#include <iostream>
#include <vector>
#include <thread>
#include <queue>
#include <mutex>
#include <condition_variable>
#include <functional>
#include <future>
#include <atomic>

// 简易线程池实现
class ThreadPool {
public:
    // 构造函数，初始化线程池并启动 n 个工作线程
    ThreadPool(size_t n) : stop(false) {
        for (size_t i = 0; i < n; ++i) {
            // 每个线程运行一个死循环任务
            workers.emplace_back([this] {
                while (true) {
                    std::function<void()> task;

                    {
                        std::unique_lock<std::mutex> lock(this->queueMutex);
                        // 等待任务队列非空或者线程池关闭
                        this->condition.wait(lock, [this] { return stop || !tasks.empty(); });

                        // 如果线程池已关闭且任务队列为空，则退出线程
                        if (stop && tasks.empty()) return;

                        // 从队列中取出一个任务
                        task = std::move(tasks.front());
                        tasks.pop();
                    }

                    // 执行任务
                    task();
                }
            });
        }
    }

    // 将任务添加到线程池中，支持任意可调用对象（函数、lambda、bind 等）
    template<class F, class... Args>
    auto enqueue(F&& f, Args&&... args)
        -> std::future<typename std::invoke_result_t<F, Args...>> {
        
        using return_type = typename std::invoke_result_t<F, Args...>;

        // 把传入的函数和参数绑定成一个 packaged_task，可以异步执行
        auto task = std::make_shared<std::packaged_task<return_type()>>(
            std::bind(std::forward<F>(f), std::forward<Args>(args)...)
        );

        std::future<return_type> res = task->get_future(); // 获取返回结果的 future

        {
            std::unique_lock<std::mutex> lock(queueMutex);

            // 如果线程池已经停止，则抛出异常
            if (stop)
                throw std::runtime_error("enqueue on stopped ThreadPool");

            // 将任务加入队列，任务是一个无参 lambda，调用 packaged_task
            tasks.emplace([task]() { (*task)(); });
        }

        // 通知一个等待线程有新任务
        condition.notify_one();
        return res;
    }

    // 析构函数，停止线程池并等待所有线程退出
    ~ThreadPool() {
        {
            std::unique_lock<std::mutex> lock(queueMutex);
            stop = true; // 设置停止标志
        }

        // 通知所有线程退出等待
        condition.notify_all();

        // 等待所有线程退出
        for (std::thread &worker : workers)
            worker.join();
    }

private:
    std::vector<std::thread> workers;                   // 工作线程集合
    std::queue<std::function<void()>> tasks;            // 任务队列

    std::mutex queueMutex;                              // 任务队列互斥锁
    std::condition_variable condition;                  // 条件变量用于任务唤醒
    bool stop;                                          // 是否停止线程池标志
};

int main() {
    ThreadPool pool(4); // 创建一个含有 4 个工作线程的线程池

    // 提交一个任务到线程池，计算 5 + 3，返回 future
    auto f1 = pool.enqueue([](int a, int b) { return a + b; }, 5, 3);

    // 从 future 中获取结果（阻塞直到任务完成）
    std::cout << "5 + 3 = " << f1.get() << std::endl;

    return 0;
}
```

- 线程池维护固定数量线程，任务放入队列等待执行。

- 线程池支持任务返回值，自动管理线程生命周期。

#### 4.2 实践技巧

- **避免竞态条件**：尽量减少共享数据，使用锁或原子操作。
- **死锁预防**：避免多把锁顺序不一致，考虑用 `std::lock()` 批量锁定。
- **锁粒度**：尽量缩小锁范围，避免影响性能。
- **线程安全容器**：标准库没有线程安全容器，使用时需自行加锁。
- **避免长时间持锁**，防止阻塞其他线程。
- **合理选择同步机制**，避免忙等待（spinlock）等。

