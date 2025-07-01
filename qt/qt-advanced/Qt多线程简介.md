## Qt多线程简介

Qt 多线程编程是 Qt 框架中非常重要的一部分，适用于需要在后台处理耗时任务而不阻塞主线程（UI线程）的应用场景。

### Qt 多线程的几种方式

| 方法   | 类名                      | 场景                             | 描述                                                         |
| ------ | ------------------------- | -------------------------------- | ------------------------------------------------------------ |
| 方式一 | `QThread` 子类化          | 学习演示                         | 继承 `QThread` 并重写 `run()` 方法，手动启动线程             |
| 方式二 | `QObject`+ `moveToThread` | 持续性工作对象（如网络、串口等） | 将一个工作对象移到子线程中执行，推荐方式                     |
| 方式三 | `QtConcurrent`            | 一次性任务（图像处理等）         | 使用并行算法自动管理线程（C++11/QtConcurrent），适合任务并行 |
| 方式四 | `QThreadPool + QRunnable` | CPU 密集型、任务多               | 用线程池管理任务，适合大量短小任务                           |

### 推荐方式：QObject + moveToThread（线程内处理，线程间通信）

- 清晰分离 UI 和工作逻辑
- 信号槽支持线程间通信（自动跨线程队列）
- 可复用性高，结构清晰

#### Worker 类（处理任务）

```cpp
// worker.h
#ifndef WORKER_H
#define WORKER_H

#include <QObject>

// Worker 类用于在子线程中执行耗时任务
// 继承自 QObject，以支持 Qt 的信号与槽机制
class Worker : public QObject {
    Q_OBJECT

  public:
    // 构造函数，parent 默认为 nullptr
    explicit Worker(QObject* parent = nullptr);

  public slots:
    // 执行具体任务的槽函数
    // 例如计算斐波那契数列的第 n 项
    void doWork(int n);

  signals:
    // 任务完成后发出的信号，携带计算结果
    // 通常连接主线程的槽函数以更新 UI
    void resultReady(long long result);
};

#endif // WORKER_H
```

```cpp
// worker.cpp
#include "worker.h"

// 构造函数，调用基类 QObject 构造函数
Worker::Worker(QObject* parent) : QObject(parent) {
}

// 执行耗时任务的槽函数，例如计算斐波那契数列的第 n 项
void Worker::doWork(int n) {
    // 使用递归 lambda 计算斐波那契数列
    // 这里采用简单递归，模拟耗时操作
    std::function<long long(int)> fib = [&](int x) {
        if (x <= 1) return 1LL;
        return fib(x - 1) + fib(x - 2);
    };

    long long result = fib(n);

    // 任务完成，发射信号通知结果
    emit resultReady(result);
}
```

#### 主窗口代码

```cpp
// widget.h
#ifndef WIDGET_H
#define WIDGET_H

#include "worker.h"
#include <QLabel>
#include <QThread>
#include <QWidget>

// Qt 命名空间宏，兼容自动生成的 UI 代码
QT_BEGIN_NAMESPACE
namespace Ui {
class Widget;
}
QT_END_NAMESPACE

// Widget 类，主界面窗口，负责 UI 和启动子线程工作
class Widget : public QWidget {
    Q_OBJECT

  public:
    // 构造函数，默认父对象为 nullptr
    Widget(QWidget* parent = nullptr);

    // 析构函数，负责资源清理
    ~Widget();

  private slots:
    // 按钮点击槽函数，启动耗时任务
    void onButtonClicked();

    // 接收 Worker 返回结果，更新界面
    void handleResult(long long);

  private:
    Ui::Widget* ui;        // UI 界面指针（由 Qt Designer 生成）
    Worker* worker;        // 子线程中执行任务的 Worker 对象
    QThread* workerThread; // 运行 Worker 的线程
    QLabel* label;         // 用于显示任务结果的标签控件

  signals:
    // 自定义信号，通知子线程开始执行任务
    void startWorkInThread(int n);
};

#endif // WIDGET_H

```

