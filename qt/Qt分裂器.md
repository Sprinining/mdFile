## Qt 分裂器

### QSplitter

`QSplitter` 是 Qt 框架中提供的一种布局管理控件，属于 `QtWidgets` 模块，用于**在界面中分隔多个子控件并支持用户拖动调整它们大小**，常用于需要可调节区域大小的应用，比如文件管理器、IDE 或面板式软件界面。

#### 常用方法/属性

| 方法 / 属性                                | 功能描述                                                     |
| ------------------------------------------ | ------------------------------------------------------------ |
| `addWidget(QWidget *widget)`               | 向分隔器中添加一个子控件。                                   |
| `insertWidget(int index, QWidget *widget)` | 在指定位置插入一个子控件。                                   |
| `widget(int index)`                        | 返回指定索引处的子控件。                                     |
| `count()`                                  | 返回子控件的数量。                                           |
| `indexOf(QWidget *widget)`                 | 返回指定控件在 splitter 中的索引。                           |
| `setOrientation(Qt::Orientation)`          | 设置分隔方向：`Qt::Horizontal` 或 `Qt::Vertical`。           |
| `orientation()`                            | 返回当前的分隔方向。                                         |
| `setSizes(const QList<int> &sizes)`        | 设置所有子控件的初始尺寸（像素单位）。                       |
| `sizes()`                                  | 获取当前所有子控件的尺寸列表。                               |
| `setStretchFactor(int index, int stretch)` | 设置某个子控件的拉伸因子（决定空间分配比例）。               |
| `setCollapsible(int index, bool)`          | 设置某个子控件是否可以被完全收起。                           |
| `setChildrenCollapsible(bool)`             | 设置所有子控件是否可以被收起（默认 true）。                  |
| `isCollapsible(int index)`                 | 返回某个子控件是否可折叠。                                   |
| `handle(int index)`                        | 返回指定索引处的分隔条句柄（`QSplitterHandle*`），可用于自定义样式或行为。 |
| `saveState() const`                        | 保存当前 splitter 的状态（子控件尺寸、顺序等），返回 `QByteArray`。 |
| `restoreState(const QByteArray &state)`    | 恢复之前保存的 splitter 状态。                               |
| `opaqueResize()`                           | 是否启用实时调整尺寸（默认 true，即拖动时立即生效）。        |
| `setOpaqueResize(bool opaque)`             | 设置是否启用实时调整尺寸（关闭后拖动只显示拖动线，释放后才更新）。 |
| `childrenCollapsible()`                    | 返回当前是否允许所有子控件可收起。                           |
| `handleWidth()`                            | 获取分隔条的宽度（默认 5 像素）。                            |
| `setHandleWidth(int width)`                | 设置分隔条宽度。                                             |
| `refresh()`                                | 重新布局所有子控件（不常用）。                               |
| `minimumSizeHint()`                        | 返回推荐的最小尺寸。                                         |

#### 基本用法示例

```cpp
#include <QApplication>
#include <QSplitter>
#include <QTextEdit>
#include <QVBoxLayout>
#include <QWidget>

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    QWidget window;

    // 创建一个垂直分割器
    QSplitter *splitter = new QSplitter(Qt::Vertical);

    // 添加两个 QTextEdit 控件
    splitter->addWidget(new QTextEdit("Top Widget"));
    splitter->addWidget(new QTextEdit("Bottom Widget"));

    // 设置主布局
    QVBoxLayout *layout = new QVBoxLayout;
    layout->addWidget(splitter);
    window.setLayout(layout);

    window.resize(400, 300);
    window.show();

    return app.exec();
}
```

#### 自定义样式

可以通过 `QSplitterHandle` 自定义分隔条样式，比如宽度、颜色等。也可结合 QSS 进行样式定制。

```cpp
splitter->setStyleSheet("QSplitter::handle { background-color: gray }");
```

#### 保存和恢复尺寸状态（Persistent State）

