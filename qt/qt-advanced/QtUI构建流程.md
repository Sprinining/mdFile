## Qt UI构建流程

Qt 的 UI 构建流程可以分为两种方式：

- 使用 Qt Designer（.ui 文件）+ 自动生成代码

- 使用 C++ 代码手动构建 UI（纯代码方式）

### 使用 Qt Designer 构建 UI（推荐方式）

#### Qt Designer 是什么？能做什么？

> **Qt Designer** 是 Qt 提供的图形界面编辑器，支持通过拖拽方式设计 `.ui` 文件（XML 形式），再由 Qt 工具自动转换为 C++ 代码使用。

可以拖控件、布局、设定 `objectName`、信号槽等，而不用手动写 C++ 来 new 控件和布局。

#### 全流程图：从 UI 设计到程序运行

```css
            【Qt Designer】
                ↓
           保存 .ui 文件 (XML)
                ↓
           uic（UI Compiler）
                ↓
        生成 ui_xxx.h 头文件（C++）
                ↓
       MainWindow 中 include 并调用
                ↓
     ui->setupUi(this) 创建并配置控件
                ↓
           程序运行可视化 UI
```

#### 项目结构与源代码

##### 项目结构

```css
MyProject/
├── main.cpp
├── mainwindow.h
├── mainwindow.cpp
├── mainwindow.ui        <-- Qt Designer 创建的 XML 文件
└── ui_mainwindow.h      <-- uic 自动生成
```

##### `.ui` 文件示例（XML 结构）

```xml
<ui version="4.0">
 <class>MainWindow</class>
 <widget class="QMainWindow" name="MainWindow">
  <property name="windowTitle"><string>示例窗口</string></property>
  <widget class="QWidget" name="centralwidget">
   <layout class="QVBoxLayout" name="verticalLayout">
    <item>
     <widget class="QLineEdit" name="lineEdit"/>
    </item>
    <item>
     <widget class="QPushButton" name="pushButton">
      <property name="text"><string>点击提交</string></property>
     </widget>
    </item>
    <item>
     <widget class="QLabel" name="label">
      <property name="text"><string>等待输入...</string></property>
     </widget>
    </item>
   </layout>
  </widget>
 </widget>
</ui>
```

通过 Designer 拖拽生成了 3 个控件，并设置好名称。

##### `mainwindow.h`

```cpp
#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

class MainWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void handleInput();

private:
    Ui::MainWindow *ui;  // 指向 UI 控件集合
};
#endif // MAINWINDOW_H
```

##### `mainwindow.cpp`

```cpp
#include "mainwindow.h"
#include "ui_mainwindow.h"  // 包含自动生成的 UI 定义

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent), ui(new Ui::MainWindow) {

    ui->setupUi(this);  // 核心函数，初始化 UI

    connect(ui->pushButton, &QPushButton::clicked, this, &MainWindow::handleInput);
}

void MainWindow::handleInput() {
    QString text = ui->lineEdit->text();
    ui->label->setText("你输入了: " + text);
}

MainWindow::~MainWindow() {
    delete ui;
}
```

#### `setupUi(this)` 做了什么？

调用 `setupUi(this)` 会执行这些事情：

1. **实例化控件**（`new QLineEdit`, `new QPushButton`, `new QLabel`）
2. **设置控件名称、属性**（text、font、alignment 等）
3. **配置布局**（QVBoxLayout 并添加控件）
4. **将控件添加到主窗口中心部件中**
5. **将控件地址绑定到 `ui->控件名` 指针**

例如：

```cpp
lineEdit = new QLineEdit(centralwidget);
label = new QLabel("等待输入...", centralwidget);
```

#### `ui_mainwindow.h` 是怎么生成的？

这是 Qt 提供的 `uic` 工具的职责，**编译阶段自动把 XML 翻译为 C++ 类**。

生成内容类似：

