## Qt核心类简介

- Qt 核心类主要分为 **对象类（继承 QObject）** 和 **值类（如 QString, QVariant）**。
- `QObject` 是核心中的核心，`QWidget` 是所有 GUI 控件的起点。
- 值类是轻量级、无需继承，适合数据封装与传递。

### Qt 核心类（Core Classes）

这是 Qt 的“非图形”基础组件，属于模块 `QtCore`，很多都继承自 **`QObject`**。

| 类名                               | 说明                                               |
| ---------------------------------- | -------------------------------------------------- |
| `QObject`                          | 所有 Qt 对象的基类，提供信号槽、事件、元对象等支持 |
| `QCoreApplication`                 | 所有 Qt 应用的主程序类（控制事件循环）             |
| `QString`                          | 字符串类，Unicode 安全                             |
| `QByteArray`                       | 字节数组，常用于网络、文件                         |
| `QVariant`                         | 类型安全的值容器（可以存 int、QString 等）         |
| `QTimer`                           | 定时器类                                           |
| `QThread`                          | 多线程支持                                         |
| `QEvent`                           | 所有事件的基类                                     |
| `QDebug`                           | 调试输出支持（配合 `qDebug()` 使用）               |
| `QFile`, `QDir`, `QTextStream`     | 文件和 IO 相关类                                   |
| `QDateTime`                        | 日期时间类                                         |
| `QMap`, `QList`, `QVector`, `QSet` | 容器类                                             |

### Qt GUI 与窗口系统核心类

这是构建图形界面所需的核心类（模块 `QtWidgets`、`QtGui`）：

| 类名                                     | 说明                                          |
| ---------------------------------------- | --------------------------------------------- |
| `QWidget`                                | 所有图形界面控件的基类                        |
| `QMainWindow`                            | 主窗口类，包含菜单栏、工具栏、状态栏等        |
| `QApplication`                           | GUI 应用程序入口（继承自 `QCoreApplication`） |
| `QPainter`                               | 画图类，2D 绘图操作的核心                     |
| `QLayout`                                | 布局管理器的基类                              |
| `QPushButton`, `QLabel`, `QLineEdit`     | 各种控件类                                    |
| `QDialog`                                | 对话框窗口的基类                              |
| `QEventLoop`, `QMouseEvent`, `QKeyEvent` | 事件系统                                      |

### 类继承结构（简化图）

这里是一个简化的继承结构图（→ 表示继承）：

```css
QObject
├── QCoreApplication
│     └── QApplication
├── QThread
├── QTimer
├── QPaintDevice                // 绘图设备基类，提供绘图目标支持
│    └── QWidget               // 界面控件基类，所有可视控件都从这里继承
│         ├── QMainWindow      // 主窗口，支持菜单栏、工具栏、状态栏
│         ├── QDialog          // 对话框基类
│         ├── QPushButton      // 按钮
│         ├── QLabel           // 标签，显示文本或图片
│         ├── QFrame           // 框架控件，容器类
│         ├── QAbstractScrollArea // 滚动区域基类
│         │     ├── QTextEdit       // 富文本编辑控件
│         │     └── QPlainTextEdit  // 纯文本编辑控件
│         ├── QScrollBar       // 滚动条
│         └── ... 其他控件
├── QLayout                   // 布局管理基类，非控件类，负责控件排列
│     ├── QBoxLayout          // 盒布局
│     │     ├── QHBoxLayout   // 水平布局
│     │     └── QVBoxLayout   // 垂直布局
│     ├── QGridLayout         // 网格布局
│     ├── QFormLayout         // 表单布局
│     └── ... 其他布局类
├── QAction                   // 动作类，菜单、工具栏的抽象操作
├── QObjectUserData           // 用户自定义数据
└── ... 其他 QObject 派生类
```

再加上一些非 QObject 类（值类、工具类）：

```css
QString
QByteArray
QVariant
QList<T>
QMap<Key, T>
QDateTime
QFile
QTextStream
```

### 模块结构概览（常用模块）

| 模块                | 功能                                        |
| ------------------- | ------------------------------------------- |
| `QtCore`            | 所有非图形类（QObject、容器、文件、多线程） |
| `QtGui`             | 图形支持（颜色、字体、图像、绘图）          |
| `QtWidgets`         | 可视化控件（按钮、窗口、布局）              |
| `QtNetwork`         | 网络支持（TCP、HTTP、SSL）                  |
| `QtMultimedia`      | 音频、视频支持                              |
| `QtSql`             | 数据库接口                                  |
| `QtQuick` / `QtQml` | QML 引擎（用于移动和嵌入式）                |