`QSplitter` 内置了两个非常重要的方法：

- `QByteArray QSplitter::saveState() const`
   获取当前分隔器的所有状态（包括子控件尺寸、顺序等），返回一个 `QByteArray`。
- `bool QSplitter::restoreState(const QByteArray &state)`
   恢复之前保存的状态，返回值表示是否成功。

#### 示例：保存状态到 `QSettings`

```cpp
#include <QApplication>
#include <QSplitter>
#include <QTextEdit>
#include <QSettings>
#include <QVBoxLayout>
#include <QWidget>

class MyWindow : public QWidget {
    QSplitter *splitter;

public:
    MyWindow() {
        splitter = new QSplitter(Qt::Horizontal);
        splitter->addWidget(new QTextEdit("Left Panel"));
        splitter->addWidget(new QTextEdit("Right Panel"));

        QVBoxLayout *layout = new QVBoxLayout;
        layout->addWidget(splitter);
        setLayout(layout);

        // 从 QSettings 恢复状态
        QSettings settings("MyCompany", "MyApp");
        splitter->restoreState(settings.value("splitterState").toByteArray());
    }

    ~MyWindow() {
        // 应用关闭时保存状态
        QSettings settings("MyCompany", "MyApp");
        settings.setValue("splitterState", splitter->saveState());
    }
};

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    MyWindow w;
    w.resize(600, 400);
    w.show();
    return app.exec();
}
```

### QSettings

`QSettings` 是 Qt 提供的一个非常实用的类，用于跨平台地**保存和读取应用程序的配置数据**（比如窗口大小、用户偏好设置、上次打开的文件路径、界面状态等）。它支持将数据持久化到系统注册表、INI 文件、或 macOS 的 plist 文件中，而无需开发者手动处理文件读写。

#### 核心特性

- **自动持久化**：程序关闭时不需要手动保存，`QSettings` 的写入是立即生效的。
- **跨平台兼容**：Windows 下默认写入注册表，Linux/macOS 下写入 `.ini` 或系统标准配置路径。
- **层级结构**：支持用“路径”的方式组织键值（如 `window/size`）。
- **支持多种数据类型**：字符串、整数、布尔值、QVariant、QByteArray、QSize、QPoint 等。

#### 基本用法

##### 写入配置

```cpp
#include <QSettings>

QSettings settings("MyCompany", "MyApp");

// 写入键值对
settings.setValue("window/size", QSize(800, 600));
settings.setValue("window/pos", QPoint(100, 100));
settings.setValue("user/rememberMe", true);
```

##### 读取配置

```cpp
QSize size = settings.value("window/size", QSize(400, 300)).toSize();
QPoint pos = settings.value("window/pos", QPoint(50, 50)).toPoint();
bool rememberMe = settings.value("user/rememberMe", false).toBool();
```

#### 构造函数形式

```cpp
QSettings settings("OrganizationName", "ApplicationName");  // 推荐写法
```

也可以手动指定 `.ini` 文件路径：

```cpp
QSettings settings("config.ini", QSettings::IniFormat);
```

默认存储路径（按平台）

| 平台    | 默认存储位置                                        |
| ------- | --------------------------------------------------- |
| Windows | 注册表 `HKEY_CURRENT_USER\Software\MyCompany\MyApp` |
| Linux   | `~/.config/MyCompany/MyApp.conf`（或 `.ini` 文件）  |
| macOS   | `~/Library/Preferences/com.MyCompany.MyApp.plist`   |

若用 `IniFormat`，会始终使用本地 `.ini` 文件，不走平台默认方式。

#### 实用方法