```cpp
// widget.cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QLabel>
#include <QPushButton>
#include <QVBoxLayout>

// 构造函数，创建 UI 组件，初始化线程和 Worker 对象，连接信号槽
Widget::Widget(QWidget* parent) {
    // 创建一个按钮，点击时触发计算任务
    auto* btn = new QPushButton("计算 Fib(35)");
    // 显示结果或状态的标签
    label = new QLabel("等待中...");
    // 垂直布局，按钮和标签依次排列
    auto* layout = new QVBoxLayout;
    layout->addWidget(btn);
    layout->addWidget(label);
    // 设置 Widget 的布局为上述创建的布局
    setLayout(layout);

    // 创建新的线程，传入 this 作为父对象，方便资源管理
    workerThread = new QThread(this);
    // 创建 Worker 对象，负责执行耗时任务
    worker = new Worker();
    // 将 Worker 对象移动到子线程中执行
    worker->moveToThread(workerThread);

    // 启动线程
    workerThread->start();

    // 连接按钮点击信号到本类槽函数，响应用户操作
    connect(btn, &QPushButton::clicked, this, &Widget::onButtonClicked);
    // 连接自定义信号，触发 Worker 在子线程执行任务
    connect(this, &Widget::startWorkInThread, worker, &Worker::doWork);
    // 连接 Worker 完成任务信号，更新主线程 UI 显示结果
    connect(worker, &Worker::resultReady, this, &Widget::handleResult);

    // 线程结束时，自动释放 Worker 对象资源
    connect(workerThread, &QThread::finished, worker, &QObject::deleteLater);
    // 当 Widget 被销毁时，通知线程退出
    connect(this, &Widget::destroyed, workerThread, &QThread::quit);
    // 线程结束时自动释放线程对象资源
    connect(workerThread, &QThread::finished, workerThread, &QObject::deleteLater);
}

// 析构函数，关闭线程并等待线程退出，释放 ui 资源
Widget::~Widget() {
    workerThread->quit(); // 通知线程退出事件循环
    workerThread->wait(); // 阻塞等待线程退出
    delete ui;            // 删除 UI 界面指针（如果有使用 ui 文件）
}

// 按钮点击槽函数，更新状态显示，并发射信号通知子线程开始工作
void Widget::onButtonClicked() {
    label->setText("计算中...");
    emit startWorkInThread(35); // 启动计算 Fib(35) 的任务
}

// 接收子线程计算完成信号，更新标签显示结果
void Widget::handleResult(long long result) {
    label->setText(QString("结果: %1").arg(result));
}
```

```cpp
// main.cpp
#include "widget.h"

#include <QApplication>

int main(int argc, char* argv[]) {
    QApplication a(argc, argv);
    Widget w;
    w.show();
    return a.exec();
}
```

- 不要在子线程直接操作 UI，必须用信号把数据发回主线程。
- 子线程的生命周期注意管理（`QObject::deleteLater()` + `QThread::quit()` + `wait()`）。

### QThread 子类法（不推荐）

#### WorkerThread 类

```cpp
// workerthread.h
#ifndef WORKERTHREAD_H
#define WORKERTHREAD_H

#include <QDebug>
#include <QThread>

class WorkerThread : public QThread {
    Q_OBJECT

  public:
    explicit WorkerThread(int n, QObject* parent = nullptr);
    void run() override;

  signals:
    void resultReady(long long result);

  private:
    int m_n;
};

#endif // WORKERTHREAD_H
```

```cpp
// workerthread.cpp
#include "workerthread.h"
#include <functional>

WorkerThread::WorkerThread(int n, QObject* parent) : QThread(parent), m_n(n) {
}

void WorkerThread::run() {
    std::function<long long(int)> fib = [&](int x) {
        if (x <= 1) return 1LL;
        return fib(x - 1) + fib(x - 2);
    };

    long long result = fib(m_n);
    emit resultReady(result);
}
```

#### 主窗口代码

```cpp
// widget.h
#ifndef WIDGET_H
#define WIDGET_H

#include "workerthread.h"
#include <QLabel>
#include <QWidget>

class Widget : public QWidget {
    Q_OBJECT

  public:
    explicit Widget(QWidget* parent = nullptr);
    ~Widget();

  private slots:
    void onStartWork();
    void onResultReady(long long result);

  private:
    QLabel* label;
    WorkerThread* workerThread;
};

#endif // WIDGET_H
```

