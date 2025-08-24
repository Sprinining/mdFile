## C++ 信号处理

C++ 中的信号处理（signal handling）指的是程序在运行过程中响应特定异步事件（通常由操作系统发送的信号）的能力。信号机制在 UNIX/Linux 系统中较常见，主要用于处理诸如中断、终止、算术错误、非法访问等异常事件。

### 信号

信号是一种**异步通信机制**，由操作系统发送给进程，以通知发生了某种事件。每种信号都有一个编号和名称，例如：

| 信号名称 | 编号 | 含义                     |
| -------- | ---- | ------------------------ |
| SIGINT   | 2    | 中断信号（如 Ctrl+C）    |
| SIGTERM  | 15   | 请求终止进程             |
| SIGSEGV  | 11   | 段错误，非法内存访问     |
| SIGFPE   | 8    | 浮点异常（如除0）        |
| SIGKILL  | 9    | 强制终止进程（不可捕获） |
| SIGABRT  | 6    | 程序异常终止（abort）    |

### 信号处理 API

C++ 使用 C 标准库中的 `<csignal>`（C 中为 `<signal.h>`）来处理信号。

#### 基本函数：signal

```cpp
#include <csignal>
#include <iostream>

void signalHandler(int signal) {
    std::cout << "Caught signal " << signal << std::endl;
    exit(signal);
}

int main() {
    signal(SIGINT, signalHandler);  // 捕获 Ctrl+C
    while (true) {
        std::cout << "Running...\n";
        sleep(1);
    }
}
```

#### 函数签名

```cpp
typedef void (*sighandler_t)(int);
sighandler_t signal(int signum, sighandler_t handler);
```

#### 特殊处理器

- `SIG_DFL`：默认处理方式。
- `SIG_IGN`：忽略信号。

例如：

```cpp
signal(SIGINT, SIG_IGN); // 忽略 Ctrl+C
```

### 信号处理函数注意事项

信号处理函数是异步调用的，可能随时打断程序执行。

- **异步调用**

  - 异步 = 不按照程序主流程顺序执行。

  - 例如，程序正在执行 `x = a + b;`，操作系统可能突然触发一个信号，然后暂停主程序，先执行信号处理函数。

- **随时打断**

  - 信号处理函数可以在任何指令中间被调用，程序不知道何时会被打断。

  - 因此，如果信号处理函数里调用了非安全操作（如 `malloc`、`printf`、加锁等），就可能破坏正在执行的代码状态，导致崩溃或死锁。

#### 可以安全执行的操作

- 修改全局或 `volatile sig_atomic_t` 变量
- 调用**异步信号安全函数**（async-signal-safe），如 `write`、`_exit`

#### 不安全的操作

##### `printf` / `fprintf`

- 这些函数使用 **内部缓冲区**（例如 `stdout` 缓冲）。
- 如果主程序正好在刷新或写入缓冲区时被信号打断，再调用 `printf`，缓冲区可能处于不一致状态。
- 可能导致输出错乱或程序崩溃。

##### `malloc` / `free` / `new` / `delete`

- 内存分配函数内部通常使用全局堆管理结构（如 free list）。
- 信号打断时，如果正在操作堆结构，再调用 `malloc`/`free`，可能破坏堆链表或分配状态，导致崩溃或内存泄漏。

##### 文件 I/O (`fopen` / `fclose` / `fwrite`)

- 标准库文件操作通常会加锁以保证多线程安全。
- 信号中断时，如果线程持有锁，信号处理函数又尝试获取同一锁，就会死锁。

##### 加锁操作（mutex、spinlock 等）

- 信号可能在主线程持有锁时打断，如果信号处理函数再次尝试加锁，程序会死锁。

##### 其他可能阻塞的系统调用

- 如 `read`、`wait` 等，如果信号打断它们，可能导致未定义行为或阻塞不释放。

#### 安全实践

- 在信号处理函数中只设置标志位
- 在主循环或程序正常流程中检查标志并执行具体处理

```cpp
#include <csignal>    // 信号处理相关函数和宏（如 SIGINT、signal）
#include <atomic>     // 原子类型，用于线程/信号安全的标志变量
#include <iostream>   // 输入输出流
#include <unistd.h>   // sleep 函数

// 使用原子布尔变量作为信号标志，保证信号处理函数中修改安全
std::atomic<bool> stopFlag(false);

// 信号处理函数，当接收到 SIGINT（Ctrl+C）时触发
void handler(int signum) {
    stopFlag = true; // 仅设置标志位，避免在信号处理函数中执行不安全操作
}

int main() {
    // 注册信号处理函数，捕获 SIGINT
    signal(SIGINT, handler);

    // 主循环，持续工作直到收到信号
    while (!stopFlag) {
        std::cout << "Working...\n"; // 输出工作状态（非信号处理函数中安全）
        sleep(1);                     // 暂停 1 秒，模拟工作间隔
    }

    // 当 stopFlag 被设置为 true，跳出循环
    std::cout << "Exiting gracefully\n"; // 优雅退出提示

    return 0;
}
```