| 方法 / 属性                          | 说明                          |
| ------------------------------------ | ----------------------------- |
| `setValue(key, value)`               | 设置键值                      |
| `value(key, defaultValue)`           | 读取值，若不存在则返回默认值  |
| `contains(key)`                      | 检查是否存在某个键            |
| `remove(key)`                        | 删除某个键                    |
| `clear()`                            | 清空所有设置项                |
| `beginGroup("group")` / `endGroup()` | 设置/退出分组（用于逻辑归类） |
| `childKeys()`                        | 获取当前组下所有键            |
| `childGroups()`                      | 获取当前组下所有子组          |
| `sync()`                             | 强制将缓存中的设置写入磁盘    |

#### 高级用法示例：使用分组

```cpp
settings.beginGroup("MainWindow");
settings.setValue("size", QSize(800, 600));
settings.setValue("pos", QPoint(100, 100));
settings.endGroup();
```

读取时也一样：

```cpp
settings.beginGroup("MainWindow");
QSize size = settings.value("size").toSize();
QPoint pos = settings.value("pos").toPoint();
settings.endGroup();
```

### 使用分裂器排布简易 HTML 查看器

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
    <width>630</width>
    <height>350</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <layout class="QVBoxLayout" name="verticalLayout" stretch="1,0">
   <item>
    <widget class="QSplitter" name="splitter">
     <property name="styleSheet">
      <string notr="true">QSplitter::handle {   
    background-color: rgb(0, 255, 127);
}</string>
     </property>
     <property name="orientation">
      <enum>Qt::Orientation::Horizontal</enum>
     </property>
     <widget class="QTextBrowser" name="textBrowser"/>
     <widget class="QPlainTextEdit" name="plainTextEdit"/>
    </widget>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout">
     <item>
      <widget class="QPushButton" name="btnBackward">
       <property name="text">
        <string>后退</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnForward">
       <property name="text">
        <string>前进</string>
       </property>
      </widget>
     </item>
     <item>
      <spacer name="horizontalSpacer">
       <property name="orientation">
        <enum>Qt::Orientation::Horizontal</enum>
       </property>
       <property name="sizeHint" stdset="0">
        <size>
         <width>40</width>
         <height>20</height>
        </size>
       </property>
      </spacer>
     </item>
     <item>
      <widget class="QPushButton" name="btnOpen">
       <property name="text">
        <string>打开HTML</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
  </layout>
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
    void on_btnOpen_clicked();
    void on_textBrowser_backwardAvailable(bool arg1);
    void on_textBrowser_forwardAvailable(bool arg1);
    void on_textBrowser_textChanged();

  private:
    Ui::Widget* ui;
    void saveSettings();
    void loadSettings();

    // QWidget interface
  protected:
    void closeEvent(QCloseEvent* event) override;
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"

#include <QFileDialog>
#include <QSettings>
#include <QUrl>

#include "./ui_widget.h"

// 构造函数：初始化 UI 组件并连接信号与槽函数
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this); // 设置 UI

    ui->plainTextEdit->setReadOnly(true);        // 设置 plainTextEdit 为只读，用于显示 HTML 源码
    ui->textBrowser->setOpenExternalLinks(true); // 启用超链接的外部打开功能（在浏览器中打开）
    ui->btnBackward->setEnabled(false);          // 初始化时“后退”按钮禁用
    ui->btnForward->setEnabled(false);           // 初始化时“前进”按钮禁用

    // 连接按钮点击信号与 QTextBrowser 的后退/前进槽函数
    connect(ui->btnBackward, &QPushButton::clicked, ui->textBrowser, &QTextBrowser::backward);
    connect(ui->btnForward, &QPushButton::clicked, ui->textBrowser, &QTextBrowser::forward);

    loadSettings();
}

// 析构函数：释放 UI 资源
Widget::~Widget() {
    delete ui;
}

