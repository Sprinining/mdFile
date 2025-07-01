## Qt 资源文件

### Qt 资源系统

Qt 的资源系统（Qt Resource System）是 Qt 提供的一种机制，用于将图片、UI 文件、音频等资源打包进可执行文件（exe）或动态库中，使得程序可以无需依赖外部文件运行。这对于部署、跨平台移植、简化资源管理都非常有用。

示例 `.qrc` 文件：

```xml
<RCC>
    <qresource prefix="/images">
        <file>icons/icon.png</file>
        <file>background.jpg</file>
    </qresource>
</RCC>
```

- `prefix`：资源前缀，类似虚拟路径；
- `<file>`：本地文件路径，文件会打包进程序。

Qt 的资源系统是**静态资源**，不支持运行时动态更改。如果需要在运行时加载用户资源文件，应使用本地路径而不是资源路径（不要用 `:/` 开头）。

### rcc 工具

#### 什么是 rcc？

- **rcc**（Resource Compiler）是 Qt 提供的一个命令行工具，用于将 `.qrc` 资源描述文件编译成 C++ 代码。

- 通过将资源文件打包进 C++ 代码，最终编译进可执行程序，实现资源文件的嵌入。

#### rcc 的作用

- 将 XML 格式的资源描述文件（`.qrc`）转换成 C++ 源文件（`.cpp`），

- 使资源文件不必以独立文件形式存在，程序运行时能直接通过资源路径访问这些资源。

#### rcc 的基本用法

假设有资源文件 `resources.qrc`：

```cpp
rcc -o resources.cpp resources.qrc
```

- 这个命令会生成 `resources.cpp`，其中包含了对资源文件的静态数据表示。
- 可以把生成的 `resources.cpp` 文件加入项目源码，一起编译。

#### 常用参数

| 参数           | 说明                                                         |
| -------------- | ------------------------------------------------------------ |
| `-o <file>`    | 指定输出文件名                                               |
| `-binary`      | 生成二进制资源文件（不常用，主要用于特殊情况）               |
| `-name <name>` | 指定资源文件的名字，默认是 `qresource`                       |
| `-list`        | 列出 `.qrc` 文件中包含的所有资源文件路径（用于检查资源内容） |

#### rcc 在构建流程中的位置

在使用 qmake 或 CMake 时，通常会自动调用 rcc，将 `.qrc` 文件转换成对应的 C++ 文件，无需手动调用。

手动调用 rcc 多用于：

- 自定义构建流程
- 构建脚本中生成资源文件
- 研究或调试资源文件问题

#### rcc 生成的文件内容简介

- 生成的 `.cpp` 文件通常会包含一个静态数组，这个数组存储了资源文件的二进制数据。

- 程序启动时，Qt 会自动注册这些资源，可以用 `":/prefix/filename"` 方式访问。

#### 生成独立二进制资源文件 和 嵌入资源的区别

##### 应用程序内嵌资源（默认）

默认情况下，rcc 将 `.qrc` 文件转换为 C++ 代码，生成 `.cpp` 文件，然后这个 `.cpp` 编译进你的程序。这样资源被**静态编译**进程序，程序运行时直接访问内嵌资源。

优点：不需要额外文件，部署方便。

缺点：修改资源需重新编译程序。

##### 生成独立的二进制资源文件（`.rcc` 文件）

- 使用 `rcc` 的 `-binary` 参数，可以将资源编译成一个独立的 `.rcc` 文件，而不是 C++ 代码。

```bash
rcc -binary -o resources.rcc resources.qrc
```

- 这个 `resources.rcc` 是一个打包了资源的二进制文件，可以和程序一起分发。

Qt 提供 API 让程序在运行时加载这个二进制资源文件：

```cpp
QResource::registerResource("/path/to/resources.rcc");
```

- 加载后，资源就可以像内嵌资源一样通过 `":/prefix/filename"` 访问。
- 也可以卸载资源：

```cpp
QResource::unregisterResource("/path/to/resources.rcc");
```

### QIcon vs QPixmap vs QImage