### QObject

- `QObject` 是 Qt 框架中最核心的基类之一，几乎所有 Qt 对象模型的关键特性都依赖于它。

- 可以将 `QObject` 看作 Qt 中“具备元信息和事件响应能力”的对象基类。

- `QObject` 是 Qt 框架的基石，支撑了：

  - 内存管理（对象树）

  - 信号与槽机制

  - 事件系统

  - 元对象反射机制

  - 属性系统

#### 基本介绍

```cpp
#include <QObject>

class MyObject : public QObject {
    Q_OBJECT
public:
    MyObject(QObject *parent = nullptr);
    ~MyObject();
};

```

- `QObject` 是所有使用 Qt 元对象系统（如信号与槽、对象树、动态属性等）类的基类。

- 若一个类继承自 `QObject` 并使用信号与槽机制，则必须添加 `Q_OBJECT` 宏。

#### 主要功能

##### 1. **对象树结构（Parent-Child）**

- `QObject` 支持对象之间的父子关系，这使得内存管理更为方便。
- 父对象会在析构时自动删除其所有子对象。

```cpp
QObject *parent = new QObject;
QObject *child = new QObject(parent); // parent 持有 child
```

> 底层原理（简化）
>
> - 每个 `QObject` 内部有一个 `_parent` 指针和一个 `children` 列表。
> - 当你构造一个对象并传入 `parent`，Qt 会把这个对象加进 `parent` 的 `children()` 列表中。
> - 析构时会遍历子对象并依次 `delete` 掉。
>
> 简单验证
>
> ```cpp
> #include <QCoreApplication>  // Qt 核心应用类，提供事件循环等功能
> #include <QObject>           // Qt 核心对象基类，支持对象树、信号槽等机制
> #include <QDebug>            // 用于调试输出的类和函数
> 
> int main(int argc, char *argv[]) {
>     // 创建 Qt 核心应用实例，argc 和 argv 传递给应用，支持事件处理
>     QCoreApplication a(argc, argv);
> 
>     // 创建一个 QObject 对象，没有指定父对象（nullptr），作为父节点
>     QObject *p = new QObject();
> 
>     // 创建两个 QObject 对象，传入父对象 p，表示它们是 p 的子对象
>     QObject *c1 = new QObject(p);
>     QObject *c2 = new QObject(p);
> 
>     // 输出 c1 的父对象指针地址，应该是 p
>     qDebug() << "Parent:" << c1->parent();
> 
>     // 输出 p 的所有子对象列表，应该包含 c1 和 c2
>     qDebug() << "Children of p:" << p->children();
> 
>     // 启动事件循环，通常用于 GUI 或需要事件驱动的程序
>     return a.exec();
> }
> ```

##### 2. **信号与槽（Signal & Slot）机制**

- `QObject` 支持基于观察者模式的信号与槽机制，是 Qt 编程的核心特性之一。

```cpp
connect(sender, &Sender::signalName, receiver, &Receiver::slotName);
```

- 编译器通过元对象编译器（moc）处理 `Q_OBJECT` 宏生成必要的代码支持信号与槽。

##### 3. **事件系统**

- `QObject` 提供 `event()`、`eventFilter()`、`installEventFilter()` 等机制，支持事件的分发与过滤。
  - `event(QEvent *event)`：所有事件都会先经过这个函数，可以重写它来统一处理不同类型的事件。
  - `eventFilter(QObject *watched, QEvent *event)`：允许一个对象拦截另一个对象的事件，在事件送到目标对象之前先被“过滤”。
  - `installEventFilter(QObject *filterObj)`：给某个对象安装一个事件过滤器，让 `filterObj` 先接收并可以处理这个对象的事件。

- 常用于控件间交互与事件劫持。