// 打开按钮点击事件：选择 HTML 文件并加载到 QTextBrowser 中
void Widget::on_btnOpen_clicked() {
    // 使用 QFileDialog 打开一个文件选择对话框，获取用户选择的 HTML 文件的 URL
    // 参数说明：
    // 1. this：父窗口指针，指定这个对话框的父对象为当前
    // Widget，确保对话框在当前窗口之上弹出
    // 2. "open HTML"：对话框标题，用于提示用户当前操作是“打开 HTML 文件”
    // 3. QUrl()：初始路径，传入空 QUrl 表示使用默认目录（可用
    // QUrl::fromLocalFile("路径") 指定初始目录）
    // 4. "HTML files(*.htm *.html)"：过滤器字符串，仅显示 *.htm 和 *.html
    // 后缀的文件
    QUrl urlFile = QFileDialog::getOpenFileUrl(this, "open HTML", QUrl(), "HTML files(*.htm *.html)");

           // 判断用户是否实际选择了文件（即返回的 URL 非空）
    if (!urlFile.isEmpty()) {
        qDebug() << urlFile;                 // 输出选择的文件 URL，用于调试
        ui->textBrowser->setSource(urlFile); // 将选择的 HTML 文件加载到 QTextBrowser 中显示
    }
}

// 当 textBrowser 可以后退时，启用“后退”按钮
void Widget::on_textBrowser_backwardAvailable(bool arg1) {
    ui->btnBackward->setEnabled(arg1);
}

// 当 textBrowser 可以前进时，启用“前进”按钮
void Widget::on_textBrowser_forwardAvailable(bool arg1) {
    ui->btnForward->setEnabled(arg1);
}

// 当 textBrowser 内容变化时，更新 plainTextEdit 显示 HTML 源码
void Widget::on_textBrowser_textChanged() {
    QString strHtml = ui->textBrowser->toHtml(); // 获取 HTML 内容
    ui->plainTextEdit->setPlainText(strHtml);    // 显示在 plainTextEdit 中
}

// 当窗口关闭时触发的事件处理函数
void Widget::closeEvent(QCloseEvent* event) {
    // 保存当前窗口及控件的状态到设置文件
    saveSettings();
}

// 保存窗口及控件状态到配置文件
void Widget::saveSettings() {
    // 创建 QSettings 对象，参数是组织名和应用名，数据存储路径与注册表或配置文件相关
    QSettings settings("QtGuide", "SimpleBrowser");

    // 保存主窗口的几何信息（位置和大小）
    QByteArray baMainWidget = this->saveGeometry();

    // 保存分割器（splitter）的状态（布局信息）
    QByteArray baSplitter = ui->splitter->saveState();

    // 获取当前文本浏览器的 URL 来源
    QUrl urlSrc = ui->textBrowser->source();

    // 将以上信息写入配置文件或注册表
    settings.setValue("MainWidget", baMainWidget);
    settings.setValue("Splitter", baSplitter);
    settings.setValue("URL", urlSrc);
}