| 特性         | QIcon                            | QPixmap                               | QImage                           |
| ------------ | -------------------------------- | ------------------------------------- | -------------------------------- |
| **用途**     | 用于表示图标，支持多分辨率和状态 | 用于显示和绘制图像（GUI相关）         | 用于图像数据处理和像素操作       |
| **数据存储** | 封装多种尺寸和状态的图像资源     | 屏幕相关的图像，依赖于底层显示硬件    | 独立于屏幕的图像像素数据         |
| **绘制性能** | 主要用于控件和按钮的图标显示     | 适合快速绘制到屏幕或窗口              | 不适合直接绘制，更多用于图像处理 |
| **平台依赖** | 依赖于 QPixmap 或其他格式实现    | 依赖于平台的图形系统（如 X11/WinAPI） | 跨平台，像素数据独立             |
| **功能**     | 管理不同状态和尺寸的图标         | 高效的图像显示                        | 方便访问和修改像素数据           |
| **转换能力** | 可以从 QPixmap 或 QImage 创建    | 可以从 QImage 转换                    | 可以保存成多种图像格式           |
| **常用场景** | 按钮图标、窗口图标等             | 绘制窗口背景、控件图形                | 图像处理、像素编辑、图像分析     |

#### 1. QIcon

- **目的**：管理多尺寸、多状态（正常、禁用、悬停等）图标。

- 通常用于按钮、工具栏、窗口标题栏的图标。

- 可以包含多种尺寸的 QPixmap，自动根据设备分辨率选择合适的图标显示。

- 示例：

  ```cpp
  QIcon icon(":/icons/myicon.png");
  button->setIcon(icon);
  ```

#### 2. QPixmap

- **目的**：高效绘制图像，主要用于 GUI 相关显示。

- 是和底层窗口系统或显卡紧密耦合的图像缓存。

- 不能直接访问像素（只能用 QPainter 绘制），性能高。

- 适合加载位图、绘制到 QWidget。

- 示例：

  ```cpp
  QPixmap pixmap(":/images/picture.png");
  label->setPixmap(pixmap);
  ```

#### 3. QImage

- **目的**：独立于显示设备，操作像素数据方便。

- 支持像素级读写、格式转换、图像处理（旋转、滤镜等）。

- 适合需要访问或修改图像内容的场景。

- 示例：

  ```cpp
  QImage image(":/images/picture.png");
  QRgb pixel = image.pixel(10, 10);
  image.setPixel(10, 10, qRgb(255, 0, 0));
  ```

### 示例：图标使用

#### widget.ui

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>Widget</class>
 <widget class="QWidget" name="Widget">
  <property name="geometry">
   <rect>
    <x>0</x>
    <y>0</y>
    <width>219</width>
    <height>115</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <widget class="QWidget" name="formLayoutWidget">
   <property name="geometry">
    <rect>
     <x>10</x>
     <y>0</y>
     <width>201</width>
     <height>108</height>
    </rect>
   </property>
   <layout class="QFormLayout" name="formLayout">
    <item row="0" column="0">
     <widget class="QLabel" name="label">
      <property name="text">
       <string>姓名</string>
      </property>
     </widget>
    </item>
    <item row="0" column="1">
     <widget class="QLineEdit" name="lineEditName"/>
    </item>
    <item row="1" column="0">
     <widget class="QLabel" name="label_2">
      <property name="text">
       <string>性别</string>
      </property>
     </widget>
    </item>
    <item row="2" column="0">
     <widget class="QLabel" name="label_3">
      <property name="text">
       <string>性格</string>
      </property>
     </widget>
    </item>
    <item row="1" column="1">
     <layout class="QHBoxLayout" name="horizontalLayout">
      <item>
       <widget class="QRadioButton" name="radioButtonMan">
        <property name="text">
         <string>男</string>
        </property>
        <property name="icon">
         <iconset resource="icons.qrc">
          <normaloff>:/images/man.png</normaloff>:/images/man.png</iconset>
        </property>
       </widget>
      </item>
      <item>
       <widget class="QRadioButton" name="radioButtonWoman">
        <property name="text">
         <string>女</string>
        </property>
        <property name="icon">
         <iconset resource="icons.qrc">
          <normaloff>:/images/woman.png</normaloff>:/images/woman.png</iconset>
        </property>
       </widget>
      </item>
     </layout>
    </item>
    <item row="2" column="1">
     <widget class="QComboBox" name="comboBox"/>
    </item>
    <item row="3" column="0">
     <widget class="QPushButton" name="btnCommit">
      <property name="text">
       <string>提交</string>
      </property>
      <property name="icon">
       <iconset resource="icons.qrc">
        <normaloff>:/images/yes.png</normaloff>:/images/yes.png</iconset>
      </property>
     </widget>
    </item>
    <item row="3" column="1">
     <widget class="QPushButton" name="btnCancel">
      <property name="text">
       <string>取消</string>
      </property>
      <property name="icon">
       <iconset resource="icons.qrc">
        <normaloff>:/images/no.png</normaloff>:/images/no.png</iconset>
      </property>
     </widget>
    </item>
   </layout>
  </widget>
 </widget>
 <resources>
  <include location="icons.qrc"/>
 </resources>
 <connections/>
