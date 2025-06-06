## Qt 其他输入控件

### 继承关系结构图

```cpp
QObject  
└── QPaintDevice  
    └── QWidget  
        ├── QAbstractSpinBox  
        │   ├── QSpinBox  
        │   └── QDoubleSpinBox  
        ├── QComboBox  
        ├── QFontComboBox  
        ├── QDateTimeEdit  
        │   ├── QDateEdit  
        │   └── QTimeEdit  
        ├── QDial  
        ├── QScrollBar  
        ├── QSlider  
        └── QKeySequenceEdit  
```

### 控件和功能简介

#### QComboBox — 下拉选择框

##### 功能简介

提供一个下拉列表供用户选择，也可以设置为可编辑，允许用户输入自定义项。

##### 常用函数

- `addItem(const QString &text)`：添加单个选项。
- `addItems(const QStringList &texts)`：批量添加选项。
- `insertItem(int index, const QString &text)`：在指定位置插入项。
- `removeItem(int index)`：删除某个选项。
- `setEditable(bool editable)`：设置是否可编辑。
- `setCurrentIndex(int index)` / `currentIndex()`：设置/获取当前选中项的索引。
- `currentText()`：获取当前显示的文本。
- `count()`：获取选项总数。
- `clear()`：清除所有选项。

##### 应用场景

适用于选择城市、语言、分类等场景。

#### QFontComboBox — 字体选择框

##### 功能简介

继承自 QComboBox，用于列出并选择系统中的字体名称。

##### 常用函数

- `currentFont()`：获取当前选中的字体（返回 QFont）。
- `setCurrentFont(const QFont &font)`：设置当前字体。
- `setFontFilters(QFontComboBox::FontFilters)`：设置字体过滤（如只显示等宽字体）。
- `setWritingSystem(QFontDatabase::WritingSystem)`：按书写系统筛选字体（如简体中文、希腊文）。

##### 应用场景

用于文本编辑器或绘图程序中的字体选择器。

#### QSpinBox — 整数微调框

##### 功能简介

提供带上下按钮的数字输入框，用户可以在特定整数范围内增减数值。

##### 常用函数

- `setRange(int min, int max)`：设置允许的取值范围。
- `setMinimum(int)` / `setMaximum(int)`：单独设置上下限。
- `setValue(int)` / `value()`：设置或获取当前值。
- `setSingleStep(int)`：设置每次增减的步长。
- `setPrefix(const QString&)` / `setSuffix(const QString&)`：设置前/后缀。
- `text()`：获取当前显示文本。

##### 应用场景

用于数量输入，如商品数量、页码选择等。

#### QDoubleSpinBox — 浮点微调框

##### 功能简介

与 QSpinBox 类似，但支持浮点数输入，适合处理精度更高的数值。

##### 常用函数

- `setDecimals(int)`：设置小数位数。
- `setRange(double min, double max)`：设置范围。
- `setValue(double)` / `value()`：设置或获取值。
- `setSingleStep(double)`：设置浮点步长。
- `setPrefix()` / `setSuffix()`：设置单位符号等。

##### 应用场景

用于金额、温度、百分比等需要小数精度的输入。

#### QTimeEdit — 时间编辑器

##### 功能简介

允许用户选择或输入时间（时、分、秒），支持键盘输入和点击微调。

##### 常用函数

- `setTime(const QTime&)` / `time()`：设置/获取时间。
- `setDisplayFormat(const QString&)`：设置时间显示格式（如 `"HH:mm:ss"`）。
- `setMinimumTime(QTime)` / `setMaximumTime(QTime)`：限制时间范围。
- `setTimeRange(QTime min, QTime max)`：同时设置最小和最大时间。

##### 应用场景

适合设置闹钟时间、会议开始时间等。

#### QDateEdit — 日期编辑器

##### 功能简介

提供选择和输入日期（年、月、日）的控件，支持日历弹出。

##### 常用函数

- `setDate(const QDate&)` / `date()`：设置/获取日期。
- `setDisplayFormat(const QString&)`：设置日期显示格式（如 `"yyyy-MM-dd"`）。
- `setMinimumDate(QDate)` / `setMaximumDate(QDate)`：限制选择范围。
- `setCalendarPopup(bool)`：启用弹出式日历。
- `calendarWidget()`：访问内部日历控件。