// 读取配置文件，恢复窗口和控件的状态
void Widget::loadSettings() {
    // 创建 QSettings 对象，路径和保存时相同
    QSettings settings("QtGuide", "SimpleBrowser");

    // 如果存在保存的主窗口几何信息，则恢复窗口位置和大小
    if (settings.contains("MainWidget")) {
        QByteArray baMainWidget = settings.value("MainWidget").toByteArray();
        this->restoreGeometry(baMainWidget);
    }

    // 如果存在保存的分割器状态，则恢复布局
    if (settings.contains("Splitter")) {
        QByteArray baSplitter = settings.value("Splitter").toByteArray();
        ui->splitter->restoreState(baSplitter);
    }

    // 如果存在保存的 URL，则设置文本浏览器显示该 URL
    if (settings.contains("URL")) {
        QUrl urlSrc = settings.value("URL").toUrl();
        ui->textBrowser->setSource(urlSrc);
    }
}
```

### 分裂器内间接添加布局器的示例

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
    <width>600</width>
    <height>480</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <layout class="QVBoxLayout" name="verticalLayout_2">
   <item>
    <widget class="QSplitter" name="splitter_2">
     <property name="styleSheet">
      <string notr="true">QSplitter::handle {   
    background-color: rgb(0, 255, 127);
}</string>
     </property>
     <property name="orientation">
      <enum>Qt::Orientation::Vertical</enum>
     </property>
     <widget class="QSplitter" name="splitter">
      <property name="sizePolicy">
       <sizepolicy hsizetype="Expanding" vsizetype="Expanding">
        <horstretch>0</horstretch>
        <verstretch>4</verstretch>
       </sizepolicy>
      </property>
      <property name="styleSheet">
       <string notr="true">QSplitter::handle {   
    background-color: rgb(0, 255, 127);
}</string>
      </property>
      <property name="orientation">
       <enum>Qt::Orientation::Horizontal</enum>
      </property>
      <widget class="QTextEdit" name="textEdit">
       <property name="html">
        <string>&lt;!DOCTYPE HTML PUBLIC &quot;-//W3C//DTD HTML 4.0//EN&quot; &quot;http://www.w3.org/TR/REC-html40/strict.dtd&quot;&gt;
&lt;html&gt;&lt;head&gt;&lt;meta name=&quot;qrichtext&quot; content=&quot;1&quot; /&gt;&lt;meta charset=&quot;utf-8&quot; /&gt;&lt;style type=&quot;text/css&quot;&gt;
p, li { white-space: pre-wrap; }
hr { height: 1px; border-width: 0; }
li.unchecked::marker { content: &quot;\2610&quot;; }
li.checked::marker { content: &quot;\2612&quot;; }
&lt;/style&gt;&lt;/head&gt;&lt;body style=&quot; font-family:'Microsoft YaHei UI'; font-size:9pt; font-weight:400; font-style:normal;&quot;&gt;
&lt;p style=&quot; margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;&quot;&gt;编辑器&lt;/p&gt;&lt;/body&gt;&lt;/html&gt;</string>
       </property>
      </widget>
      <widget class="QWidget" name="">
       <layout class="QVBoxLayout" name="verticalLayout">
        <item>
         <widget class="QPushButton" name="pushButton">
          <property name="text">
           <string>功能1</string>
          </property>
         </widget>
        </item>
        <item>
         <widget class="QPushButton" name="pushButton_2">
          <property name="text">
           <string>功能2</string>
          </property>
         </widget>
        </item>
        <item>
         <widget class="QPushButton" name="pushButton_3">
          <property name="text">
           <string>功能3</string>
          </property>
         </widget>
        </item>
       </layout>
      </widget>
     </widget>
     <widget class="QTextBrowser" name="textBrowser">
      <property name="sizePolicy">
       <sizepolicy hsizetype="Expanding" vsizetype="Expanding">
        <horstretch>0</horstretch>
        <verstretch>1</verstretch>
       </sizepolicy>
      </property>
      <property name="html">
       <string>&lt;!DOCTYPE HTML PUBLIC &quot;-//W3C//DTD HTML 4.0//EN&quot; &quot;http://www.w3.org/TR/REC-html40/strict.dtd&quot;&gt;
&lt;html&gt;&lt;head&gt;&lt;meta name=&quot;qrichtext&quot; content=&quot;1&quot; /&gt;&lt;meta charset=&quot;utf-8&quot; /&gt;&lt;style type=&quot;text/css&quot;&gt;
p, li { white-space: pre-wrap; }
hr { height: 1px; border-width: 0; }
li.unchecked::marker { content: &quot;\2610&quot;; }
li.checked::marker { content: &quot;\2612&quot;; }
&lt;/style&gt;&lt;/head&gt;&lt;body style=&quot; font-family:'Microsoft YaHei UI'; font-size:9pt; font-weight:400; font-style:normal;&quot;&gt;
&lt;p style=&quot; margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;&quot;&gt;提示信息&lt;/p&gt;&lt;/body&gt;&lt;/html&gt;</string>
      </property>
     </widget>
    </widget>
   </item>
  </layout>
 </widget>
 <resources/>
 <connections/>
</ui>
```

