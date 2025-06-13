## Qt 滚动区域和工具箱

### Scroll Area

在 Qt 中，`QScrollArea` 是一个非常常用的部件（widget），它用于在有限的可视区域内显示较大的内容，并自动提供滚动条以便用户可以查看超出可视范围的部分。它常用于图像浏览器、设置页面、表单或任何可能内容溢出的情况。

#### 基本概念

`QScrollArea` 提供一个可以滚动的区域，可以将任意一个 QWidget 作为它的 **内容区域（widget）**，当该内容区域超出可见范围时，自动显示水平/垂直滚动条。

```cpp
QScrollArea *scrollArea = new QScrollArea;
QWidget *contentWidget = new QWidget; // 可以换成你自定义的 widget
scrollArea->setWidget(contentWidget);
```

#### 主要结构

```css
QScrollArea
├── viewport (可视区域)
│   └── widget (实际显示内容)
├── 垂直滚动条（可选）
└── 水平滚动条（可选）
```

#### 常用函数和属性

| 函数 / 属性                                         | 说明                                                         |
| --------------------------------------------------- | ------------------------------------------------------------ |
| `setWidget(QWidget *widget)`                        | 设置实际内容组件（只能设置一个）                             |
| `widget()`                                          | 获取当前内容组件                                             |
| `setWidgetResizable(bool)`                          | 是否自动调整内容组件大小以适应 scrollArea 大小（默认 false） |
| `setAlignment(Qt::Alignment)`                       | 设置内容的对齐方式                                           |
| `setHorizontalScrollBarPolicy(Qt::ScrollBarPolicy)` | 设置水平滚动条策略（如 `Qt::ScrollBarAsNeeded`）             |
| `setVerticalScrollBarPolicy(Qt::ScrollBarPolicy)`   | 设置垂直滚动条策略                                           |

#### 简单示例

##### 显示一个大图片

```cpp
QScrollArea *scrollArea = new QScrollArea(this);
QPixmap pixmap(":/images/large_image.png");
QLabel *imageLabel = new QLabel;
imageLabel->setPixmap(pixmap);
scrollArea->setWidget(imageLabel);
scrollArea->setWidgetResizable(true);
```

##### 嵌套复杂表单

```cpp
QWidget *formWidget = new QWidget;
QVBoxLayout *layout = new QVBoxLayout(formWidget);
for (int i = 0; i < 50; ++i) {
    layout->addWidget(new QLineEdit(QString("Line %1").arg(i)));
}

QScrollArea *scrollArea = new QScrollArea;
scrollArea->setWidget(formWidget);
scrollArea->setWidgetResizable(true);
```

#### Qt::ScrollBarPolicy

| 枚举值                   | 含义                           | 使用场景                           |
| ------------------------ | ------------------------------ | ---------------------------------- |
| `Qt::ScrollBarAlwaysOff` | 滚动条永远不显示               | 内容不允许滚动或你不希望出现滚动条 |
| `Qt::ScrollBarAlwaysOn`  | 滚动条总是显示                 | 界面固定、有滚动条提示用户可以滚动 |
| `Qt::ScrollBarAsNeeded`  | 默认选项，仅在需要时显示滚动条 | 内容超出可视区域才显示滚动条       |

### 示例：地图

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
 </widget>
 <resources/>
 <connections/>
</ui>
```

#### widget.h

```cpp
#ifndef WIDGET_H
#define WIDGET_H

// Qt 基础控件与布局
#include <QHBoxLayout>   // 水平布局器，用于主界面布局
#include <QLabel>        // 用于显示地图图片
#include <QList>         // 点的列表
#include <QPixmap>       // 图片对象
#include <QPoint>        // 坐标点类型
#include <QRadioButton>  // 右侧用于省份选择的单选按钮
#include <QScrollArea>   // 滚动区域容器，用于实现视图滚动
#include <QSignalMapper> // 信号映射器，用于简化多个按钮信号的统一处理
#include <QStringList>   // 字符串列表（省份名）
#include <QVBoxLayout>   // 垂直布局器，用于按钮区域布局