##### 应用场景

用于生日、到期日、计划时间等日期输入。

#### QDateTimeEdit — 日期时间编辑器

##### 功能简介

结合 QDateEdit 和 QTimeEdit，可同时编辑日期和时间。

##### 常用函数

- `setDateTime(const QDateTime&)` / `dateTime()`：设置/获取日期时间。
- `setDisplayFormat(const QString&)`：设置显示格式（如 `"yyyy-MM-dd HH:mm:ss"`）。
- `setMinimumDateTime()` / `setMaximumDateTime()`：限制选择范围。
- `setDate()` / `setTime()`：单独设置日期或时间。

##### 应用场景

用于设置事件的完整时间点，如预定、定时任务。

#### QDial — 拨盘控件

##### 功能简介

提供一个旋转式的控件，用户可拖动以选择值，通常用于仿物理旋钮的界面。

##### 常用函数

- `setRange(int min, int max)`：设置取值范围。
- `setNotchesVisible(bool)`：设置是否显示刻度。
- `setWrapping(bool)`：启用数值环绕（最大值后回到最小值）。
- `value()` / `setValue(int)`：获取/设置当前值。

##### 应用场景

音量控制、亮度调节等旋钮式交互。

#### QScrollBar — 滚动条

##### 功能简介

提供垂直或水平滚动条，用于内容过多的区域滚动显示。

##### 常用函数

- `setRange(int min, int max)`：设置滚动范围。
- `setPageStep(int)`：设置滚动的页面步长。
- `setSingleStep(int)`：设置微调的步长。
- `setValue(int)` / `value()`：设置/获取当前位置。

##### 应用场景

图像查看器、大型表格、文本编辑器滚动区域。

#### QSlider — 滑动条

##### 功能简介

线性滑动条，用户可通过滑块调整数值，UI 比 QScrollBar 更适合交互输入。

##### 常用函数

- `setOrientation(Qt::Orientation)`：设置方向（水平或垂直）。
- `setRange(int min, int max)`：设置取值范围。
- `setValue(int)` / `value()`：设置/获取当前值。
- `setTickInterval(int)`：设置刻度间隔。
- `setTickPosition(QSlider::TickPosition)`：设置刻度显示位置。

##### 应用场景

音量调节、亮度控制、进度设置。

#### QKeySequenceEdit — 快捷键编辑器

##### 功能简介

允许用户输入快捷键组合（如 Ctrl+S），用于设置自定义快捷键。

##### 常用函数

- `setKeySequence(const QKeySequence&)`：设置当前按键组合。
- `keySequence()`：获取当前的按键组合。
- `clear()`：清除当前输入。
- `editingFinished()`（信号）：当用户完成按键输入时发出。

##### 应用场景

应用程序设置页面，用户自定义快捷键时使用。

### QComboBox

#### 基本概述

`QComboBox` 是 Qt 中提供的下拉选择控件，允许用户从列表中选择一项，或在可编辑模式下输入自定义内容。

它集成了：

- 列表显示功能（类似 `QListView`）
- 可选的文本输入框（可编辑模式）
- 下拉按钮用于展开/收起列表

#### 常见功能特性

| 特性           | 描述                           |
| -------------- | ------------------------------ |
| 静态下拉列表   | 默认情况下仅能选择预定义选项   |
| 可编辑模式     | 用户可在输入框中输入自定义文本 |
| 选项可关联数据 | 每项可附加一个 `QVariant` 数据 |
| 支持图标和文本 | 每个选项可以带图标             |
| 自动补全       | 在可编辑模式下支持输入自动匹配 |

#### 常用函数详解

##### 添加、插入、删除选项

```cpp
void addItem(const QString &text, const QVariant &userData = QVariant());
void addItem(const QIcon &icon, const QString &text, const QVariant &userData = QVariant());
void addItems(const QStringList &texts);

void insertItem(int index, const QString &text, const QVariant &userData = QVariant());
void removeItem(int index);
void clear();
```

