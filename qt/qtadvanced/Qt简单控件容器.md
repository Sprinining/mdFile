## Qt 简单控件容器

### Widget 容器

在 Qt 中，`QWidget` 不仅可以作为控件本身（例如标签、按钮），也可以作为 **其他控件的容器（容纳子控件）**，实现界面的布局组织和父子关系管理。

#### 容器功能核心概念

##### 父子关系

- `QWidget` 可以作为父控件，其他 `QWidget`（如按钮、标签）可以作为其子控件。

- 创建子控件时，将父控件传入构造函数：

```cpp
QWidget* parentWidget = new QWidget;
QPushButton* btn = new QPushButton("Click Me", parentWidget);  // btn 是 parentWidget 的子控件
```

##### 自动管理子控件生命周期

- 子控件会随着父控件的销毁自动销毁（不需要手动 delete）。

- `QWidget` 负责绘制所有子控件。

##### 布局管理器（Layout）

要让容器合理地排布子控件，**必须使用布局管理器**（例如 `QVBoxLayout`, `QHBoxLayout`, `QGridLayout` 等）：

```cpp
QVBoxLayout* layout = new QVBoxLayout(parentWidget);
layout->addWidget(new QLabel("Name:"));
layout->addWidget(new QLineEdit);
layout->addWidget(new QPushButton("Submit"));
```

设置布局：

```cpp
parentWidget->setLayout(layout);
```

#### 实用功能

| 功能                | 方法/说明                                          |
| ------------------- | -------------------------------------------------- |
| 添加子控件          | 构造函数中指定父控件，或使用 `layout->addWidget()` |
| 设置背景色/样式     | `setStyleSheet()`                                  |
| 设置尺寸策略        | `setSizePolicy()`                                  |
| 控制显示/隐藏子控件 | `childWidget->hide()` / `show()`                   |
| 获取所有子控件      | `findChildren<QWidget*>()`                         |
| 自定义布局/绘图     | 重写 `paintEvent()`，可以自定义绘制容器背景等      |

#### 示例：创建一个表单容器

```cpp
QWidget* formWidget = new QWidget;

QFormLayout* formLayout = new QFormLayout;
formLayout->addRow("Username:", new QLineEdit);
formLayout->addRow("Password:", new QLineEdit);
formLayout->addWidget(new QPushButton("Login"));

formWidget->setLayout(formLayout);
formWidget->show();
```

### Frame 容器

在 Qt 中，`QFrame` 是继承自 `QWidget` 的一个特殊容器控件，**它的主要作用是作为一个带有边框的容器，用于视觉上的分组和装饰**。可以把它看作一个“有外框的 QWidget”。

适合用来：

- 分隔界面区域；
- 包裹和组织一组控件；
- 提供带边框或凹凸效果的外观；
- 可作为自定义控件或复合控件的基础。

它**既可以独立使用，也可以作为其他控件的父容器**。

#### 常见用法示意

```cpp
QFrame* frame = new QFrame(this);
frame->setFrameShape(QFrame::Box);           // 设置边框形状为方框
frame->setFrameShadow(QFrame::Sunken);       // 设置边框阴影为下凹
frame->setLineWidth(2);                      // 设置边框宽度

QVBoxLayout* layout = new QVBoxLayout(frame); // 给 frame 添加子控件布局
layout->addWidget(new QLabel("用户名："));
layout->addWidget(new QLineEdit());
```

#### QFrame 核心属性和方法

| 方法/属性           | 说明                                                |
| ------------------- | --------------------------------------------------- |
| `setFrameShape()`   | 设置边框形状，如 Box、HLine、VLine、Panel           |
| `setFrameShadow()`  | 设置边框阴影样式，如 Raised（凸起）、Sunken（凹下） |
| `setLineWidth()`    | 设置边框的粗细                                      |
| `setMidLineWidth()` | 设置双线边框中间线宽度（用于 Panel）                |
| `frameRect()`       | 获取实际绘制区域的矩形范围                          |
| `setStyleSheet()`   | 设置样式（比如背景颜色、边框颜色）                  |