> 简单举例：使用事件过滤器拦截鼠标点击事件
>
> 假设我们想在一个按钮点击之前拦截它的鼠标按下事件，做一些自定义处理：
>
> ```cpp
> #include <QApplication>  // Qt 应用程序管理类，负责事件循环等
> #include <QPushButton>   // 按钮控件
> #include <QEvent>       // 事件类基类，包含事件类型定义
> #include <QDebug>       // 调试输出类
> 
> // 自定义事件过滤器类，继承自 QObject
> class FilterObj : public QObject {
> protected:
>     // 重写事件过滤器方法，用于拦截事件
>     bool eventFilter(QObject *watched, QEvent *event) override {
>         // 判断事件类型是否是鼠标按下事件
>         if (event->type() == QEvent::MouseButtonPress) {
>             qDebug() << "鼠标点击事件被拦截了！";
>             // 返回 true，表示事件被过滤掉，后续目标对象不会收到该事件
>             return true;
>         }
>         // 对其他事件，调用父类默认的事件过滤器处理
>         return QObject::eventFilter(watched, event);
>     }
> };
> 
> int main(int argc, char *argv[]) {
>     // 创建应用程序对象，管理应用程序的控制流和主设置
>     QApplication a(argc, argv);
> 
>     // 创建一个按钮控件，文本显示“点击我”
>     QPushButton button("点击我");
> 
>     // 创建事件过滤器对象
>     FilterObj filter;
> 
>     // 给按钮安装事件过滤器，使 filter 可以拦截按钮的事件
>     button.installEventFilter(&filter);
> 
>     // 显示按钮窗口
>     button.show();
> 
>     // 进入 Qt 事件循环，等待事件发生
>     return a.exec();
> }
> ```

##### 4. **元对象系统（Meta-Object System）**

- 通过 `metaObject()` 可获取类的元信息（如类名、属性、信号、槽等）。
- `QObject` 支持运行时类型识别（RTTI）：

```cpp
object->metaObject()->className();
object->inherits("QWidget"); // 判断是否继承自 QWidget
```

##### 5. **动态属性系统**

- 可通过 `setProperty()` 和 `property()` 在运行时动态添加、修改和读取属性。

```cpp
object->setProperty("level", 42);
int level = object->property("level").toInt();
```

##### 6. **定时器机制**

- `QObject` 支持启动定时器并重写 `timerEvent()` 接收定时器事件：

```cpp
int id = startTimer(1000); // 1 秒定时
void timerEvent(QTimerEvent *event) override;
```

> 每 1 秒打印一次计数器
>
> counter.h
>
> ```cpp
> #ifndef COUNTER_H
> #define COUNTER_H
> 
> #include <QObject>
> #include <QTimerEvent>
> #include <QDebug>
> 
> class Counter : public QObject {
>     Q_OBJECT
> 
> private:
>     int counter = 0;
>     int timerId = 0;
> 
> protected:
>     void timerEvent(QTimerEvent *event) override {
>         if (event->timerId() == timerId) {
>             counter++;
>             qDebug() << "定时器触发，第" << counter << "次";
>             if (counter >= 5) {
>                 qDebug() << "停止定时器";
>                 killTimer(timerId);
>                 QCoreApplication::quit();
>             }
>         }
>     }
> 
> public:
>     Counter() {
>         timerId = startTimer(1000);
>         qDebug() << "定时器已启动";
>     }
> };
> 
> #endif // COUNTER_H
> ```
>
> main.cpp
>
> ```cpp
> #include "Counter.h"
> #include <QApplication>
> 
> int main(int argc, char *argv[]) {
>     QApplication a(argc, argv);
>     Counter c;  // 创建并启动定时器对象
>     return a.exec();
> }
> ```

#### 常用成员函数

| 函数                                 | 功能描述                 |
| ------------------------------------ | ------------------------ |
| `QObject(QObject *parent = nullptr)` | 构造函数，设置父对象     |
| `~QObject()`                         | 析构函数，自动销毁子对象 |
| `setObjectName(const QString &)`     | 设置对象名               |
| `objectName()`                       | 获取对象名               |
| `parent()` / `children()`            | 获取父/子对象            |
| `deleteLater()`                      | 延迟删除对象（线程安全） |
| `installEventFilter(QObject *)`      | 安装事件过滤器           |
| `isWidgetType()`                     | 判断是否为 QWidget 类型  |

#### 使用注意事项

- 若使用信号与槽，必须添加 `Q_OBJECT` 宏并使用 `moc` 编译。
- `QObject` 不允许被拷贝：其拷贝构造和赋值操作被禁用（QObject 的子类也禁止拷贝）。
- 子类构造函数要传递 `parent` 给 `QObject` 构造函数，保证对象树正确。

### QWidget

`QWidget` 是 Qt 框架中所有用户界面控件（窗口部件）的基类。它既可以作为一个顶层窗口（独立窗体），也可以作为其他窗口部件的容器（子控件）。