```cpp
namespace Ui {
class MainWindow;
}

class Ui_MainWindow {
public:
    QWidget *centralwidget;
    QLineEdit *lineEdit;
    QPushButton *pushButton;
    QLabel *label;
    QVBoxLayout *verticalLayout;

    void setupUi(QMainWindow *MainWindow) {
        centralwidget = new QWidget(MainWindow);
        lineEdit = new QLineEdit(centralwidget);
        pushButton = new QPushButton("点击提交", centralwidget);
        label = new QLabel("等待输入...", centralwidget);

        verticalLayout = new QVBoxLayout(centralwidget);
        verticalLayout->addWidget(lineEdit);
        verticalLayout->addWidget(pushButton);
        verticalLayout->addWidget(label);

        MainWindow->setCentralWidget(centralwidget);
    }
};
```

生成类 `Ui_MainWindow` 中的成员变量会在 `MainWindow` 类中通过 `ui->成员名` 访问。

#### 信号与槽绑定机制

```cpp
connect(ui->pushButton, &QPushButton::clicked, this, &MainWindow::handleInput);
```

- 信号（Signal）：如 QPushButton::clicked
- 槽（Slot）：自定义的成员函数 `handleInput()`

Qt 会通过元对象系统（Meta-Object Compiler, MOC）建立运行时的连接表，实现回调。

#### 使用 Qt Designer 的优势与适用场景

优点：

- 快速原型设计
- 所见即所得
- 易于协作（UI / 逻辑分离）
- 可视化布局调整、属性编辑

注意：

- 所有控件必须设置 `objectName` 才能被 `uic` 正确绑定
- 逻辑层不要在 `.ui` 文件中写，保持解耦
- 修改 `.ui` 文件后应重新编译

#### 小结

| 阶段 | 工具/操作   | 作用              |
| ---- | ----------- | ----------------- |
| 设计 | Qt Designer | 设计 `.ui`（XML） |
| 编译 | uic         | 生成 `ui_xxx.h`   |
| 使用 | `setupUi()` | 实例化 UI         |
| 连接 | `connect()` | 绑定事件响应      |
| 运行 | `exec()`    | 启动主循环        |

### 使用 C++ 代码手动构建 UI（纯代码方式）

在 Qt 中除了使用 Qt Designer（.ui 文件）设计 UI 外，也可以完全使用 **C++ 代码手动构建 UI**。这种方式灵活、无依赖 `.ui` 文件，适合动态控件布局、跨平台项目、嵌入式开发等场景。

#### 核心思路

**手动构建 UI 的步骤：**

1. 创建窗口类并继承 `QWidget` 或 `QMainWindow`；
2. 使用构造函数中手动实例化控件；
3. 使用布局类（如 `QVBoxLayout`, `QHBoxLayout` 等）组合控件；
4. 使用 `setLayout()` 或 `setCentralWidget()` 设置布局；
5. 通过信号槽连接交互逻辑。

#### 示例：构建一个简单的登录窗口

##### 效果展示

- 标签：用户名、密码
- 输入框：QLineEdit
- 登录按钮
- 使用垂直布局组合

##### 完整代码

```cpp
// main.cpp
#include <QApplication>
#include <QWidget>
#include <QLabel>
#include <QLineEdit>
#include <QPushButton>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QMessageBox>

class LoginWidget : public QWidget {
    Q_OBJECT

public:
    LoginWidget(QWidget* parent = nullptr) : QWidget(parent) {
        // 创建控件
        QLabel* userLabel = new QLabel("用户名:");
        QLabel* passLabel = new QLabel("密码:");

        usernameEdit = new QLineEdit;
        passwordEdit = new QLineEdit;
        passwordEdit->setEchoMode(QLineEdit::Password);

        QPushButton* loginButton = new QPushButton("登录");

        // 布局
        QVBoxLayout* mainLayout = new QVBoxLayout;

        QHBoxLayout* userLayout = new QHBoxLayout;
        userLayout->addWidget(userLabel);
        userLayout->addWidget(usernameEdit);

        QHBoxLayout* passLayout = new QHBoxLayout;
        passLayout->addWidget(passLabel);
        passLayout->addWidget(passwordEdit);

        mainLayout->addLayout(userLayout);
        mainLayout->addLayout(passLayout);
        mainLayout->addWidget(loginButton);

        setLayout(mainLayout);
        setWindowTitle("登录窗口");
        resize(300, 150);

        // 信号槽
        connect(loginButton, &QPushButton::clicked, this, &LoginWidget::handleLogin);
    }

private slots:
    void handleLogin() {
        QString username = usernameEdit->text();
        QString password = passwordEdit->text();
        if (username == "admin" && password == "123456") {
            QMessageBox::information(this, "登录成功", "欢迎，" + username);
        } else {
            QMessageBox::warning(this, "登录失败", "用户名或密码错误");
        }
    }

private:
    QLineEdit* usernameEdit;
    QLineEdit* passwordEdit;
};

// 启动入口
int main(int argc, char* argv[]) {
    QApplication app(argc, argv);
    LoginWidget login;
    login.show();
    return app.exec();
}

// 类定义写在 .cpp 文件中，且用到 Q_OBJECT 宏，则需要手动 #include "xxx.moc"
#include "main.moc"
```