#### 可选的边框形状（`QFrame::Shape`）

| 枚举值                | 效果                     |
| --------------------- | ------------------------ |
| `QFrame::NoFrame`     | 无边框（默认）           |
| `QFrame::Box`         | 普通方框                 |
| `QFrame::Panel`       | 面板样式（常用于对话框） |
| `QFrame::StyledPanel` | 使用样式表样式           |
| `QFrame::HLine`       | 水平线（分隔条）         |
| `QFrame::VLine`       | 垂直线（分隔条）         |

#### 边框阴影样式（`QFrame::Shadow`）

| 枚举值           | 效果               |
| ---------------- | ------------------ |
| `QFrame::Plain`  | 无阴影，仅纯色线条 |
| `QFrame::Raised` | 看起来凸出于背景   |
| `QFrame::Sunken` | 看起来凹陷进背景   |

#### 示例：创建分组容器

```cpp
QFrame* group = new QFrame(this);
group->setFrameShape(QFrame::Panel);
group->setFrameShadow(QFrame::Raised);
group->setLineWidth(3);

QVBoxLayout* layout = new QVBoxLayout(group);
layout->addWidget(new QLabel("配置项："));
layout->addWidget(new QCheckBox("启用自动保存"));
```

#### QFrame vs QWidget 容器对比

| 特性           | QWidget          | QFrame                 |
| -------------- | ---------------- | ---------------------- |
| 是否有边框     | ❌ 默认无         | ✅ 支持多种边框样式     |
| 可作为容器使用 | ✅ 是             | ✅ 是                   |
| 视觉装饰能力   | 中（需手写样式） | 强（支持内建形状阴影） |
| 常用场景       | 任意控件容器     | 分隔、分组、装饰用     |

### 示例：Frame 展示

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
    <width>320</width>
    <height>320</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <layout class="QVBoxLayout" name="verticalLayout_2">
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout">
     <item>
      <widget class="QWidget" name="widget1" native="true">
       <layout class="QVBoxLayout" name="verticalLayout">
        <item>
         <widget class="QRadioButton" name="radioButtonNull">
          <property name="text">
           <string>Null</string>
          </property>
         </widget>
        </item>
        <item>
         <widget class="QRadioButton" name="radioButtonRed">
          <property name="text">
           <string>Red</string>
          </property>
         </widget>
        </item>
        <item>
         <widget class="QRadioButton" name="radioButtonBlue">
          <property name="text">
           <string>Blue</string>
          </property>
         </widget>
        </item>
        <item>
         <widget class="QRadioButton" name="radioButtonGreen">
          <property name="text">
           <string>Green</string>
          </property>
         </widget>
        </item>
       </layout>
      </widget>
     </item>
     <item>
      <widget class="QWidget" name="widget" native="true">
       <layout class="QFormLayout" name="formLayout">
        <item row="0" column="0">
         <widget class="QLabel" name="label">
          <property name="text">
           <string>LineWidth</string>
          </property>
         </widget>
        </item>
        <item row="0" column="1">
         <widget class="QSpinBox" name="spinBoxLineWidth"/>
        </item>
        <item row="1" column="0">
         <widget class="QLabel" name="label_2">
          <property name="text">
           <string>MidLineWidth</string>
          </property>
         </widget>
        </item>
        <item row="1" column="1">
         <widget class="QSpinBox" name="spinBoxMidLineWidth"/>
        </item>
        <item row="2" column="0">
         <widget class="QLabel" name="label_3">
          <property name="text">
           <string>FrameShape</string>
          </property>
         </widget>
        </item>
        <item row="2" column="1">
         <widget class="QComboBox" name="comboBoxFrameShape"/>
        </item>
        <item row="3" column="0">
         <widget class="QLabel" name="label_4">
          <property name="text">
           <string>FrameShadow</string>
          </property>
         </widget>
        </item>
        <item row="3" column="1">
         <widget class="QComboBox" name="comboBoxFrameShadow"/>
        </item>
       </layout>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <widget class="QFrame" name="frameTest">
     <property name="frameShape">
      <enum>QFrame::Shape::StyledPanel</enum>
     </property>
     <property name="frameShadow">
      <enum>QFrame::Shadow::Raised</enum>
     </property>
    </widget>
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