#include <QWidget> // 所有可视界面类的基类 QWidget

QT_BEGIN_NAMESPACE
namespace Ui {
class Widget;
}
QT_END_NAMESPACE

// 主窗口类 Widget，继承自 QWidget
class Widget : public QWidget {
    Q_OBJECT

  public:
    // 构造函数和析构函数
    Widget(QWidget* parent = nullptr);
    ~Widget();

    // 初始化控件和界面布局
    void initControls();

  public slots:
    // 槽函数：当某个省份按钮被点击后调用，滚动地图到该省份位置
    void showProvince(int index);

  private:
    Ui::Widget* ui; // UI 指针（Qt Designer 生成）

    // ====== 数据成员 ======

    // 省份名称列表
    QStringList m_listProvinces;

    // 省份对应的坐标点列表
    QList<QPoint> m_listPoints;

    // 地图图片资源
    QPixmap m_map;

    // 加载地图图片和省份文本数据的私有函数
    void loadData();

    // ====== 控件成员 ======

    // 显示地图的 QLabel 控件
    QLabel* m_labelMap;

    // 左边滚动区域：包裹地图 QLabel
    QScrollArea* m_saLeftMap;

    // 右边滚动区域：包裹省份按钮列表
    QScrollArea* m_saRightButtons;
};

#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QDebug>
#include <QFile>

// 构造函数：初始化 UI 和加载地图数据
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);
    loadData();     // 加载地图和省份坐标数据
    initControls(); // 初始化控件和布局
}

// 析构函数：释放 UI 资源
Widget::~Widget() {
    delete ui;
}

// 加载地图图片和省份坐标文本数据
void Widget::loadData() {
    // 加载地图图片资源（china.png）
    m_map.load(":/china.png");

    // 打开文本文件资源（china.txt），用于读取省份名与坐标
    QFile fileIn(":/china.txt");

    // 清空已有数据
    m_listProvinces.clear();
    m_listPoints.clear();

    // 以只读文本方式打开文件
    fileIn.open(QIODevice::ReadOnly | QIODevice::Text);

    // 逐行读取文件内容
    while (!fileIn.atEnd()) {
        QByteArray baLine = fileIn.readLine();       // 读取一行字节数据
        QString strLine = QString::fromUtf8(baLine); // 转为 UTF-8 字符串
        QStringList liParts = strLine.split('\t');   // 每行格式：[省份名]\t[x]\t[y]

        QPoint pt;
        m_listProvinces << liParts[0]; // 保存省份名
        pt.setX(liParts[1].toInt());   // 提取并设置横坐标
        pt.setY(liParts[2].toInt());   // 提取并设置纵坐标
        m_listPoints << pt;            // 保存坐标点
    }

    // 打印加载信息（调试用途）
    qDebug() << m_listProvinces.size() << m_listProvinces;
    qDebug() << m_listPoints.size() << m_listPoints;
}