</ui>
```

#### icons.qrc

```xml
<RCC>
    <qresource prefix="/">
        <file>images/ellipse.png</file>
        <file>images/man.png</file>
        <file>images/no.png</file>
        <file>images/polygon.png</file>
        <file>images/rectangle.png</file>
        <file>images/triangle.png</file>
        <file>images/woman.png</file>
        <file>images/yes.png</file>
    </qresource>
</RCC>
```

#### widget.h

```cpp
#ifndef WIDGET_H
#define WIDGET_H

#include <QWidget>

QT_BEGIN_NAMESPACE
namespace Ui {
class Widget;
}
QT_END_NAMESPACE

class Widget : public QWidget {
    Q_OBJECT

public:
    Widget(QWidget* parent = nullptr);
    ~Widget();

private slots:
    void on_btnCommit_clicked();

    void on_btnCancel_clicked();

private:
    Ui::Widget* ui;
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"      // 包含自定义窗口类的头文件
#include "./ui_widget.h" // 包含由 uic 工具生成的 UI 类定义（ui->setupUi 会用到）
#include <QDebug>        // 用于调试输出
#include <QIcon>         // 用于设置图标
#include <QMessageBox>   // 弹出提示框
#include <QPixmap>       // 图标图像处理类

// 构造函数，初始化 UI
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this); // 构建 UI 界面（自动连接 .ui 文件中定义的控件）

    // 默认选中“男”单选按钮
    ui->radioButtonMan->setChecked(true);

    // 向下拉框中添加图标 + 描述文字（性格特质）
    ui->comboBox->addItem(QIcon(":/images/triangle.png"), tr("锐意进取"));
    ui->comboBox->addItem(QIcon(":/images/rectangle.png"), tr("大方得体"));
    ui->comboBox->addItem(QIcon(":/images/polygon.png"), tr("灵活善变"));
    ui->comboBox->addItem(QIcon(":/images/ellipse.png"), tr("精明圆滑"));
}

// 析构函数，释放 UI 内存
Widget::~Widget() {
    delete ui;
}

// 提交按钮被点击后的槽函数（展示用户填写的信息）
void Widget::on_btnCommit_clicked() {
    QString res;

    // 添加姓名信息
    res.append(tr("姓名：%1\r\n").arg(ui->lineEditName->text()));

    // 添加性别信息
    res.append(ui->radioButtonMan->isChecked() ? tr("性别：男\r\n") : tr("性别：女\r\n"));

    // 添加性格特质信息
    res.append(tr("性格特质：%1\r\n").arg(ui->comboBox->currentText()));

    // 获取当前选中项对应的图标
    int index = ui->comboBox->currentIndex();    // 当前选中项索引
    QIcon icon = ui->comboBox->itemIcon(index);  // 获取该项的图标
    QPixmap pixmap = icon.pixmap(QSize(32, 32)); // 转换为指定大小的 Pixmap 图像

    // 构建消息框并显示结果
    QMessageBox msgBox;
    msgBox.setWindowTitle(tr("人员信息"));      // 标题
    msgBox.setText(res);                        // 文本内容
    msgBox.setStandardButtons(QMessageBox::Ok); // 只有“确定”按钮
    msgBox.setIconPixmap(pixmap);               // 设置图标（性格特质图标）
    msgBox.exec();                              // 显示消息框（阻塞）
}

// 取消按钮被点击后的槽函数（提示并退出）
void Widget::on_btnCancel_clicked() {
    // 弹出确认框，询问用户是否退出
    int ret = QMessageBox::information(this,
                                       tr("退出"),                        // 标题
                                       tr("您确定要退出程序吗？"),        // 内容
                                       QMessageBox::Yes | QMessageBox::No // 提供“是/否”选项
                                       );

    // 如果用户选择“是”，则关闭窗口（退出程序）
    if (QMessageBox::Yes == ret) this->close();
}
```

#### 完整编译流程图（ASCII）

```css
+-------------+   +-----------+   +-------------+   +-----------+
| widget.ui   |   | widget.h |    | icons.qrc   |   | main.cpp  |
+------+------+   +-----------+   +------+------|   +-----+-----+
       |                              |                   |
       v                              v                   v
   +--------+                    +--------+           +--------+
   |  uic   |                    |  rcc   |           |  g++   |
   |生成UI头|                    |生成资源|            | 编译主  |
   +---+----+                    +---+----+           +--------+
       |                            |                     |
       v                            v                     v