##### 访问选项内容

```cpp
int count() const;                             // 返回选项总数
QString itemText(int index) const;             // 获取指定项的文本
QVariant itemData(int index) const;            // 获取指定项的附加数据
void setItemText(int index, const QString &text);
void setItemData(int index, const QVariant &value);
```

##### 当前选中项

```cpp
int currentIndex() const;
void setCurrentIndex(int index);
QString currentText() const;                   // 获取当前显示的文本
QVariant currentData() const;
```

#### 可编辑模式

启用后可以直接在文本框中输入文字：

```cpp
comboBox->setEditable(true);
comboBox->setInsertPolicy(QComboBox::InsertAtBottom);  // 新项插入策略
comboBox->setCompleter(new QCompleter(comboBox->model(), comboBox));  // 自动补全
```

#### 信号（Signal）

| 信号                                               | 描述                           |
| -------------------------------------------------- | ------------------------------ |
| `void currentIndexChanged(int index)`              | 当前选中项索引变化             |
| `void currentIndexChanged(const QString &text)`    | 当前选中文本变化               |
| `void activated(int index)` / `activated(QString)` | 用户主动选择一项（点击或回车） |
| `void highlighted(int index)`                      | 鼠标高亮某项时发出             |

#### 数据模型支持（高级用法）

`QComboBox` 内部使用一个 `QAbstractItemModel` 存储选项。可以设置自己的模型：

```cpp
comboBox->setModel(myModel);              // 使用自定义数据模型
comboBox->setModelColumn(1);              // 指定用于显示的列
```

#### 样式与外观控制

- 使用 `QSS` 可定制外观，例如：

```css
QComboBox {
    border: 1px solid gray;
    padding: 1px 18px 1px 3px;
    min-width: 6em;
}
QComboBox::drop-down {
    subcontrol-origin: padding;
    subcontrol-position: top right;
    width: 15px;
}
```

#### 典型使用示例

```cpp
QComboBox *comboBox = new QComboBox(this);
comboBox->addItem("Apple", 1);
comboBox->addItem("Banana", 2);
comboBox->addItem("Cherry", 3);

connect(comboBox, QOverload<int>::of(&QComboBox::currentIndexChanged),
        this, [](int index) {
            qDebug() << "Selected index:" << index;
        });
```

#### 注意事项

- 若启用可编辑模式，要注意用户输入的合法性（可配合 `QValidator` 使用）

- 避免频繁调用 `addItem()` 和 `clear()`，可考虑使用 `model()->beginResetModel()`

  - **一次性更新大量数据项**时，频繁调用 `addItem()` 和 `clear()` 会导致 Qt 的模型系统在每次修改时都触发视图更新、信号发送等一系列代价较高的操作。

  - 安全批量替换内容

    ```cpp
    QAbstractItemModel *m = comboBox->model();
    
    m->beginResetModel();  // 告诉 Qt: 准备开始大修改
    comboBox->clear();     // 清除旧项（可选）
    comboBox->addItems(newList);  // 添加大量新项
    m->endResetModel();    // 告诉 Qt: 修改完成，请更新视图
    ```

  - 如果只是：

    - 添加 3~5 个小项
    - 改变其中一个选项
    - 在 UI 线程对用户交互项做响应式变更

    就**不要滥用 `beginResetModel()`**，因为它会清除当前状态，比如：

    - 当前选中项
    - 滚动位置
    - 某些委托缓存

- 使用 `QCompleter` 配合可编辑模式能显著提升用户体验

### 示例：个人信息收集

#### widget.ui