#### ui_widget.h

```cpp
/********************************************************************************
** Form generated from reading UI file 'widget.ui'
**
** Created by: Qt User Interface Compiler version 6.9.0
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_WIDGET_H
#define UI_WIDGET_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QSplitter>
#include <QtWidgets/QTextBrowser>
#include <QtWidgets/QTextEdit>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_Widget
{
public:
    QVBoxLayout *verticalLayout_2;   // 最外层垂直布局，管理整个窗口的控件排布
    QSplitter *splitter_2;           // 垂直分割器，垂直分割两个区域
    QSplitter *splitter;             // 水平分割器，水平分割文本编辑区和按钮区
    QTextEdit *textEdit;             // 文本编辑控件，位于 splitter 左侧
    QWidget *widget;                 // splitter 右侧的容器 widget，用于承载按钮的布局
    QVBoxLayout *verticalLayout;     // widget 中的垂直布局，排列多个按钮
    QPushButton *pushButton;         // 按钮1
    QPushButton *pushButton_2;       // 按钮2
    QPushButton *pushButton_3;       // 按钮3
    QTextBrowser *textBrowser;       // 文本浏览控件，位于 splitter_2 的下方区域

    void setupUi(QWidget *Widget)
    {
        if (Widget->objectName().isEmpty())
            Widget->setObjectName("Widget");
        Widget->resize(600, 480);

        // 创建最外层垂直布局，放入 splitter_2
        verticalLayout_2 = new QVBoxLayout(Widget);
        verticalLayout_2->setObjectName("verticalLayout_2");

        // 创建垂直方向的分割器 splitter_2，分割上半部分（splitter）和下半部分（textBrowser）
        splitter_2 = new QSplitter(Widget);
        splitter_2->setObjectName("splitter_2");
        splitter_2->setStyleSheet(QString::fromUtf8("QSplitter::handle {   \n"
"    background-color: rgb(0, 255, 127);\n"
"}"));
        splitter_2->setOrientation(Qt::Orientation::Vertical);

        // 创建水平方向的分割器 splitter，分割左边的文本编辑和右边按钮区域
        splitter = new QSplitter(splitter_2);
        splitter->setObjectName("splitter");
        QSizePolicy sizePolicy(QSizePolicy::Policy::Expanding, QSizePolicy::Policy::Expanding);
        sizePolicy.setHorizontalStretch(0);
        sizePolicy.setVerticalStretch(4);
        sizePolicy.setHeightForWidth(splitter->sizePolicy().hasHeightForWidth());
        splitter->setSizePolicy(sizePolicy);
        splitter->setStyleSheet(QString::fromUtf8("QSplitter::handle {   \n"
"    background-color: rgb(0, 255, 127);\n"
"}"));
        splitter->setOrientation(Qt::Orientation::Horizontal);

        // 创建文本编辑控件，添加到 splitter 左侧
        textEdit = new QTextEdit(splitter);
        textEdit->setObjectName("textEdit");

        // 创建一个 QWidget（container widget），用来包裹按钮布局
        // 注意：QSplitter 只能直接放置 QWidget 类型的控件，
        // 不能直接放布局，所以这里创建一个空的 QWidget 作为容器
        widget = new QWidget(splitter);
        widget->setObjectName("widget");

        // 在 widget 中创建垂直布局，用于排列按钮
        verticalLayout = new QVBoxLayout(widget);
        verticalLayout->setObjectName("verticalLayout");
        verticalLayout->setContentsMargins(0, 0, 0, 0);  // 去除边距，使按钮紧凑排列

        // 创建三个按钮，并添加到 widget 的垂直布局中
        pushButton = new QPushButton(widget);
        pushButton->setObjectName("pushButton");
        verticalLayout->addWidget(pushButton);

        pushButton_2 = new QPushButton(widget);
        pushButton_2->setObjectName("pushButton_2");
        verticalLayout->addWidget(pushButton_2);

        pushButton_3 = new QPushButton(widget);
        pushButton_3->setObjectName("pushButton_3");
        verticalLayout->addWidget(pushButton_3);

        // 把包裹按钮的 widget 加入 splitter 的右侧
        splitter->addWidget(widget);

        // 把 splitter（包含左侧文本编辑和右侧按钮区域）加入 splitter_2 的上部
        splitter_2->addWidget(splitter);

        // 创建文本浏览控件，放入 splitter_2 的下方
        textBrowser = new QTextBrowser(splitter_2);
        textBrowser->setObjectName("textBrowser");
        QSizePolicy sizePolicy1(QSizePolicy::Policy::Expanding, QSizePolicy::Policy::Expanding);
        sizePolicy1.setHorizontalStretch(0);
        sizePolicy1.setVerticalStretch(1);
        sizePolicy1.setHeightForWidth(textBrowser->sizePolicy().hasHeightForWidth());
        textBrowser->setSizePolicy(sizePolicy1);

        // 添加文本浏览控件到底部分割器 splitter_2 中
        splitter_2->addWidget(textBrowser);

        // 把 splitter_2 添加到最外层的垂直布局中
        verticalLayout_2->addWidget(splitter_2);

        retranslateUi(Widget);

        QMetaObject::connectSlotsByName(Widget);
    } // setupUi

    void retranslateUi(QWidget *Widget)
    {
        Widget->setWindowTitle(QCoreApplication::translate("Widget", "Widget", nullptr));
        textEdit->setHtml(QCoreApplication::translate("Widget", "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n"
"<html><head><meta name=\"qrichtext\" content=\"1\" /><meta charset=\"utf-8\" /><style type=\"text/css\">\n"
"p, li { white-space: pre-wrap; }\n"
"hr { height: 1px; border-width: 0; }\n"
"li.unchecked::marker { content: \"\\2610\"; }\n"
"li.checked::marker { content: \"\\2612\"; }\n"
"</style></head><body style=\" font-family:'Microsoft YaHei UI'; font-size:9pt; font-weight:400; font-style:normal;\">\n"
"<p style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\">\347\274\226\350\276\221\345\231\250</p></body></html>", nullptr));
        pushButton->setText(QCoreApplication::translate("Widget", "\345\212\237\350\203\2751", nullptr));
        pushButton_2->setText(QCoreApplication::translate("Widget", "\345\212\237\350\203\2752", nullptr));
        pushButton_3->setText(QCoreApplication::translate("Widget", "\345\212\237\350\203\2753", nullptr));
        textBrowser->setHtml(QCoreApplication::translate("Widget", "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n"
"<html><head><meta name=\"qrichtext\" content=\"1\" /><meta charset=\"utf-8\" /><style type=\"text/css\">\n"
"p, li { white-space: pre-wrap; }\n"
"hr { height: 1px; border-width: 0; }\n"
"li.unchecked::marker { content: \"\\2610\"; }\n"
"li.checked::marker { content: \"\\2612\"; }\n"
"</style></head><body style=\" font-family:'Microsoft YaHei UI'; font-size:9pt; font-weight:400; font-style:normal;\">\n"
"<p style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\">\346\217\220\347\244\272\344\277\241\346\201\257</p></body></html>", nullptr));
    } // retranslateUi

};

namespace Ui {
    class Widget: public Ui_Widget {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_WIDGET_H
```

- `QSplitter` 只能直接放置 `QWidget`，而不能直接放置布局，所以自动生成的代码中会创建一个空的 `QWidget` 作为容器，再给这个 `QWidget` 添加布局。

- 水平 `splitter` 左边是 `QTextEdit`，右边是一个包裹了垂直布局的 `QWidget`，布局中放了3个按钮。

- 垂直 `splitter_2` 上半部分是上述水平 `splitter`，下半部分是 `QTextBrowser`。