+--------------+           +----------------+       +-----------+
| ui_widget.h  |           | qrc_icons.cpp  |       |  main.o   |
+------+-------+           +-------+--------+       +-----------+
       |                            |                          
       |                            v                          
       |                      +------------+                  
       |                      |   g++ 编译  |                  
       |                      +------+-----+                  
       |                             v                        
       |                      +-------------+                 
       |                      | qrc_icons.o |                 
       |                      +-------------+                 
       |                                                      
+--------------+      +-------------------+                   
| widget.cpp   | ---> | moc (元对象编译)  |                   
+------+-------+      +--------+----------+                   
       |                       |                              
       v                       v                              
+--------------+      +-------------------+                   
| moc_widget.cpp| <== |  Q_OBJECT + UI头  |                   
+-------+------+      +-------------------+                   
        |                                                    
        v                                                    
   +------------+                                           
   |  g++ 编译  |                                           
   +-----+------+                                           
         v                                                  
   +-------------+                                          
   | widget.o    |                                          
   +-------------+                                          

                所有目标文件链接：
+---------------------------------------------------------+
| g++ main.o widget.o moc_widget.o qrc_icons.o -o my_app |
+-------------------------------+-------------------------+
                                |
                                v
                         +-------------+
                         |  ./my_app   |
                         +-------------+
```

### QSplashScreen

`QSplashScreen` 是 Qt 提供的一个用于在应用程序启动时显示启动画面（Splash Screen）的类，常用于展示软件 Logo、版本号、加载进度提示等内容，在主窗口加载前提供更好的用户体验。

#### 作用

`QSplashScreen` 会显示在所有窗口的前面，通常在主窗口加载过程中显示几秒钟，然后自动关闭或手动关闭。

#### 基本用法

```cpp
#include <QApplication>
#include <QMainWindow>
#include <QSplashScreen>
#include <QPixmap>
#include <QThread>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    QPixmap pixmap(":/images/splash.png"); // 加载启动图资源
    QSplashScreen splash(pixmap);          // 创建启动画面
    splash.show();                         // 显示启动画面
    app.processEvents();                   // 保证立即显示，而不是等主循环

    // 模拟加载过程
    QThread::sleep(2);                     // 可替换为初始化操作
    splash.showMessage("正在加载主窗口...", Qt::AlignBottom | Qt::AlignCenter, Qt::white);

    QMainWindow mainWin;
    mainWin.setWindowTitle("主窗口");
    mainWin.resize(600, 400);
    mainWin.show();

    splash.finish(&mainWin);              // 等主窗口显示后关闭 Splash
    return app.exec();
}
```

#### 常用方法

| 方法                     | 说明                                     |
| ------------------------ | ---------------------------------------- |
| `showMessage(text, ...)` | 在 Splash 图上显示文本（支持位置、颜色） |
| `clearMessage()`         | 清除之前显示的文本                       |
| `finish(QWidget* w)`     | 等指定窗口显示后关闭 Splash              |
| `repaint()`              | 手动重绘 Splash，一般用于长时间阻塞中    |

#### 注意事项

- 使用 `QSplashScreen` 时要调用 `app.processEvents()`，否则 Splash 画面不会及时刷新。

- 不要在主线程中阻塞过久（如 `sleep()`），应使用后台线程初始化资源。

- 可配合 `QElapsedTimer` 或 `QTimer` 控制 Splash 显示时间。

### 添加应用程序图标

在 Qt 项目中使用 **CMake 添加应用程序图标**，需要根据平台做不同的处理：

- Windows → 使用 `.rc` 文件
- macOS → 使用 `.icns` 文件
- Linux → 使用 `.desktop` 文件或不嵌入（窗口图标通过代码设置）

#### Windows 平台添加图标（.rc 文件）

1. 添加图标资源文件

准备一个 `.ico` 文件，例如 `app.ico`。

2. 编写资源文件 `app.rc`（内容如下）：

```css
IDI_ICON1 ICON DISCARDABLE "app.ico"
```

3. 修改 `CMakeLists.txt`

```cmake
# 加到 source 列表中
set(PROJECT_SOURCES
    main.cpp
    widget.cpp
    widget.h
    widget.ui
    app.rc      # 添加资源文件
)