```cpp
// widget.cpp
#include "widget.h"
#include <QPushButton>
#include <QVBoxLayout>

Widget::Widget(QWidget* parent) : QWidget(parent), workerThread(nullptr) {

    auto* btn = new QPushButton("计算 Fib(35)", this);
    label = new QLabel("等待中...", this);

    auto* layout = new QVBoxLayout(this);
    layout->addWidget(btn);
    layout->addWidget(label);

    connect(btn, &QPushButton::clicked, this, &Widget::onStartWork);
}

Widget::~Widget() {
    if (workerThread) {
        workerThread->quit();
        workerThread->wait();
        delete workerThread;
    }
}

void Widget::onStartWork() {
    if (workerThread && workerThread->isRunning()) return;

    label->setText("计算中...");
    workerThread = new WorkerThread(35);

    connect(workerThread, &WorkerThread::resultReady, this, &Widget::onResultReady);
    connect(workerThread, &QThread::finished, workerThread, &QObject::deleteLater);

    workerThread->start();
}

void Widget::onResultReady(long long result) {
    label->setText(QString("结果: %1").arg(result));
}
```

| 缺点类别     | 描述                                   |
| ------------ | -------------------------------------- |
| 设计原则违背 | 工作逻辑与线程控制混合，违背职责分离   |
| 阻碍事件驱动 | 无法使用信号槽跨线程通信机制           |
| 不易扩展维护 | 逻辑固定，无法复用通用工作组件         |
| 错误难排查   | 生命周期混乱时容易崩溃、泄漏或逻辑错乱 |

### QtConcurrent 使用

`QtConcurrent` 是 Qt 提供的一个高级并发编程模块，它封装了多线程机制，让你**像写普通函数一样写并发代码**，无需手动管理 `QThread`、信号槽等底层逻辑，非常适合快速并发处理任务。

#### 常用 API 简介

| 函数                         | 用途说明                           |
| ---------------------------- | ---------------------------------- |
| `QtConcurrent::run()`        | 在后台线程执行一个函数             |
| `QtConcurrent::map()`        | 并发地修改一个容器中的所有元素     |
| `QtConcurrent::filter()`     | 并发地过滤容器中的元素             |
| `QtConcurrent::mapped()`     | 并发地对容器中每个元素应用转换函数 |
| `QFuture` / `QFutureWatcher` | 管理异步任务和回调                 |

#### QtConcurrent::run 示例：后台执行函数并获取结果

- 计算 `fib(40)`，不阻塞 UI，完成后更新界面

```cpp
#include <QApplication>
#include <QPushButton>
#include <QLabel>
#include <QVBoxLayout>
#include <QtConcurrent>

long long fib(int n) {
    if (n <= 1) return 1;
    return fib(n - 1) + fib(n - 2);
}

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    QWidget window;
    QPushButton *button = new QPushButton("计算 Fib(40)");
    QLabel *label = new QLabel("准备就绪");
    QVBoxLayout *layout = new QVBoxLayout(&window);
    layout->addWidget(button);
    layout->addWidget(label);

    QObject::connect(button, &QPushButton::clicked, [&]() {
        label->setText("计算中...");

        // 使用 QFutureWatcher 跟踪任务完成状态
        QFutureWatcher<long long> *watcher = new QFutureWatcher<long long>();

        // 任务完成后自动回调，更新 UI
        QObject::connect(watcher, &QFutureWatcher<long long>::finished, [=]() {
            long long result = watcher->result();
            label->setText(QString("结果：%1").arg(result));
            watcher->deleteLater();
        });

        // 启动后台任务
        QFuture<long long> future = QtConcurrent::run(fib, 40);
        watcher->setFuture(future);
    });

    window.show();
    return app.exec();
}
```

#### QtConcurrent::map 示例：并行修改容器元素

- 将一个字符串列表的所有字符串改为大写

```cpp
#include <QtConcurrent>
#include <QStringList>
#include <QDebug>

void toUpper(QString &str) {
    str = str.toUpper();
}

int main() {
    QStringList list = {"hello", "world", "qt", "concurrent"};

    QtConcurrent::map(list, toUpper);  // 并行处理每个元素

    // 等待任务完成（可选）
    // QFuture<void> future = QtConcurrent::map(list, toUpper);
    // future.waitForFinished();

    qDebug() << list;  // 输出: "HELLO" "WORLD" "QT" "CONCURRENT"
    return 0;
}
```

#### QtConcurrent::mapped 示例：并行生成新容器

```cpp
QString doubleStr(const QString &s) {
    return s + s;
}

QStringList list = {"a", "b", "c"};

QFuture<QString> future = QtConcurrent::mapped(list, doubleStr);
future.waitForFinished();

QStringList result = future.results();  // ["aa", "bb", "cc"]
```

#### QFuture vs QFutureWatcher 区别

