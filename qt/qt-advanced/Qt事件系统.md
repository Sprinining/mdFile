## Qt 事件系统

Qt 的事件系统是一个**事件驱动架构**，它让程序能够响应用户操作（鼠标、键盘等）、系统消息（窗口调整、定时器）、以及自定义事件。所有事件都被封装为 `QEvent` 对象，通过事件循环分发给对应的 `QObject`（尤其是 `QWidget`）处理。

### 事件系统的核心类和概念

| 类 / 概念                                         | 作用简介                                                     |
| ------------------------------------------------- | ------------------------------------------------------------ |
| **QEvent**                                        | 所有事件的基类，封装事件类型和状态信息。                     |
| **QObject::event()**                              | 事件的统一入口函数，根据事件类型调用具体事件处理函数。       |
| **QCoreApplication**                              | 提供事件分发入口，管理事件队列，主事件循环入口（`exec()`）。 |
| **QEventLoop**                                    | 事件循环实现，负责不断处理事件队列。                         |
| **QObject::installEventFilter() / eventFilter()** | 实现事件过滤器机制，拦截监听目标对象的事件。                 |
| **QWidget**                                       | 继承自 QObject，重写了事件函数，处理 GUI 相关事件。          |

### 事件的产生与分发流程

```css
[用户操作/系统消息]
          ↓
[Qt 平台封装成 QEvent]
          ↓
[放入事件队列 (postEvent) 或 立即派发 (sendEvent)]
          ↓
[QEventLoop 从队列取出事件]
          ↓
[QCoreApplication::notify() 派发事件]
          ↓
[调用目标 QObject::event()]
          ↓
[调用具体事件处理函数（如 mousePressEvent()）]
```

### 关键类详解

#### QEvent

- 所有事件的基类。
- 定义了 `Type` 枚举，表示事件类型，比如鼠标事件、键盘事件、定时器事件、绘图事件等。
- 支持事件“接受/忽略”机制，控制事件是否继续传递。

```cpp
void QEvent::accept();   // 标记事件已处理
void QEvent::ignore();   // 标记事件未处理
bool QEvent::isAccepted() const;
```

#### QObject::event(QEvent *event)

- 事件处理的统一入口。
- 默认实现根据事件类型调用对应的虚函数，如 `mousePressEvent()`, `keyPressEvent()`。
- 可重写此函数实现自定义事件处理逻辑。

```cpp
bool MyWidget::event(QEvent *event) override {
    if (event->type() == QEvent::KeyPress) {
        // 自定义键盘事件处理
        return true;
    }
    return QWidget::event(event);  // 调用父类默认处理
}
```

#### QCoreApplication 和 QApplication

- `QCoreApplication` 是事件系统的顶层管理者，负责管理事件队列，事件派发。
- `QApplication` 继承自 `QCoreApplication`，用于 GUI 程序。
- 事件循环由 `exec()` 启动，进入事件循环阻塞等待事件。

```cpp
int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    MainWindow w;
    w.show();
    return app.exec();  // 启动事件循环
}
```

#### QEventLoop

- 事件循环的实际执行者，管理事件队列的不断处理。
- 你可以创建自己的事件循环（模态对话框、异步等待等）。
- 常用方法：

```cpp
QEventLoop loop;
loop.exec();   // 启动事件循环（阻塞）
loop.exit();   // 退出事件循环
```

#### 事件过滤器（Event Filter）

- 允许一个对象监听和拦截另一个对象的事件。
- 通过 `installEventFilter()` 安装。
- 通过重写 `eventFilter()` 实现事件拦截与处理。

```cpp
class MyFilter : public QObject {
protected:
    bool eventFilter(QObject *watched, QEvent *event) override {
        if (event->type() == QEvent::MouseButtonPress) {
            qDebug() << "Mouse pressed on" << watched;
            return true;  // 拦截事件
        }
        return QObject::eventFilter(watched, event); // 继续传递
    }
};

// 使用
button->installEventFilter(new MyFilter(button));
```

### 完整示例