// 初始化界面控件及布局
void Widget::initControls() {
    // 1. 创建 QLabel 显示地图，并设置地图图像
    m_labelMap = new QLabel();
    m_labelMap->setPixmap(m_map); // 地图图像设置到标签上

    // 2. 创建左侧滚动区域（显示地图）
    m_saLeftMap = new QScrollArea();
    m_saLeftMap->setWidget(m_labelMap); // 将地图标签嵌入滚动区域

    // 3. 创建右侧按钮容器及垂直布局器（用于省份选择按钮）
    QWidget* pWidRight = new QWidget();
    QVBoxLayout* pLayoutRight = new QVBoxLayout();

    QRadioButton* curButton = nullptr;
    int nCount = m_listProvinces.size(); // 省份总数量

    // 4. 遍历每个省份，创建对应的单选按钮
    for (int i = 0; i < nCount; ++i) {
        curButton = new QRadioButton(m_listProvinces[i]);

        // 使用 lambda 表达式直接传递当前索引到槽函数
        // 避免使用 QSignalMapper，代码更简洁且类型安全
        connect(curButton, &QRadioButton::clicked, this, [=]() {
            showProvince(i); // 点击按钮时，跳转地图视图到对应省份
        });

        pLayoutRight->addWidget(curButton); // 添加按钮到右侧布局器
    }

    // 5. 设置右侧按钮容器布局，并包裹进滚动区域
    pWidRight->setLayout(pLayoutRight);
    m_saRightButtons = new QScrollArea();
    m_saRightButtons->setWidget(pWidRight); // 设置内容为按钮容器

    // 6. 创建主布局器，左右两个滚动区域并排放置
    QHBoxLayout* pMainLayout = new QHBoxLayout();
    pMainLayout->addWidget(m_saLeftMap);      // 左侧地图区域
    pMainLayout->addWidget(m_saRightButtons); // 右侧按钮区域
    pMainLayout->setStretch(0, 4);            // 左边宽一些
    pMainLayout->setStretch(1, 1);            // 右边窄一些

    // 7. 设置主窗口布局器
    setLayout(pMainLayout);

    // 8. 设置窗口初始大小
    resize(800, 600);

    // 9. 默认选中最后一个按钮（如“台湾”）
    curButton->setChecked(true);

    // 10. 确保该按钮在右侧滚动区域中可见
    m_saRightButtons->ensureWidgetVisible(curButton);

    // 11. 滚动地图区域，让最后一个省份坐标显示在可见视口
    // 参数含义：目标坐标（x, y），额外偏移（xMargin, yMargin）
    m_saLeftMap->ensureVisible(m_listPoints[nCount - 1].x(), m_listPoints[nCount - 1].y(), 200, 200);
}