```css
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>Widget</class>
 <widget class="QWidget" name="Widget">
  <property name="geometry">
   <rect>
    <x>0</x>
    <y>0</y>
    <width>382</width>
    <height>302</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <widget class="QWidget" name="formLayoutWidget">
   <property name="geometry">
    <rect>
     <x>130</x>
     <y>100</y>
     <width>121</width>
     <height>133</height>
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
       <string>职业</string>
      </property>
     </widget>
    </item>
    <item row="3" column="0">
     <widget class="QLabel" name="label_4">
      <property name="text">
       <string>生日</string>
      </property>
     </widget>
    </item>
    <item row="0" column="1">
     <widget class="QLineEdit" name="lineEdtName"/>
    </item>
    <item row="1" column="1">
     <widget class="QComboBox" name="comboBoxGender">
      <item>
       <property name="text">
        <string>男</string>
       </property>
      </item>
      <item>
       <property name="text">
        <string>女</string>
       </property>
      </item>
      <item>
       <property name="text">
        <string>保密</string>
       </property>
      </item>
     </widget>
    </item>
    <item row="2" column="1">
     <widget class="QComboBox" name="comboBoxJob">
      <item>
       <property name="text">
        <string>魔法师</string>
       </property>
      </item>
      <item>
       <property name="text">
        <string>矮人</string>
       </property>
      </item>
      <item>
       <property name="text">
        <string>精英怪</string>
       </property>
      </item>
      <item>
       <property name="text">
        <string>哥布林</string>
       </property>
      </item>
      <item>
       <property name="text">
        <string>狂战士</string>
       </property>
      </item>
      <item>
       <property name="text">
        <string>弓箭手</string>
       </property>
      </item>
     </widget>
    </item>
    <item row="3" column="1">
     <widget class="QDateEdit" name="dateEdit"/>
    </item>
    <item row="4" column="1">
     <widget class="QPushButton" name="pushButton">
      <property name="minimumSize">
       <size>
        <width>0</width>
        <height>0</height>
       </size>
      </property>
      <property name="maximumSize">
       <size>
        <width>50</width>
        <height>20</height>
       </size>
      </property>
      <property name="layoutDirection">
       <enum>Qt::LayoutDirection::LeftToRight</enum>
      </property>
      <property name="text">
       <string>提交</string>
      </property>
      <property name="default">
       <bool>false</bool>
      </property>
      <property name="flat">
       <bool>false</bool>
      </property>
     </widget>
    </item>
   </layout>
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
    void on_comboBoxGender_currentIndexChanged(int index);
    void on_comboBoxJob_currentTextChanged(const QString& arg1);
    void on_dateEdit_dateChanged(const QDate& date);
    void on_pushButton_clicked();

private:
    Ui::Widget* ui;
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QDateTime>
#include <QMessageBox>

// 构造函数：初始化 UI 和控件属性
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this); // 设置 UI 组件

    // 设置职业下拉框可编辑
    ui->comboBoxJob->setEditable(true);

    // 设置日期选择器为弹出日历形式
    ui->dateEdit->setCalendarPopup(true);
}

// 析构函数：释放 UI 资源
Widget::~Widget() {
    delete ui;
}

// 槽函数：当性别下拉框选择变化时触发
void Widget::on_comboBoxGender_currentIndexChanged(int index) {
    if (index < 0) return;                                       // 无效索引，直接返回
    qDebug() << "性别：" << ui->comboBoxGender->itemText(index); // 打印当前选择的性别
}

// 槽函数：当职业下拉框文字变化时触发
void Widget::on_comboBoxJob_currentTextChanged(const QString& arg1) {
    qDebug() << "职业：" << arg1; // 打印当前职业
}

// 槽函数：当生日日期选择变化时触发
void Widget::on_dateEdit_dateChanged(const QDate& date) {
    qDebug() << date.toString("yyyy-MM-dd"); // 打印新选择的日期
}

// 槽函数：当点击“提交”按钮时触发
void Widget::on_pushButton_clicked() {
    QString res;

    // 拼接用户输入的信息
    res.append(tr("姓名：%1\r\n").arg(ui->lineEdtName->text()));
    res.append(tr("性别：%1\r\n").arg(ui->comboBoxGender->currentText()));
    res.append(tr("职业：%1\r\n").arg(ui->comboBoxJob->currentText()));
    res.append(tr("生日：%1\r\n").arg(ui->dateEdit->date().toString()));

    // 计算年龄（仅按年份粗略估算）
    QDateTime dtCur = QDateTime::currentDateTime();
    int years = dtCur.date().year() - ui->dateEdit->date().year();
    res.append(tr("年龄：%1").arg(years));

    // 弹出消息框显示用户信息
    QMessageBox::information(this, tr("信息"), res);
}
```