```cpp
#include <QApplication>
#include <QPushButton>
#include <QEvent>
#include <QDebug>
#include <QEventLoop>

class MyFilter : public QObject {
    Q_OBJECT
public:
    explicit MyFilter(QObject *parent = nullptr) : QObject(parent) {}

protected:
    bool eventFilter(QObject *watched, QEvent *event) override {
        if (event->type() == QEvent::MouseButtonPress) {
            qDebug() << "MyFilter: Mouse pressed on" << watched;
            return true;  // 拦截事件
        }
        return QObject::eventFilter(watched, event);
    }
};

class MyButton : public QPushButton {
    Q_OBJECT
public:
    explicit MyButton(const QString &text, QWidget *parent = nullptr) : QPushButton(text, parent) {}

protected:
    void mousePressEvent(QMouseEvent *event) override {
        qDebug() << "MyButton: mousePressEvent";
        QPushButton::mousePressEvent(event);
    }

    bool event(QEvent *event) override {
        if (event->type() == QEvent::KeyPress) {
            qDebug() << "MyButton: key press event";
            return true;  // 处理键盘事件
        }
        return QPushButton::event(event);
    }
};

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    MyButton button("Click me");
    MyFilter filter;
    button.installEventFilter(&filter);

    button.show();

    // 演示自定义事件循环
    QEventLoop loop;
    QTimer::singleShot(3000, &loop, &QEventLoop::quit); // 3秒后退出循环
    qDebug() << "Starting local event loop for 3 seconds...";
    loop.exec();
    qDebug() << "Local event loop exited.";

    return app.exec();
}
```

### 对比信号槽机制

| 维度         | Qt 事件机制                                  | Qt 信号槽机制                             |
| ------------ | -------------------------------------------- | ----------------------------------------- |
| 本质         | 面向对象的**事件传递系统**（继承 + 虚函数）  | 面向对象的**观察者通信机制**（发布/订阅） |
| 触发方式     | 由系统或框架触发（系统、窗口、输入等）       | 通常由程序员手动触发                      |
| 定义方式     | 重写虚函数 `event()`, `mousePressEvent()` 等 | 定义 `signals:` 和 `slots:`               |
| 执行顺序     | Qt 自己维护（事件循环）                      | 自己定义信号-槽连接关系                   |
| 是否自动传递 | 有完整分发机制（事件过滤器/事件传递）        | 不会自动分发，需手动 connect              |
| 用途         | **响应用户或系统事件**（GUI核心）            | **模块间通信、解耦**                      |
| 可跨线程     | 是（事件队列支持跨线程 postEvent）           | 是（支持 `Qt::QueuedConnection`）         |
| 概念来源     | 类似操作系统消息机制（如 Win32 消息队列）    | 来自观察者设计模式                        |

#### 事件机制：系统控制流程

- 是 Qt 用于实现 GUI 控件响应的基础机制，用户操作（鼠标、键盘、窗口移动等）都会以事件的形式从系统传入 Qt。
- 所有继承自 `QObject` 的对象都能收到事件（尤其 `QWidget` 系列）。
- Qt 底层通过 `QCoreApplication::notify()` 派发，支持事件过滤器、事件重定向、传递等特性。

#### 信号槽机制：模块解耦、逻辑通信

- 是 Qt 特有的对象通信机制，解决的是“对象状态变化后如何通知其它对象”的问题。
- 可以定义任意信号，比如：

```cpp
signals:
    void dataLoaded(const QString &data);
```

再通过 `connect` 连接到任何槽函数，执行回调。

#### 使用场景对比

| 使用场景                           | 建议机制                      |
| ---------------------------------- | ----------------------------- |
| 处理用户交互（鼠标、键盘、窗口等） | **事件机制**                  |
| 组件之间传递逻辑消息               | **信号槽机制**                |
| 拦截所有对象的事件（如全局快捷键） | **事件过滤器机制**            |
| 跨线程安全通信                     | **信号槽 + QueuedConnection** |
| 控件内部通信                       | **信号槽机制**                |
| 控件对系统事件作出响应             | **事件机制**                  |

### 总结

| 核心点                              | 说明                                             |
| ----------------------------------- | ------------------------------------------------ |
| **事件统一载体 QEvent**             | 所有事件类型的基类，携带事件类型和状态           |
| **事件分发入口 QObject::event()**   | 事件的默认分发函数，根据类型转调具体事件处理函数 |
| **事件循环 QEventLoop**             | 事件处理的核心循环，负责取事件并分发处理         |
| **主事件循环 QApplication::exec()** | 程序主循环，保证 UI 响应                         |
| **事件过滤器机制**                  | 跨对象事件拦截与预处理                           |