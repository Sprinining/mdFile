## C++信号处理

C++ 中的信号处理（signal handling）指的是程序在运行过程中响应特定异步事件（通常由操作系统发送的信号）的能力。信号机制在 UNIX/Linux 系统中较常见，主要用于处理诸如中断、终止、算术错误、非法访问等异常事件。

### 信号的基本概念

信号是一种**异步通信机制**，由操作系统发送给进程，以通知发生了某种事件。每种信号都有一个编号和名称，例如：

| 信号名称 | 编号 | 含义                     |
| -------- | ---- | ------------------------ |
| SIGINT   | 2    | 中断信号（如 Ctrl+C）    |
| SIGTERM  | 15   | 请求终止进程             |
| SIGSEGV  | 11   | 段错误，非法内存访问     |
| SIGFPE   | 8    | 浮点异常（如除0）        |
| SIGKILL  | 9    | 强制终止进程（不可捕获） |
| SIGABRT  | 6    | 程序异常终止（abort）    |

### C++ 中的信号处理 API

C++ 使用 C 标准库中的 `<csignal>`（C 中为 `<signal.h>`）来处理信号。

#### 基本函数：`signal`

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

在信号处理函数中**必须非常小心**，因为它是**异步调用的**，所以：

#### 可以做的事情：

- 设置全局变量
- 调用 `write`、`_exit` 等**异步信号安全（async-signal-safe）**的函数

#### 不安全的操作：

- 使用 `printf`（可能是线程不安全的）
- 使用 malloc、new、文件 I/O、lock、其他可能阻塞的系统调用

因此，更安全的做法是：

- 设置标志变量，在主循环中检查它并做后续处理

```cpp
#include <csignal>
#include <atomic>
#include <iostream>
#include <unistd.h>

std::atomic<bool> stopFlag(false);

void handler(int signum) {
    stopFlag = true;
}

int main() {
    signal(SIGINT, handler);
    while (!stopFlag) {
        std::cout << "Working...\n";
        sleep(1);
    }
    std::cout << "Exiting gracefully\n";
}
```

### 更强大的 signal 替代：`sigaction`

`signal` 有实现差异且不支持重入保护等特性，更推荐使用：

```cpp
#include <csignal>
#include <iostream>
#include <unistd.h>

void handler(int signo) {
    std::cout << "Signal " << signo << " caught\n";
}

int main() {
    struct sigaction sa;
    sa.sa_handler = handler;
    sigemptyset(&sa.sa_mask); // 处理期间不屏蔽信号
    sa.sa_flags = 0;          // 默认行为

    sigaction(SIGINT, &sa, nullptr);
    while (true) {
        std::cout << "Running...\n";
        sleep(1);
    }
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

- **优雅退出**（处理 `SIGINT`）
- **热重启配置**（例如处理 `SIGHUP`）
- **崩溃调试**（处理 `SIGSEGV`，记录日志）
- **定时器机制**（如 `SIGALRM`）

### 信号 vs 异常 vs 中断

| 项目     | 信号          | C++ 异常       | 硬件中断     |
| -------- | ------------- | -------------- | ------------ |
| 类型     | OS 级事件     | 编译期语言特性 | CPU 层面     |
| 来源     | 内核/外部事件 | 程序代码       | 硬件设备     |
| 响应方式 | 异步触发      | 同步抛出/捕获  | 异步中断处理 |
| 例子     | SIGSEGV       | try-catch      | 鼠标点击     |

### 补充：线程与信号

- 默认情况下，信号发送给进程，内核会选择一个线程来处理。
- 使用 `pthread_sigmask` 可设置线程屏蔽信号。
- 使用 `sigwait()` 系列函数可同步等待信号（适合多线程）。