### 示例：卖盒饭

#### widget.ui

```css
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>Widget</class>
 <widget class="QWidget" name="Widget">
  <property name="geometry">
   <rect>
    <x>0</x>
    <y>0</y>
    <width>406</width>
    <height>174</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <widget class="QWidget" name="gridLayoutWidget">
   <property name="geometry">
    <rect>
     <x>60</x>
     <y>30</y>
     <width>301</width>
     <height>107</height>
    </rect>
   </property>
   <layout class="QGridLayout" name="gridLayout">
    <item row="3" column="0">
     <widget class="QPushButton" name="btnCalc">
      <property name="text">
       <string>计算总价</string>
      </property>
     </widget>
    </item>
    <item row="0" column="0">
     <widget class="QLabel" name="label">
      <property name="text">
       <string>盒饭</string>
      </property>
     </widget>
    </item>
    <item row="2" column="1">
     <widget class="QSpinBox" name="spinBoxCount"/>
    </item>
    <item row="0" column="1">
     <widget class="QComboBox" name="comboBox"/>
    </item>
    <item row="1" column="1">
     <widget class="QDoubleSpinBox" name="doubleSpinBoxPrice"/>
    </item>
    <item row="2" column="0">
     <widget class="QLabel" name="label_3">
      <property name="text">
       <string>份数</string>
      </property>
     </widget>
    </item>
    <item row="1" column="0">
     <widget class="QLabel" name="label_2">
      <property name="text">
       <string>单价</string>
      </property>
     </widget>
    </item>
    <item row="2" column="2">
     <widget class="QSlider" name="horizontalSlider">
      <property name="orientation">
       <enum>Qt::Orientation::Horizontal</enum>
      </property>
     </widget>
    </item>
    <item row="3" column="1">
     <widget class="QLineEdit" name="lineEditTotal">
      <property name="maximumSize">
       <size>
        <width>70</width>
        <height>16777215</height>
       </size>
      </property>
     </widget>
    </item>
   </layout>
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
    void on_comboBox_currentIndexChanged(int index);
    void on_btnCalc_clicked();

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
#include <QSlider>

Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);

    ui->comboBox->addItem(tr("番茄鸡蛋"), 8.50);
    ui->comboBox->addItem(tr("土豆烧肉"), 10.00);
    ui->comboBox->addItem(tr("鱼香肉丝"), 10.00);
    ui->comboBox->addItem(tr("青椒鸡蛋"), 8.50);
    ui->comboBox->addItem(tr("地三鲜"), 9.00);

    ui->doubleSpinBoxPrice->setRange(0.00, 30.00);
    ui->doubleSpinBoxPrice->setSingleStep(1.00);
    ui->doubleSpinBoxPrice->setSuffix(tr(" 元"));

    ui->spinBoxCount->setRange(0, 100);
    ui->spinBoxCount->setSingleStep(1);
    ui->horizontalSlider->setRange(0, 100);
    ui->horizontalSlider->setSingleStep(1);

    ui->horizontalSlider->setTickPosition(QSlider::TicksBothSides);
    ui->horizontalSlider->setTickInterval(10);

    connect(ui->spinBoxCount, &QSpinBox::valueChanged, ui->horizontalSlider, &QSlider::setValue);
    connect(ui->horizontalSlider, &QSlider::valueChanged, ui->spinBoxCount, &QSpinBox::setValue);
}

Widget::~Widget() {
    delete ui;
}

void Widget::on_comboBox_currentIndexChanged(int index) {
    if (index < 0) return;
    double dblPrice = ui->comboBox->itemData(index).toDouble();
    ui->doubleSpinBoxPrice->setValue(dblPrice);
    qDebug() << ui->comboBox->currentText() << "\t" << dblPrice;
}

void Widget::on_btnCalc_clicked() {
    double dblTotal = ui->doubleSpinBoxPrice->value() * ui->spinBoxCount->value();
    ui->lineEditTotal->setText(tr("%1 元").arg(dblTotal));
}
```