// 槽函数：点击某个省份按钮后调用，滚动地图视图到该省份坐标
void Widget::showProvince(int index) {
    // 滚动地图视口，确保该省份的位置处于可视范围内
    m_saLeftMap->ensureVisible(m_listPoints[index].x(), m_listPoints[index].y(), 200, 200); // 设置边缘留白，提升可视性
}
```

### Tool Box

Qt 的 **`QToolBox`** 是一个容器类，用于在一个面板中组织多个子页面，每个页面都有一个标题标签，用户可以点击标签来切换显示的页面。它在视觉效果和交互上类似于「手风琴式」控件，但是垂直排列的（和 `QTabWidget` 的横向标签页不同）。

#### 基本概念

- `QToolBox` 是 Qt Widgets 模块中的一个控件，继承自 `QFrame`。
- 每个子页面是一个 `QWidget`，可以放置布局和控件。
- 用户通过点击不同的标题栏来切换页面。
- 适合组织**功能面板**、**设置菜单**、**帮助信息**等不需要频繁切换的内容。

#### 基本用法示例

```cpp
#include <QApplication>
#include <QToolBox>
#include <QLabel>
#include <QVBoxLayout>

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    QToolBox *toolBox = new QToolBox;

    // 页面 1
    QWidget *page1 = new QWidget;
    QVBoxLayout *layout1 = new QVBoxLayout;
    layout1->addWidget(new QLabel("内容 1"));
    page1->setLayout(layout1);
    toolBox->addItem(page1, "页面 1");

    // 页面 2
    QWidget *page2 = new QWidget;
    QVBoxLayout *layout2 = new QVBoxLayout;
    layout2->addWidget(new QLabel("内容 2"));
    page2->setLayout(layout2);
    toolBox->addItem(page2, "页面 2");

    toolBox->resize(300, 200);
    toolBox->show();

    return app.exec();
}
```

#### 常用方法

| 方法                                                         | 说明                           |
| ------------------------------------------------------------ | ------------------------------ |
| `addItem(QWidget *widget, const QString &label)`             | 添加一个新页面，标签为 `label` |
| `insertItem(int index, QWidget *widget, const QString &label)` | 在指定位置插入页面             |
| `removeItem(int index)`                                      | 删除指定索引的页面             |
| `widget(int index)`                                          | 返回索引对应的页面             |
| `currentIndex()`                                             | 返回当前显示页面的索引         |
| `setCurrentIndex(int index)`                                 | 设置当前显示的页面             |
| `setItemText(int index, const QString &text)`                | 设置页面标签文本               |

#### 样式美化

可以使用 Qt 的样式表（QSS）来自定义 `QToolBox` 的外观，比如：

```cpp
toolBox->setStyleSheet(R"(
QToolBox::tab {
    background: lightgray;
    border: 1px solid gray;
    padding: 5px;
}
QToolBox::tab:selected {
    background: white;
    font-weight: bold;
}
)");
```

#### 和 QTabWidget 的区别

| 特性       | QToolBox           | QTabWidget       |
| ---------- | ------------------ | ---------------- |
| 标签方向   | 垂直               | 水平（默认）     |
| UI 体验    | 展开一个，隐藏其他 | 类似浏览器标签页 |
| 用途       | 设置、工具、导航等 | 多页面内容切换   |
| 可嵌套布局 | 是                 | 是               |

### 示例：工具箱

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
    <width>520</width>
    <height>400</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <layout class="QHBoxLayout" name="horizontalLayout">
   <item>
    <widget class="QLabel" name="labelShow">
     <property name="sizePolicy">
      <sizepolicy hsizetype="Expanding" vsizetype="Expanding">
       <horstretch>0</horstretch>
       <verstretch>0</verstretch>
      </sizepolicy>
     </property>
     <property name="text">
      <string>TextLabel</string>
     </property>
    </widget>
   </item>
   <item>
    <widget class="QToolBox" name="toolBox">
     <property name="currentIndex">
      <number>2</number>
     </property>
     <widget class="QWidget" name="pageText">
      <property name="geometry">
       <rect>
        <x>0</x>
        <y>0</y>
        <width>248</width>
        <height>295</height>
       </rect>
      </property>
      <attribute name="label">
       <string>编辑文本</string>
      </attribute>
      <layout class="QVBoxLayout" name="verticalLayout">
       <item>
        <widget class="QLineEdit" name="lineEditText"/>
       </item>
       <item>
        <widget class="QPushButton" name="pushButtonEditText">
         <property name="text">
          <string>修改文本</string>
         </property>
        </widget>
       </item>
      </layout>
     </widget>
     <widget class="QWidget" name="pageFont">
      <property name="geometry">
       <rect>
        <x>0</x>
        <y>0</y>
        <width>248</width>
        <height>295</height>
       </rect>
      </property>
      <attribute name="label">
       <string>字体字号</string>
      </attribute>
      <layout class="QVBoxLayout" name="verticalLayout_2">
       <item>
        <widget class="QFontComboBox" name="fontComboBox"/>
       </item>
       <item>
        <widget class="QSpinBox" name="spinBoxSize"/>
       </item>
      </layout>
     </widget>
     <widget class="QWidget" name="pageColor">
      <attribute name="label">
       <string>颜色设置</string>
      </attribute>
      <layout class="QGridLayout" name="gridLayout">
       <item row="0" column="0">
        <widget class="QLabel" name="label">
         <property name="text">
          <string>前景色</string>
         </property>
        </widget>
       </item>
       <item row="0" column="1">
        <widget class="QComboBox" name="comboBoxFGColor"/>
       </item>
       <item row="1" column="0">
        <widget class="QLabel" name="label_2">
         <property name="text">
          <string>背景色</string>
         </property>
        </widget>
       </item>
       <item row="1" column="1">
        <widget class="QComboBox" name="comboBoxBGColor"/>
       </item>
      </layout>
     </widget>
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
    void on_pushButtonEditText_clicked();

    void on_fontComboBox_currentTextChanged(const QString& arg1);

    void on_spinBoxSize_valueChanged(int arg1);

    void on_comboBoxFGColor_currentTextChanged(const QString& arg1);

    void on_comboBoxBGColor_currentTextChanged(const QString& arg1);

  private:
    Ui::Widget* ui;
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QColor>
#include <QDebug>
#include <QFont>
#include <QMessageBox>

// 构造函数，初始化界面和控件
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this); // 加载 UI 文件生成的界面
    initControls();    // 初始化控件配置
}

// 析构函数，释放 UI 对象内存
Widget::~Widget() {
    delete ui;
}

// 初始化控件属性和样式
void Widget::initControls() {
    // 设置字号旋钮框的范围为 4 到 100
    ui->spinBoxSize->setRange(4, 100);
    // 默认字号设置为 9
    ui->spinBoxSize->setValue(9);

    // 获取所有可用颜色名称列表（Qt内置的标准颜色）
    QStringList colorNames = QColor::colorNames();

    // 将颜色名称添加到前景色组合框
    ui->comboBoxFGColor->addItems(colorNames);
    // 设置默认前景色为黑色
    ui->comboBoxFGColor->setCurrentText("black");

    // 将颜色名称添加到背景色组合框
    ui->comboBoxBGColor->addItems(colorNames);
    // 设置默认背景色为浅灰色
    ui->comboBoxBGColor->setCurrentText("lightgray");

    // 设置 ToolBox 组件的样式表
    // ::tab 选择器修改工具箱标签页的背景色为紫红色（magenta）
    // 给特定页面 QWidget 指定名字，设置不同的背景色以便区分
    QString strCSS = "::tab{ background-color: magenta; }"
                     "QWidget#pageText{ background-color: green; }"
                     "QWidget#pageFont{ background-color: cyan; }"
                     "QWidget#pageColor{ background-color: yellow; }";
    ui->toolBox->setStyleSheet(strCSS);
}

// 点击编辑按钮时，将输入框的文本设置到显示标签上
void Widget::on_pushButtonEditText_clicked() {
    QString strText = ui->lineEditText->text(); // 获取输入框内容
    ui->labelShow->setText(strText);            // 设置标签显示内容
}

// 字体选择框内容改变时，更新标签的字体（字体名 + 当前字号）
void Widget::on_fontComboBox_currentTextChanged(const QString& arg1) {
    QFont txtFont(arg1, ui->spinBoxSize->value()); // 创建字体，字号用旋钮框当前值
    ui->labelShow->setFont(txtFont);               // 应用字体到标签
}

// 字号旋钮框数值改变时，更新标签字体（当前字体名 + 新字号）
void Widget::on_spinBoxSize_valueChanged(int arg1) {
    QFont txtFont(ui->fontComboBox->currentText(), arg1); // 创建字体，字号用旋钮框新值
    ui->labelShow->setFont(txtFont);                      // 应用字体到标签
}

// 当前景色组合框的文本改变时，更新标签的前景色和背景色样式
void Widget::on_comboBoxFGColor_currentTextChanged(const QString& arg1) {
    QString strFGColor = arg1;                               // 新前景色
    QString strBGColor = ui->comboBoxBGColor->currentText(); // 当前背景色
    // 拼接样式表字符串，设置字体颜色和背景颜色
    QString strCSS = QString("color: %1; background-color: %2;").arg(strFGColor).arg(strBGColor);
    ui->labelShow->setStyleSheet(strCSS); // 应用样式
}

// 当背景色组合框文本改变时，更新标签的背景色和前景色样式
void Widget::on_comboBoxBGColor_currentTextChanged(const QString& arg1) {
    QString strFGColor = ui->comboBoxFGColor->currentText(); // 当前前景色
    QString strBGColor = arg1;                               // 新背景色
    // 拼接样式表字符串，设置字体颜色和背景颜色
    QString strCSS = QString("color: %1; background-color: %2;").arg(strFGColor).arg(strBGColor);
    ui->labelShow->setStyleSheet(strCSS); // 应用样式
}
```

