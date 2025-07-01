## QUiLoader 动态加载 ui 文件

在 Qt 中，`QUiLoader` 是一个用于**在运行时动态加载 `.ui` 文件**的类，属于模块 `QtUiTools`。相比于常规的 `uic` 工具将 `.ui` 编译为 `.h/.cpp`，`QUiLoader` 提供了更灵活的方式，例如用于插件化、换肤、动态模块加载等场景。

### 什么是 QUiLoader？

`QUiLoader` 是 Qt 提供的一个类，用来**在运行时加载 .ui 文件并构造对应的 QWidget 层次结构**。

它来自 `QtUiTools` 模块，本质上是 Qt 的 UI 描述文件（XML）解析器 + 控件工厂。

### 和传统 `setupUi(this)` 的区别

| 对比项         | `setupUi(this)` （静态绑定）         | `QUiLoader`（动态加载）                     |
| -------------- | ------------------------------------ | ------------------------------------------- |
| 加载时机       | 编译时 uic 转换为 C++ 并编译         | 运行时解析 `.ui` 文件                       |
| 原理           | uic 生成 `ui_xxx.h` 并通过指针初始化 | QUiLoader 运行时打开 .ui → XML → QWidget 树 |
| 热更新 UI 支持 | 不支持                               | 可以修改 `.ui` 文件直接热加载               |
| 使用自由度     | 高度依赖对象结构                     | 控件名查找 + layout 管理                    |

### QUiLoader 加载 `.ui` 的完整流程

#### 源代码

##### 项目结构

```css
myloader/
├── main.cpp
├── widget.h
├── widget.cpp
├── widget.ui
├── resources.qrc
├── CMakeLists.txt
```

##### widget.ui

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>Form</class>
 <widget class="QWidget" name="Form">
  <property name="geometry">
   <rect><x>0</x><y>0</y><width>300</width><height>150</height></rect>
  </property>
  <layout class="QVBoxLayout" name="verticalLayout">
   <item>
    <widget class="QPushButton" name="pushButton">
     <property name="text"><string>Click Me</string></property>
    </widget>
   </item>
  </layout>
 </widget>
 <resources/>
 <connections/>
</ui>
```

##### widget.h

```cpp
#ifndef WIDGET_H
#define WIDGET_H

#include <QWidget>

class Widget : public QWidget {
    Q_OBJECT
public:
    explicit Widget(QWidget *parent = nullptr);
};

#endif // WIDGET_H
```

##### widget.cpp

```cpp
#include "widget.h"
#include <QDebug>
#include <QFile>
#include <QPushButton>
#include <QVBoxLayout>
#include <QtUiTools/QUiLoader>

Widget::Widget(QWidget *parent) : QWidget(parent) {
    // 加载 .ui 文件
    QUiLoader loader;
    QFile file(":/widget.ui"); // 使用 qrc 资源路径或直接写文件路径
    if (!file.open(QFile::ReadOnly)) {
        qWarning() << "Failed to open .ui file";
        return;
    }

    QWidget *form = loader.load(&file, this);
    file.close();

    if (!form) {
        qWarning() << "Failed to load .ui";
        return;
    }

    // 使用 layout 包装
    QVBoxLayout *layout = new QVBoxLayout(this);
    layout->addWidget(form);
    setLayout(layout);

    // 连接信号槽
    QPushButton *btn = form->findChild<QPushButton *>("pushButton");
    if (btn) {
        connect(btn, &QPushButton::clicked, [] { qDebug() << "Button clicked!"; });
    }
}
```

##### main.cpp

```cpp
#include "widget.h"
#include <QApplication>

int main(int argc, char *argv[]) {
    QApplication a(argc, argv);
    Widget w;
    w.show();
    return a.exec();
}
```

#### 代码片段

```cpp
QFile file(":/widget.ui");
file.open(QFile::ReadOnly);
QUiLoader loader;
QWidget *form = loader.load(&file, this);
```

##### 步骤 1：打开 UI 文件（XML 格式）

- Qt 的 `.ui` 是一个 **XML 文档**，内部描述了界面控件的层级结构、属性、布局等。
- 示例片段（略）：

```xml
<ui version="4.0">
  <widget class="QWidget" name="Form">
    <layout class="QVBoxLayout" name="verticalLayout">
      <item>
        <widget class="QPushButton" name="pushButton">
          <property name="text"><string>Click Me</string></property>
        </widget>
      </item>
    </layout>
  </widget>