#### 基本定义

- **头文件**：`#include <QWidget>`
- **模块**：Qt Widgets
- **继承关系**：`QObject` → `QPaintDevice` → `QWidget`
- **作用**：提供窗口控件的显示、布局管理、事件处理、绘图等基础功能。

#### QWidget 的主要功能

##### 窗口和控件管理

- 可以创建顶层窗口（没有父控件）或嵌套控件（有父控件）。
- 管理控件的大小、位置、可见性、样式、窗口标题等。
- 支持窗口类型设置（如弹出窗口、对话框、工具窗口等）。

##### 事件处理

- 支持鼠标事件（点击、移动、双击等）、键盘事件（按键）、窗口事件（关闭、移动、调整大小）。
- 支持事件过滤，允许自定义事件响应。
- 支持信号与槽机制，配合事件处理做交互。

##### 绘图

- 提供 `paintEvent()`，可重写来自定义绘制内容。
- 通过 `QPainter` 在控件上绘制图形、文字、图片。

##### 布局管理

- 可以设置布局管理器（如 `QHBoxLayout`、`QVBoxLayout` 等），自动安排子控件位置和大小。
- 提供尺寸策略（size policies）和尺寸提示（size hint）来辅助布局。

##### 父子关系管理

- 支持父控件和子控件的层级关系。
- 父控件销毁时自动销毁所有子控件，避免内存泄漏。

#### 常用成员函数

| 函数名                                 | 说明           |
| -------------------------------------- | -------------- |
| `show()`                               | 显示控件       |
| `hide()`                               | 隐藏控件       |
| `resize(int w, int h)`                 | 调整控件大小   |
| `move(int x, int y)`                   | 移动控件位置   |
| `setWindowTitle(const QString &title)` | 设置窗口标题   |
| `setLayout(QLayout *layout)`           | 设置布局管理器 |
| `update()`                             | 请求重绘控件   |
| `repaint()`                            | 立即重绘控件   |
| `setFocus()`                           | 设置控件为焦点 |
| `setAttribute(Qt::WidgetAttribute)`    | 设置控件属性   |

#### 重要事件函数（可重写）

- `void paintEvent(QPaintEvent *event)`
   处理控件的绘制事件，自定义界面时重写此函数。

- `void mousePressEvent(QMouseEvent *event)`
   鼠标按下事件。

- `void mouseReleaseEvent(QMouseEvent *event)`
   鼠标释放事件。

- `void keyPressEvent(QKeyEvent *event)`
   键盘按键按下事件。

- `void resizeEvent(QResizeEvent *event)`
   控件大小改变时触发。

- `void closeEvent(QCloseEvent *event)`
   窗口关闭事件。

#### 示例代码

```cpp
#include <QApplication>
#include <QWidget>
#include <QPainter>    // 用于绘图
#include <QMouseEvent> // 处理鼠标事件

// 自定义控件类，继承自 QWidget
class MyWidget : public QWidget {
public:
    MyWidget(QWidget *parent = nullptr) : QWidget(parent) {
        // 设置控件的初始大小
        resize(400, 300);

        // 设置控件标题（如果是顶层窗口）
        setWindowTitle("Detailed QWidget Example");

        // 使控件可以接收键盘焦点
        setFocusPolicy(Qt::StrongFocus);
    }

protected:
    // 重写绘制事件，绘制自定义内容
    void paintEvent(QPaintEvent *event) override {
        QPainter painter(this);  // 创建绘图对象，目标是当前控件

        // 填充背景颜色为浅灰色
        painter.fillRect(rect(), Qt::lightGray);

        // 设置画刷为蓝色，绘制一个矩形填充控件区域
        painter.setBrush(Qt::blue);
        painter.drawRect(50, 50, 300, 200);

        // 设置画笔颜色为白色，绘制文本
        painter.setPen(Qt::white);
        painter.setFont(QFont("Arial", 20));
        painter.drawText(rect(), Qt::AlignCenter, "Hello QWidget");
    }

    // 重写鼠标按下事件，打印点击位置
    void mousePressEvent(QMouseEvent *event) override {
        // 打印点击的坐标位置
        qDebug("Mouse pressed at (%d, %d)", event->x(), event->y());
    }

    // 重写键盘按键事件，响应按键
    void keyPressEvent(QKeyEvent *event) override {
        if (event->key() == Qt::Key_Escape) {
            // 按下 ESC 键时关闭窗口
            close();
        }
    }

    // 窗口调整大小事件，可以做自适应处理
    void resizeEvent(QResizeEvent *event) override {
        qDebug("Window resized: width=%d, height=%d",
               event->size().width(), event->size().height());
    }
};

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    MyWidget window;  // 创建自定义控件实例
    window.show();    // 显示窗口

    return app.exec();  // 进入 Qt 事件循环
}
```