#include <QFrame>
#include <QList>
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
    void initControls();

  private slots:
    void on_radioButtonNull_clicked();

    void on_radioButtonRed_clicked();

    void on_radioButtonBlue_clicked();

    void on_radioButtonGreen_clicked();

    void on_spinBoxLineWidth_valueChanged(int arg1);

    void on_spinBoxMidLineWidth_valueChanged(int arg1);

    void on_comboBoxFrameShape_currentIndexChanged(int index);

    void on_comboBoxFrameShadow_currentIndexChanged(int index);

  private:
    Ui::Widget* ui;
    // 保存 FrameShape
    QList<QFrame::Shape> m_listFrameShape;
    // 保存 FrameShadow
    QList<QFrame::Shadow> m_listFrameShadow;
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"

// 构造函数：初始化 UI 界面和控件设置
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this); // 设置 UI
    initControls();    // 初始化控件的状态和属性
}

// 析构函数：释放 UI 占用的资源
Widget::~Widget() {
    delete ui;
}

// 初始化控件
void Widget::initControls() {
    // 设置默认选中的颜色为“无背景色”
    ui->radioButtonNull->setChecked(true);

    // 配置 Line Width 的 SpinBox 范围和初始值
    ui->spinBoxLineWidth->setRange(0, 27);
    ui->spinBoxLineWidth->setValue(1);

    // 配置 Mid Line Width 的 SpinBox 范围和初始值
    ui->spinBoxMidLineWidth->setRange(0, 27);
    ui->spinBoxMidLineWidth->setValue(0);

    // Frame Shape 列表，顺序与 comboBox 条目对应
    m_listFrameShape << QFrame::NoFrame << QFrame::Box << QFrame::Panel << QFrame::WinPanel << QFrame::HLine << QFrame::VLine << QFrame::StyledPanel;

    // comboBoxFrameShape 添加各个边框形状选项
    ui->comboBoxFrameShape->addItem("NoFrame");
    ui->comboBoxFrameShape->addItem("Box");
    ui->comboBoxFrameShape->addItem("Panel");
    ui->comboBoxFrameShape->addItem("WinPanel");
    ui->comboBoxFrameShape->addItem("HLine");
    ui->comboBoxFrameShape->addItem("VLine");
    ui->comboBoxFrameShape->addItem("StyledPanel");

    // 设置默认选择 StyledPanel
    ui->comboBoxFrameShape->setCurrentIndex(6);

    // Frame Shadow 列表，顺序与 comboBox 条目对应
    m_listFrameShadow << QFrame::Plain << QFrame::Raised << QFrame::Sunken;

    // comboBoxFrameShadow 添加阴影样式选项
    ui->comboBoxFrameShadow->addItem("Plain");
    ui->comboBoxFrameShadow->addItem("Raised");
    ui->comboBoxFrameShadow->addItem("Sunken");

    // 设置默认选择 Raised（凸起样式）
    ui->comboBoxFrameShadow->setCurrentIndex(1);
}

// 设置背景为“无颜色”
void Widget::on_radioButtonNull_clicked() {
    ui->frameTest->setStyleSheet(""); // 清除样式表
}

// 设置背景为红色
void Widget::on_radioButtonRed_clicked() {
    ui->frameTest->setStyleSheet("background-color: rgb(255, 0, 0);");
}