</ui>
```

##### 步骤 2：`QUiLoader::load()` 开始解析

`loader.load(&file, this)` 执行了几个关键动作：

加载 XML 文档

- QUiLoader 内部使用 `QXmlStreamReader` 将 `.ui` 文件读入。

创建控件对象

- 它通过控件名 `"QPushButton"`，调用 `QMetaObject::newInstance()` 来动态构建控件：

```cpp
QWidget *widget = QMetaObject::newInstance("QPushButton");
```

- 并递归构建所有子控件，设置属性（如 text），布局信息等。

设置父子关系

- 所有控件通过 `setParent()` 正确嵌套，形成 QWidget 树。

##### 步骤 3：返回最外层的 QWidget 指针

最终拿到的是 `.ui` 文件最外层那个 `<widget class="QWidget">` 对应的 `QWidget*` 对象。

也就是说：

```cpp
QWidget *form = loader.load(...);
```

这个 `form` 实际上就等价于自己设计的 UI 界面。

##### 步骤 4：手动将 `form` 添加到主窗口中显示

```cpp
QVBoxLayout *layout = new QVBoxLayout(this);
layout->addWidget(form);
setLayout(layout);
```

这是完成显示的关键步骤：

- `form` 被添加到主窗口（`Widget`）的布局中
- 否则它虽然被创建了，但不会被显示

##### 步骤 5：通过 `findChild()` 获取内部控件

```cpp
QPushButton *btn = form->findChild<QPushButton*>("pushButton");
```

由于 `QUiLoader` 不会自动生成 `ui->pushButton` 成员，所以需要手动查找。

这是 Qt 的元对象系统（QObject + objectName）提供的动态控件访问方式。

### 资源路径 VS 本地路径

```cpp
QFile file(":/widget.ui");
```

使用的是 Qt 的资源系统（`qrc`），它的优点是：

- `.ui` 被打包进可执行文件，部署方便
- 路径写成 `:/` 前缀表示从资源系统加载

替代方式是直接读取磁盘路径（如 `QFile("widget.ui")`），适合调试或热更。

### 自定义控件支持机制

如果在 `.ui` 里用了自定义控件（如 `MyWidget`），`QUiLoader` 默认识别不了。

这时需要继承 `QUiLoader` 并重载 `createWidget()`：

```cpp
class MyLoader : public QUiLoader {
protected:
    QWidget *createWidget(const QString &className, QWidget *parent, const QString &name) override {
        if (className == "MyCustomWidget")
            return new MyCustomWidget(parent);
        return QUiLoader::createWidget(className, parent, name);
    }
};
```

然后使用自定义的 loader 代替默认的：

```cpp
MyLoader loader;
QWidget *form = loader.load(&file, this);
```

### 实际用途

| 用途场景             | 好处                                                     |
| -------------------- | -------------------------------------------------------- |
| UI 热更新            | `.ui` 文件可以不重编译直接换                             |
| 插件式界面           | 插件提供 UI 文件，自主加载                               |
| 前后端分离           | UI 由设计师交付 `.ui`，程序员动态接入                    |
| 多界面快速切换       | 多个 `.ui` 文件动态切换，无需链接所有 UI 类              |
| 轻量工具脚本引擎集成 | PyQt/PySide 等支持动态加载 `.ui`，无需 Python 编译器桥接 |

### 缺点

| 缺点               | 影响或后果                          |
| ------------------ | ----------------------------------- |
| 性能开销           | 程序启动慢，界面复杂时体验差        |
| 缺少编译时类型检查 | 容易拼写错误，运行时崩溃            |
| 自定义控件支持麻烦 | 需要重写 createWidget，增加维护成本 |
| 资源文件管理复杂   | 需额外管理 qrc 或文件路径           |
| 功能支持不完整     | 部分控件和特性无法正确加载          |
| 信号槽需手动连接   | 开发工作量增加，易出错              |
| 代码维护难度增加   | 冗长且不利于代码智能提示和团队协作  |