### QApplication

  `QApplication` 是 Qt 应用程序中图形界面（GUI）程序的核心类之一，定义在头文件 `<QApplication>` 中。它管理应用程序的控制流和主要设置，是所有使用 Qt GUI 的程序所必须创建的对象。

#### 基本作用

`QApplication` 类的主要功能包括：

1. **初始化图形界面应用程序的环境**
    如设置字体、样式、窗口图标、国际化等。
2. **事件循环管理**
    提供 `exec()` 方法来启动主事件循环，处理用户输入、窗口更新等事件。
3. **全局状态管理**
    例如全局剪贴板、应用程序样式、主屏幕信息、应用级别的信号等。

#### 常见用法

```cpp
#include <QApplication>
#include <QPushButton>

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);  // 必须首先创建 QApplication 对象

    QPushButton button("Hello, Qt!");
    button.show();  // 显示窗口

    return app.exec();  // 启动事件循环
}
```

#### 重要成员函数

| 方法                                   | 作用                           |
| -------------------------------------- | ------------------------------ |
| `exec()`                               | 启动事件循环，阻塞直到程序退出 |
| `quit()`                               | 请求退出主事件循环             |
| `setStyle()`                           | 设置 GUI 控件风格              |
| `setFont()`                            | 设置应用程序全局字体           |
| `clipboard()`                          | 获取全局剪贴板对象             |
| `desktop()`（Qt5）/ `screens()`（Qt6） | 获取屏幕信息（多屏支持）       |
| `activeWindow()`                       | 获取当前活动窗口               |
| `topLevelWidgets()`                    | 获取所有顶层窗口指针列表       |

#### 注意事项

- **QApplication 对象必须在任何 GUI 控件之前创建**。
- 同一进程中只能创建一个 QApplication 实例。
- Qt6 中 `QApplication` 被细分为 `QApplication`（用于 GUI）和 `QCoreApplication`（用于非 GUI 程序，如控制台工具、服务程序）。

#### Qt6 的差异（简述）

在 Qt6 中：

- `QGuiApplication` 提供基本 GUI 功能（比如窗口系统、输入事件等）
- `QApplication` 继承自 `QGuiApplication`，并引入了 widgets 支持

### QMainWindow

`QMainWindow` 是 Qt 提供的一个高级窗口部件类，它是大多数桌面 GUI 应用的主窗口框架。它在 `QWidget` 的基础上扩展，提供了**菜单栏（Menu Bar）**、**工具栏（Tool Bar）**、**状态栏（Status Bar）**、**停靠窗口（Dock Widget）\**等\**完整的窗口布局机制**。

#### 用法示例

```cpp
#include <QApplication>
#include <QMainWindow>
#include <QTextEdit>

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    QMainWindow window;
    QTextEdit *editor = new QTextEdit();
    window.setCentralWidget(editor);  // 设置中央控件
    window.resize(800, 600);
    window.show();

    return app.exec();
}
```

#### QMainWindow 的布局组成

QMainWindow 是一个**有结构的窗口**，支持以下组件：

```css
+------------------------------------------------------+
| Menu Bar                                             |
+------------------------------------------------------+
| Tool Bar                                             |
+------------------------------------------------------+
| Dock Widgets |           Central Widget              |
|              |                                       |
|              |                                       |
+--------------+---------------------------------------+
| Status Bar                                           |
+------------------------------------------------------+
```

#### 常用成员函数

| 方法                                               | 说明                                       |
| -------------------------------------------------- | ------------------------------------------ |
| `setCentralWidget(QWidget *)`                      | 设置中央主控件（必须设置，否则主区域为空） |
| `menuBar()`                                        | 获取菜单栏指针，可添加菜单项               |
| `addToolBar(QToolBar *)`                           | 添加工具栏                                 |
| `addDockWidget(Qt::DockWidgetArea, QDockWidget *)` | 添加可停靠窗口                             |
| `statusBar()`                                      | 获取状态栏，可显示信息                     |
| `setStatusBar(QStatusBar *)`                       | 替换默认状态栏                             |
| `setMenuBar(QMenuBar *)`                           | 替换默认菜单栏                             |