| 类名             | 功能说明                                                     |
| ---------------- | ------------------------------------------------------------ |
| `QFuture<T>`     | 表示一个异步任务，可以 `result()`、`wait()`                  |
| `QFutureWatcher` | 提供信号（如 `finished`、`progressValueChanged`）用于主线程响应异步事件 |

#### 特点总结

优点

- 简洁：像写普通函数一样写并发
- 自动线程池：不用管理 `QThread`
- 安全：线程结果通过 `QFutureWatcher` 回调处理，不阻塞主线程
- 并发处理容器：非常适合 `list/map` 等并行计算

注意事项

- 不适用于需要事件循环的线程（例如串口、Socket）
- 不适合长期驻留线程，只适合短时间任务
- 调试困难，不易中断任务
- QtConcurrent 默认使用 `QThreadPool`，受其线程数上限限制（可调）

### QThreadPool + QRunnable

`QThreadPool + QRunnable` 提供了一种**高性能、轻量级、适合大量短任务**的线程池机制，不需要显式管理线程对象，适合做：图像处理、任务队列执行、批量 I/O 等。

#### 工作原理

- **`QThreadPool`** 是一个线程池管理类，系统自动复用线程资源，避免频繁创建/销毁线程的性能开销。
- **`QRunnable`** 是一个接口类，你继承它并重写 `run()` 方法来定义任务逻辑。
- 使用方式类似 Java 的 `ExecutorService + Runnable`。

#### 使用步骤

1. 创建一个继承自 `QRunnable` 的任务类

2. 重写 `run()`，写入你要在线程中执行的逻辑

3. 将任务对象交给线程池执行：`QThreadPool::globalInstance()->start(task)`

#### 示例

```cpp
// MyTask.h
#ifndef MYTASK_H
#define MYTASK_H

#include <QRunnable>
#include <QObject>
#include <functional>

// QRunnable 不能发信号，但我们可以包装一个 QObject 作为信号中介
class MyTask : public QObject, public QRunnable {
    Q_OBJECT

public:
    explicit MyTask(int n);
    void run() override;  // 重写线程执行体

signals:
    void resultReady(long long result);

private:
    int m_n;
};

#endif // MYTASK_H
```

```cpp
// MyTask.cpp
#include "MyTask.h"

MyTask::MyTask(int n) : m_n(n) {
    // 设置为自动删除，任务完成后自动释放内存
    setAutoDelete(true);
}

void MyTask::run() {
    // 递归计算斐波那契数列（模拟耗时任务）
    std::function<long long(int)> fib = [&](int x) {
        if (x <= 1) return 1LL;
        return fib(x - 1) + fib(x - 2);
    };

    long long result = fib(m_n);

    // QRunnable 没有事件循环，因此 emit 的槽要连接到主线程
    emit resultReady(result);
}
```

```cpp
// widget.cpp
#include "MyTask.h"
#include <QWidget>
#include <QPushButton>
#include <QLabel>
#include <QVBoxLayout>
#include <QThreadPool>

class Widget : public QWidget {
    Q_OBJECT

public:
    Widget() {
        auto *btn = new QPushButton("计算 Fib(35)", this);
        label = new QLabel("准备就绪", this);
        auto *layout = new QVBoxLayout(this);
        layout->addWidget(btn);
        layout->addWidget(label);

        connect(btn, &QPushButton::clicked, this, &Widget::onStartTask);
    }

private slots:
    void onStartTask() {
        label->setText("计算中...");

        auto *task = new MyTask(35);

        // 连接结果信号（QRunnable 任务中的信号），注意：必须是跨线程队列连接
        connect(task, &MyTask::resultReady, this, [=](long long result) {
            label->setText(QString("结果：%1").arg(result));
        });

        // 交由线程池执行任务
        QThreadPool::globalInstance()->start(task);
    }

private:
    QLabel *label;
};
```

#### 特点总结

优点

- 不需要手动管理 `QThread`
- 重复创建/销毁任务时性能高，线程会复用
- 适合大量短小任务并发执行
- `setAutoDelete(true)` 后任务完成自动释放资源

注意事项

- `QRunnable` **不是 `QObject`**，默认不支持信号槽，需要混合继承 `QObject` 或使用外部回调
- 无事件循环，不能用 `QTimer`、`event loop` 等功能
- 如果你的任务需要长期驻留线程，建议使用 `QObject + moveToThread`
- 默认线程池大小是 `QThread::idealThreadCount()`（可通过 `setMaxThreadCount()` 修改）