- **信号处理函数必须只执行原子性操作或 async-signal-safe 函数**。
- 不保证原子性的操作、使用共享资源或可能阻塞的系统调用都是 **异步不安全** 的。

### sigaction

`signal` 有实现差异且不支持重入保护等特性，更推荐使用 `sigaction`：

```cpp
#include <csignal>   // 信号处理相关头文件（sigaction, SIGINT 等）
#include <iostream>  // 输入输出流
#include <unistd.h>  // sleep 函数

// 信号处理函数，当接收到指定信号时调用
void handler(int signo) {
    // 注意：cout 在信号处理函数中不安全，仅用于演示
    std::cout << "Signal " << signo << " caught\n";
}

int main() {
    struct sigaction sa;          // sigaction 结构体，用于定义信号行为

    sa.sa_handler = handler;      // 指定信号处理函数
    sigemptyset(&sa.sa_mask);     // 处理期间不屏蔽其他信号（空集）
    sa.sa_flags = 0;              // 默认行为（没有 SA_RESTART 或其他标志）

    // 注册信号处理函数，用于捕获 SIGINT（Ctrl+C）
    sigaction(SIGINT, &sa, nullptr);

    // 主循环，模拟程序持续运行
    while (true) {
        std::cout << "Running...\n";  // 输出运行状态
        sleep(1);                     // 暂停 1 秒，模拟工作
    }

    return 0;
}
```

对比：

| 特性       | `signal`                                         | `sigaction`                                            |
| ---------- | ------------------------------------------------ | ------------------------------------------------------ |
| 灵活性     | 功能有限，只能简单注册处理函数                   | 可以精细控制信号行为（信号屏蔽、标志等）               |
| 行为一致性 | 不同系统/编译器实现可能不完全一致                | 标准化、跨平台行为更一致                               |
| 信号屏蔽   | 不能控制信号屏蔽                                 | 可以设置处理信号时临时屏蔽其他信号                     |
| 重新安装   | 某些系统中处理函数会被恢复默认（信号处理仅一次） | 处理函数安装后不会被重置                               |
| 支持的标志 | 无                                               | 可以设置多个标志（例如 `SA_RESTART` 自动重启系统调用） |
| 安全性     | 有些实现中信号处理期间可能被其他信号打断         | 支持信号掩码，处理过程更安全                           |

### 常见用途

#### 程序终止控制

- 捕获 `SIGINT`（Ctrl+C）、`SIGTERM` 等，优雅关闭程序。
- 做法：在信号处理函数中设置标志位，主循环检测后释放资源、保存状态。

```cpp
volatile sig_atomic_t stopFlag = 0;

void handler(int) { stopFlag = 1; }

while (!stopFlag) { /* 程序工作 */ }
```

#### 定时任务 / 闹钟

- 使用 `SIGALRM` 配合 `alarm()` 定时触发信号。
- 常用于定时轮询、超时控制。

```cpp
void alarmHandler(int) { /* 执行定时任务 */ }
alarm(5); // 5 秒后触发 SIGALRM
```

#### 子进程状态监控

- 捕获 `SIGCHLD` 信号，检测子进程退出或异常。
- 避免僵尸进程，及时回收子进程资源。

```cpp
void childHandler(int) { waitpid(-1, nullptr, WNOHANG); }
```

#### 异步 I/O / 外部事件

- 捕获硬件中断或系统信号（如网络或文件事件）。
- 在信号里仅设置标志位或调用 async-signal-safe 函数，主循环处理具体逻辑。

#### 调试与日志

- 捕获 `SIGSEGV`、`SIGFPE` 等异常信号，打印简单信息或写入日志（仅 async-signal-safe 操作）。
- 辅助排查程序崩溃原因。

### 信号 vs 异常 vs 中断

| 项目     | 信号          | C++ 异常       | 硬件中断     |
| -------- | ------------- | -------------- | ------------ |
| 类型     | OS 级事件     | 编译期语言特性 | CPU 层面     |
| 来源     | 内核/外部事件 | 程序代码       | 硬件设备     |
| 响应方式 | 异步触发      | 同步抛出/捕获  | 异步中断处理 |
| 例子     | SIGSEGV       | try-catch      | 鼠标点击     |