#### 知识点解析

##### 控件创建

控件用 `new` 创建，传入 `this` 或默认父指针。

```cpp
QPushButton* btn = new QPushButton("点击");
```

##### 布局管理

Qt 提供 `QHBoxLayout`, `QVBoxLayout`, `QGridLayout`, `QFormLayout` 等。

```cpp
QVBoxLayout* layout = new QVBoxLayout;
layout->addWidget(widget1);
layout->addWidget(widget2);
setLayout(layout); // QWidget专用
```

QMainWindow 要用：

```cpp
setCentralWidget(widget);
```

##### 信号槽连接

```cpp
connect(button, &QPushButton::clicked, this, &Class::slotFunc);
```

#### 何时用纯代码构建 UI？

| 场景               | 是否推荐纯代码       |
| ------------------ | -------------------- |
| UI 简单或动态生成  | ✅ 推荐               |
| 嵌入式、无资源系统 | ✅ 推荐               |
| 跨平台 CMake 项目  | ✅ 推荐               |
| 需要与设计分离     | ❌ 建议用 Qt Designer |
| 需要美术设计师参与 | ❌ 建议用 .ui 文件    |

#### 项目结构建议

```css
project/
├── main.cpp
├── login_widget.h
└── login_widget.cpp
```

将 UI 构建代码放在 `login_widget.*` 文件中，逻辑更清晰。

#### 扩展建议

- 配合样式表（`setStyleSheet`）自定义控件样式；
- 支持国际化（`tr()`）；
- 将控件封装为复用组件类。

### 对比

| 维度                     | Qt Designer + `.ui` 文件                            | 纯 C++ 手动构建 UI                       |
| ------------------------ | --------------------------------------------------- | ---------------------------------------- |
| **UI 构建方式**          | 图形界面拖拽控件，生成 `.ui` 文件，自动转为 C++ 类  | 完全通过 C++ 代码手动创建控件和布局      |
| **代码位置**             | UI 逻辑和展示分离，布局在 `.ui` 文件中              | UI 和逻辑耦合，所有内容都在 C++ 中       |
| **初学者友好性**         | ✅ 友好，图形化操作直观                              | ❌ 需要理解控件、布局的构造顺序和层次关系 |
| **修改 UI 的便捷性**     | ✅ 非常便捷，拖拽即可                                | ❌ 不方便，需逐行修改代码                 |
| **可读性**               | ✅ 更清晰，结构分明                                  | ❌ UI 和逻辑混在一起                      |
| **灵活性**               | ❌ 差，运行时不能动态生成复杂控件树                  | ✅ 高，可根据运行时逻辑动态构建复杂界面   |
| **生成方式**             | `uic` 工具自动将 `.ui` 文件转为头文件（`ui_xxx.h`） | 不依赖生成工具，自己写全部代码           |
| **部署复杂度**           | 需打包 `.ui` 文件或依赖 `uic` 生成的代码            | 无依赖，易于部署                         |
| **定制控件集成**         | 稍复杂，需要注册自定义控件到 Qt Designer            | 简单，自定义类直接 new 即可              |
| **适合场景**             | 设计主窗口、对话框、静态表单类 UI                   | 动态表格、复杂图形、嵌入式设备           |
| **信号槽连接**           | 可在 Designer 设置或手动写代码                      | 必须写代码手动连接                       |
| **国际化支持（`tr()`）** | ✅ 自动支持                                          | ✅ 手动写 `tr()`                          |
| **推荐搭配**             | `.ui` 文件 + `QMainWindow` 或 `QDialog`             | 继承自 `QWidget` 或其他组件类            |