# 指定使用 RC 编译器（仅 Windows 下）
if (WIN32)
    enable_language(RC)
endif()
```

### 示例：启动画面

先通过 `rcc -binary bigpics.qrc -o bigpics.rcc` 的方式生成二进制资源文件 `bigpics.rcc`，再将其复制到影子构建文件夹下。

```css
projects/
├── splash/                  ← 源码目录
│   ├── CMakeLists.txt
│   └── main.cpp
└── build-splash-qt6-debug/  ← 影子构建目录
    ├── Makefile
    ├── moc_*.cpp
    ├── ui_*.h
    └── splash.exe
```

#### widget.ui

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>Widget</class>
 <widget class="QWidget" name="Widget">
  <property name="geometry">
   <rect>
    <x>0</x>
    <y>0</y>
    <width>800</width>
    <height>600</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <widget class="QPushButton" name="btnAbout">
   <property name="geometry">
    <rect>
     <x>180</x>
     <y>140</y>
     <width>75</width>
     <height>23</height>
    </rect>
   </property>
   <property name="text">
    <string>关于本程序</string>
   </property>
  </widget>
  <widget class="QPushButton" name="btnAboutQt">
   <property name="geometry">
    <rect>
     <x>340</x>
     <y>140</y>
     <width>75</width>
     <height>23</height>
    </rect>
   </property>
   <property name="text">
    <string>关于Qt</string>
   </property>
  </widget>
 </widget>
 <resources/>
 <connections/>
</ui>
```

#### widget.h

```cpp
#ifndef WIDGET_H
#define WIDGET_H

#include <QWidget>

QT_BEGIN_NAMESPACE
namespace Ui {
class Widget;
}
QT_END_NAMESPACE

class Widget : public QWidget {
    Q_OBJECT

public:
    Widget(QWidget* parent = nullptr);
    ~Widget();

private slots:
    void on_btnAbout_clicked();

    void on_btnAboutQt_clicked();

private:
    Ui::Widget* ui;
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QDebug>
#include <QMessageBox>

Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);
}

Widget::~Widget() {
    delete ui;
}

void Widget::on_btnAbout_clicked() {
    QMessageBox::about(this, tr("关于本程序"), tr("启动画面演示程序，版本 1.0，\r\n使用外挂资源 bigpics.rcc。"));
}

void Widget::on_btnAboutQt_clicked() {
    QMessageBox::aboutQt(this, tr("关于 Qt"));
}
```

#### main.cpp

```cpp
#include "widget.h" // 引入主窗口类的声明

#include <QApplication>  // 应用程序主入口类
#include <QPixmap>       // 图像处理类，主要用于加载和显示图片
#include <QResource>     // Qt 资源系统类，用于注册外部 .rcc 资源
#include <QSplashScreen> // 启动画面类
#include <QThread>       // 线程处理类，用于调用 sleep 等函数

int main(int argc, char* argv[]) {
    QApplication a(argc, argv); // 创建 Qt 应用程序对象，argc/argv 是命令行参数

    // 将 bigpics.rcc 注册为资源文件，里面应包含 splash.png 等图片
    QResource::registerResource("bigpics.rcc");

    // 加载启动图片（注意路径是资源路径而非文件路径）
    QPixmap pixmap(":/splash.png");

    // 缩放图片至 480x270 尺寸（适配窗口大小）
    pixmap = pixmap.scaled(QSize(480, 270));

    // 创建启动画面（Splash Screen）对象并展示图片
    QSplashScreen splash(pixmap);
    splash.show();

    // 在启动图上显示一行提示文字，左下角对齐
    splash.showMessage(QObject::tr("加载中 ..."), Qt::AlignLeft | Qt::AlignBottom);

    // 处理当前事件队列，确保 splash 能及时显示出来
    a.processEvents();

    // 创建主窗口对象
    Widget w;

    // 模拟加载过程，当前线程休眠 3 秒（注意：不可用于真实长耗时任务）
    w.thread()->sleep(3);

    // 显示主窗口
    w.show();

    // 当主窗口显示完成后，关闭启动画面
    splash.finish(&w);

    // 进入 Qt 应用程序事件循环
    return a.exec();
}

```