// 设置背景为蓝色
void Widget::on_radioButtonBlue_clicked() {
    ui->frameTest->setStyleSheet("background-color: rgb(0, 0, 255);");
}

// 设置背景为绿色
void Widget::on_radioButtonGreen_clicked() {
    ui->frameTest->setStyleSheet("background-color: rgb(0, 255, 0);");
}

// 响应 Line Width 数值变化，更新 frame 边框宽度
void Widget::on_spinBoxLineWidth_valueChanged(int arg1) {
    ui->frameTest->setLineWidth(arg1);
}

// 响应 Mid Line Width 数值变化，更新 frame 中线宽度
void Widget::on_spinBoxMidLineWidth_valueChanged(int arg1) {
    ui->frameTest->setMidLineWidth(arg1);
}

// 当选择不同 Frame Shape（形状）时，更新 frameTest 的形状样式
void Widget::on_comboBoxFrameShape_currentIndexChanged(int index) {
    if (index < 0) return;
    ui->frameTest->setFrameShape(m_listFrameShape[index]);
}

// 当选择不同 Frame Shadow（阴影）时，更新 frameTest 的阴影样式
void Widget::on_comboBoxFrameShadow_currentIndexChanged(int index) {
    if (index < 0) return;
    ui->frameTest->setFrameShadow(m_listFrameShadow[index]);
}
```

### Group Box 容器

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
    <width>400</width>
    <height>300</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <layout class="QVBoxLayout" name="verticalLayout_2">
   <item>
    <widget class="QGroupBox" name="groupBoxIP">
     <property name="title">
      <string>IP</string>
     </property>
     <layout class="QHBoxLayout" name="horizontalLayout">
      <item>
       <widget class="QRadioButton" name="radioButtonIP1">
        <property name="text">
         <string>192.168.1.1</string>
        </property>
       </widget>
      </item>
      <item>
       <widget class="QRadioButton" name="radioButtonIP2">
        <property name="text">
         <string>192.168.1.2</string>
        </property>
       </widget>
      </item>
      <item>
       <widget class="QRadioButton" name="radioButtonIP3">
        <property name="text">
         <string>192.168.1.3</string>
        </property>
       </widget>
      </item>
     </layout>
    </widget>
   </item>
   <item>
    <widget class="QGroupBox" name="groupBoxPort">
     <property name="title">
      <string>Port</string>
     </property>
     <layout class="QHBoxLayout" name="horizontalLayout_2">
      <item>
       <widget class="QRadioButton" name="radioButtonPort1">
        <property name="text">
         <string>80</string>
        </property>
       </widget>
      </item>
      <item>
       <widget class="QRadioButton" name="radioButtonPort2">
        <property name="text">
         <string>443</string>
        </property>
       </widget>
      </item>
      <item>
       <widget class="QRadioButton" name="radioButtonPort3">
        <property name="text">
         <string>8080</string>
        </property>
       </widget>
      </item>
     </layout>
    </widget>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_3">
     <item>
      <widget class="QPushButton" name="pushButtonConnect">
       <property name="text">
        <string>新建连接</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QGroupBox" name="groupBoxConnection">
       <property name="title">
        <string>连接操作</string>
       </property>
       <layout class="QVBoxLayout" name="verticalLayout">
        <item>
         <widget class="QPushButton" name="pushButtonSend">
          <property name="text">
           <string>发送数据</string>
          </property>
         </widget>
        </item>
        <item>
         <widget class="QPushButton" name="pushButtonRecv">
          <property name="text">
           <string>接收数据</string>
          </property>
         </widget>
        </item>
        <item>
         <widget class="QPushButton" name="pushButtonClose">
          <property name="text">
           <string>关闭连接</string>
          </property>
         </widget>
        </item>
       </layout>
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
    void initControls();

  private slots:
    void on_radioButtonIP1_clicked();

    void on_radioButtonIP2_clicked();

    void on_radioButtonIP3_clicked();

    void on_radioButtonPort1_clicked();

    void on_radioButtonPort2_clicked();

    void on_radioButtonPort3_clicked();

    void on_pushButtonConnect_clicked();

    void on_pushButtonSend_clicked();

    void on_pushButtonRecv_clicked();

    void on_pushButtonClose_clicked();

  private:
    Ui::Widget* ui;
    QString m_strIP;
    int m_nPort;
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QMessageBox>

// 构造函数：初始化 UI 和控件
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this); // 绑定 .ui 文件中定义的界面
    initControls();    // 初始化控件的默认状态
}

// 析构函数：释放 UI 内存
Widget::~Widget() {
    delete ui;
}

// 初始化控件
void Widget::initControls() {
    // 默认 IP 设置为 192.168.1.1，并勾选对应的单选框
    m_strIP = tr("192.168.1.1");
    ui->radioButtonIP1->setChecked(true);

    // 默认端口设置为 80，并勾选对应的单选框
    m_nPort = 80;
    ui->radioButtonPort1->setChecked(true);

    // 设置 IP 和 Port 的 GroupBox 为可勾选（Checkable）
    ui->groupBoxIP->setCheckable(true);
    ui->groupBoxPort->setCheckable(true);

    // 设置“连接操作”分组框为可勾选，但初始状态为未启用（即禁用内部控件）
    ui->groupBoxConnection->setCheckable(true);
    ui->groupBoxConnection->setChecked(false);
}

// IP 单选框点击事件，设置对应 IP
void Widget::on_radioButtonIP1_clicked() {
    m_strIP = tr("192.168.1.1");
}

void Widget::on_radioButtonIP2_clicked() {
    m_strIP = tr("192.168.1.2");
}

void Widget::on_radioButtonIP3_clicked() {
    m_strIP = tr("192.168.1.3");
}

// Port 单选框点击事件，设置对应端口号
void Widget::on_radioButtonPort1_clicked() {
    m_nPort = 80;
}

void Widget::on_radioButtonPort2_clicked() {
    m_nPort = 443;
}

void Widget::on_radioButtonPort3_clicked() {
    m_nPort = 8080;
}

// 点击“新建连接”按钮后的处理逻辑
void Widget::on_pushButtonConnect_clicked() {
    // 弹出提示框，显示连接信息
    QString strInfo = tr("新建连接成功：\r\nIP：%1\r\nPort：%2").arg(m_strIP).arg(m_nPort);
    QMessageBox::information(this, tr("新建连接"), strInfo);

    // 禁用 IP 和端口选择组（即取消勾选 groupBox）
    ui->groupBoxIP->setChecked(false);
    ui->groupBoxPort->setChecked(false);

    // 禁用“新建连接”按钮，防止重复连接
    ui->pushButtonConnect->setEnabled(false);

    // 启用连接操作组（勾选 groupBoxConnection，内部控件可用）
    ui->groupBoxConnection->setChecked(true);
}

// 点击“发送数据”按钮后的处理
void Widget::on_pushButtonSend_clicked() {
    QMessageBox::information(this, tr("发送数据"), tr("已发送数据。"));
}

// 点击“接收数据”按钮后的处理
void Widget::on_pushButtonRecv_clicked() {
    QMessageBox::information(this, tr("接收数据"), tr("已接收数据。"));
}

// 点击“关闭连接”按钮后的处理
void Widget::on_pushButtonClose_clicked() {
    // 显示提示信息
    QMessageBox::information(this, tr("关闭连接"), tr("已关闭连接。"));

    // 启用 IP 和端口选择分组框（重新勾选）
    ui->groupBoxIP->setChecked(true);
    ui->groupBoxPort->setChecked(true);

    // 启用“新建连接”按钮
    ui->pushButtonConnect->setEnabled(true);

    // 禁用连接操作分组框（取消勾选）
    ui->groupBoxConnection->setChecked(false);
}
```