#### 示例：添加菜单栏与状态栏

```cpp
#include "widget.h"

#include <QApplication>
#include <QMainWindow>
#include <QMenuBar>
#include <QStatusBar>
#include <QTextEdit>
#include <QToolBar>

int main(int argc, char* argv[]) {
    QApplication a(argc, argv);
    QMainWindow window;

    // 中央控件
    QTextEdit* editor = new QTextEdit();
    window.setCentralWidget(editor);

    // 菜单栏
    QMenuBar* menuBar = window.menuBar();
    QMenu* fileMenu = menuBar->addMenu("File");
    fileMenu->addAction("Open");
    fileMenu->addAction("Exit");

    // 状态栏
    QStatusBar* statusBar = window.statusBar();
    statusBar->showMessage("Ready");

    // 工具栏
    QToolBar* toolBar = new QToolBar();
    toolBar->addAction("Undo");
    window.addToolBar(toolBar);
    window.show();

    return a.exec();
}
```

#### QMainWindow vs QWidget 的区别

| 对比项         | QMainWindow          | QWidget              |
| -------------- | -------------------- | -------------------- |
| 结构化窗口支持 | ✅ 有菜单栏、状态栏等 | ❌ 手动布局           |
| 用作主窗口     | ✅ 推荐用作主窗口     | ✅ 可用，但功能少     |
| 内部默认布局   | 内建多区域布局系统   | 纯手动布局（layout） |
| 用途           | 应用主界面           | 通用控件或子界面     |

### QLayout

`QLayout` 是 Qt 中的布局管理器基类，用于**自动管理多个控件在父窗口中的排列与大小调整**。你可以把它理解为“布局策略”的核心接口，其子类如 `QVBoxLayout`、`QHBoxLayout`、`QGridLayout` 等负责具体的排布逻辑。

####  常见子类及用途

`QLayout` 是 Qt 用来控制控件排列和自动调整大小的基类，通常不会直接使用它，而是使用其派生类。

| 子类             | 描述                             |
| ---------------- | -------------------------------- |
| `QVBoxLayout`    | 垂直排列控件                     |
| `QHBoxLayout`    | 水平排列控件                     |
| `QGridLayout`    | 表格状排列控件                   |
| `QFormLayout`    | 表单式排列（左边标签，右边控件） |
| `QStackedLayout` | 多页叠加式布局（如 tab 页）      |

#### 用法示例：`QVBoxLayout`

```cpp
#include <QApplication>
#include <QPushButton>
#include <QVBoxLayout>
#include <QWidget>

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    QWidget window;
    QVBoxLayout *layout = new QVBoxLayout();

    layout->addWidget(new QPushButton("Button 1"));
    layout->addWidget(new QPushButton("Button 2"));
    layout->addWidget(new QPushButton("Button 3"));

    window.setLayout(layout);
    window.show();

    return app.exec();
}
```

#### QLayout 的核心功能

**自动布局管理**

- 自动调整子控件大小
- 根据窗口大小自动重新排列

**边距与间距控制**

- `setContentsMargins(left, top, right, bottom)`
- `setSpacing(int)`

**嵌套布局支持**

- 布局中可以再嵌套布局（支持复杂 UI）

#### 主要接口（在 `QLayout` 中定义）

| 方法                          | 说明                         |
| ----------------------------- | ---------------------------- |
| `addWidget(QWidget *)`        | 向布局中添加控件（子类实现） |
| `addLayout(QLayout *)`        | 添加子布局，实现嵌套         |
| `setContentsMargins(...)`     | 设置四周边距                 |
| `setSpacing(int)`             | 设置控件之间的间距           |
| `itemAt(int)` / `takeAt(int)` | 获取/移除布局项              |
| `count()`                     | 子控件（项）数量             |
| `invalidate()`                | 强制重新计算布局             |
| `update()`                    | 通知 Qt 更新布局显示         |

#### 和 QWidget 的关系

- `QWidget::setLayout(QLayout *)` 绑定布局到控件

- 一个 QWidget 只能设置一个顶层布局

- 控件一旦加入布局，它的大小和位置就由布局管理，不再需要 `setGeometry()` 或 `resize()` 手动控制