## Qt 表格控件

### QTableWidget

`QTableWidget` 是 Qt 框架中一个非常常用的控件，属于 Qt Widgets 模块，用于在 GUI 中以表格形式显示和编辑数据。它是 `QTableView` 的一个子类，预置了一个使用 `QTableWidgetItem` 的模型，适合快速开发带表格的界面。

#### 常用构造函数

```cpp
QTableWidget(int rows, int columns, QWidget *parent = nullptr);
```

也可以后续动态设置行列数：

```cpp
tableWidget->setRowCount(10);
tableWidget->setColumnCount(5);
```

#### 常用操作示例

##### 设置表头

```cpp
QStringList headers = {"Name", "Age", "Score"};
tableWidget->setHorizontalHeaderLabels(headers);
```

##### 插入单元格内容

```cpp
QTableWidgetItem *item = new QTableWidgetItem("Alice");
tableWidget->setItem(0, 0, item);
```

- 在使用 `setItem()` 设置表格数据时，如果启用了自动排序功能（`setSortingEnabled(true)`），就可能导致还没设置完一整行时，行的位置就被自动移动了，导致显示错乱或逻辑错误。

##### 设置只读单元格

```cpp
item->setFlags(item->flags() & ~Qt::ItemIsEditable);
```

##### 设置整行选择模式

```cpp
tableWidget->setSelectionBehavior(QAbstractItemView::SelectRows);
```

##### 响应单元格点击信号

```cpp
connect(tableWidget, &QTableWidget::cellClicked,
        [](int row, int column) {
            qDebug() << "Clicked cell: " << row << column;
        });
```

#### 进阶功能

**排序**：

```cpp
tableWidget->setSortingEnabled(true);
```

**自定义单元格（控件嵌入）**：

```cpp
QPushButton *btn = new QPushButton("Click Me");
tableWidget->setCellWidget(0, 1, btn);
```

**清空表格**：

```cpp
tableWidget->clearContents();  // 保留表头
tableWidget->clear();          // 表头也清除
```

**获取选中项**：

```cpp
QList<QTableWidgetItem*> selectedItems = tableWidget->selectedItems();
```

### QTableWidgetItem

`QTableWidgetItem` 是 Qt 中专门用于 `QTableWidget` 表格的单元格条目类，它表示表格中的一个单元格对象，可以用于显示文本、图标，也可以设置其行为（如是否可编辑、是否可选中等）。

```cpp
#include <QTableWidgetItem>
```

它不是控件，而是数据项。每个 `QTableWidgetItem` 可以包含以下内容：

- 显示内容（文本）
- 图标
- 对齐方式
- 用户自定义数据
- 状态（是否可选中、是否可编辑、是否可拖动）

#### 常用构造函数

```cpp
QTableWidgetItem();
QTableWidgetItem(const QString &text);
QTableWidgetItem(const QIcon &icon, const QString &text);
```

#### 典型用法

```cpp
QTableWidgetItem *item = new QTableWidgetItem("Hello");
tableWidget->setItem(0, 0, item);
```

#### 常用设置项

##### 设置对齐方式

```cpp
item->setTextAlignment(Qt::AlignCenter); // 居中对齐
```

可选项包括：

- `Qt::AlignLeft`, `Qt::AlignRight`, `Qt::AlignHCenter`
- `Qt::AlignTop`, `Qt::AlignBottom`, `Qt::AlignVCenter`

##### 设置图标

```cpp
item->setIcon(QIcon(":/icons/user.png"));
```

也可以直接在构造函数中设置：

```cpp
QTableWidgetItem *item = new QTableWidgetItem(QIcon(":/icons/user.png"), "Alice");
```

##### 设置字体或颜色

```cpp
item->setFont(QFont("Arial", 12, QFont::Bold));
item->setForeground(QBrush(Qt::red));     // 文字颜色
item->setBackground(QBrush(Qt::yellow));  // 背景颜色
```

##### 设置是否可编辑

默认单元格是可编辑的。若要禁用编辑：

```cpp
item->setFlags(item->flags() & ~Qt::ItemIsEditable);
```

也可以设置为只读 + 不可选中：

```cpp
item->setFlags(Qt::NoItemFlags);
```

##### 设置和获取用户数据

可以将任意 QVariant 数据附加到条目中：

```cpp
item->setData(Qt::UserRole, QVariant(12345));
QVariant val = item->data(Qt::UserRole);
```

可以用于储存额外信息而不显示在界面上，比如 ID、状态码等。

#### 获取现有单元格项

```cpp
QTableWidgetItem *item = tableWidget->item(row, column);
if (item) {
    QString text = item->text();
}
```

#### 注意事项

- `QTableWidget` 会**接管 item 的生命周期**，不需要手动删除。

- 设置完 `QTableWidgetItem` 后，只有使用 `setItem()` 传入到 `QTableWidget` 才会生效。

- 每个 `QTableWidgetItem` 实例只能存在于一个单元格中，**不能复用同一个 item 设置多个格子**。

#### 示例代码片段

```cpp
QTableWidget *table = new QTableWidget(3, 2);
table->setHorizontalHeaderLabels({"Name", "Score"});

QTableWidgetItem *item1 = new QTableWidgetItem("Alice");
item1->setTextAlignment(Qt::AlignCenter);
item1->setFont(QFont("Consolas", 12, QFont::Bold));
item1->setForeground(Qt::blue);

QTableWidgetItem *item2 = new QTableWidgetItem("98");
item2->setFlags(item2->flags() & ~Qt::ItemIsEditable); // 设置为只读

table->setItem(0, 0, item1);
table->setItem(0, 1, item2);
```

### 表头设置

在 Qt 的 `QTableWidget` 中，**表头（Header）** 用于显示每列或每行的标题。可以自定义表头内容、样式、行为等。`QTableWidget` 默认带有：

- **水平表头（Horizontal Header）**：表示每一列的标题（如 "姓名"、"年龄"）
- **垂直表头（Vertical Header）**：表示每一行的编号（如 1、2、3）

#### 设置表头标签

##### 设置列标题（水平表头）

```cpp
QStringList headers = {"姓名", "年龄", "成绩"};
tableWidget->setColumnCount(headers.size());
tableWidget->setHorizontalHeaderLabels(headers);
```

##### 设置行标题（垂直表头）

```cpp
QStringList rowHeaders = {"A", "B", "C"};
tableWidget->setRowCount(rowHeaders.size());
tableWidget->setVerticalHeaderLabels(rowHeaders);
```

#### 获取表头对象

可以获取表头控件本身，用于进一步设置样式、交互行为：

```cpp
QHeaderView *hHeader = tableWidget->horizontalHeader(); // 横向表头
QHeaderView *vHeader = tableWidget->verticalHeader();   // 纵向表头
```

#### 常用表头配置操作

##### 设置列宽 / 行高自适应内容

```cpp
tableWidget->resizeColumnsToContents(); // 自动调整列宽
tableWidget->resizeRowsToContents();    // 自动调整行高
```

##### 禁用用户点击表头排序

```cpp
tableWidget->setSortingEnabled(false);
```

或禁止交互：

```cpp
tableWidget->horizontalHeader()->setSectionsClickable(false);
```

##### 固定列宽 / 不可拖动调整宽度

```cpp
tableWidget->horizontalHeader()->setSectionResizeMode(QHeaderView::Fixed);
tableWidget->setColumnWidth(0, 100); // 第0列设为100像素宽
```

如果要让所有列等宽分布：

```cpp
tableWidget->horizontalHeader()->setSectionResizeMode(QHeaderView::Stretch);
```

##### 隐藏表头

```cpp
tableWidget->horizontalHeader()->setVisible(false); // 隐藏列标题
tableWidget->verticalHeader()->setVisible(false);   // 隐藏行编号
```

#### 进阶：自定义表头样式

可以使用 QSS（Qt Style Sheet）自定义表头的外观：

```cpp
tableWidget->setStyleSheet(
    "QHeaderView::section { background-color: lightgray; color: black; font-weight: bold; }"
);
```

### 选中区域和选中行为

在 `QTableWidget` 中，**选中区域（Selection Range）** 和 **选中行为（Selection Behavior）** 是非常重要的交互特性，决定了用户如何选中单元格、选中的范围、以及你如何从代码中获取这些选中的内容。

#### 选中行为（Selection Behavior）

通过 `setSelectionBehavior()` 设置，控制**用户点击时，选择的是哪一部分**。

可选项如下：

| 行为常量                           | 说明                     |
| ---------------------------------- | ------------------------ |
| `QAbstractItemView::SelectItems`   | 默认，**选中单元格**     |
| `QAbstractItemView::SelectRows`    | 点击任意单元格会选中整行 |
| `QAbstractItemView::SelectColumns` | 点击任意单元格会选中整列 |

示例：

```cpp
tableWidget->setSelectionBehavior(QAbstractItemView::SelectRows);
```

#### 选中模式（Selection Mode）

通过 `setSelectionMode()` 设置，控制**能不能多选**、是否允许框选等。

可选项如下：

| 模式常量                                 | 说明                                               |
| ---------------------------------------- | -------------------------------------------------- |
| `QAbstractItemView::NoSelection`         | 禁止选择                                           |
| `QAbstractItemView::SingleSelection`     | 一次只能选一个区域（行/列/单元格）                 |
| `QAbstractItemView::MultiSelection`      | 可使用 Ctrl 多选多个单元格（仅配合 `SelectItems`） |
| `QAbstractItemView::ExtendedSelection`   | 默认，支持 Shift/Ctrl 多选                         |
| `QAbstractItemView::ContiguousSelection` | 只能选连续区域                                     |

示例：

```cpp
tableWidget->setSelectionMode(QAbstractItemView::ExtendedSelection);
```

#### 获取选中区域数据

##### 获取所有选中的单元格

```cpp
QList<QTableWidgetItem*> selectedItems = tableWidget->selectedItems();
for (QTableWidgetItem* item : selectedItems) {
    qDebug() << item->row() << item->column() << item->text();
}
```

##### 获取所有选中的行号（常用于 `SelectRows` 模式）

```cpp
QItemSelectionModel *sel = tableWidget->selectionModel();
QModelIndexList selected = sel->selectedRows(); // 获取选中的行
for (const QModelIndex &index : selected) {
    qDebug() << "Selected row:" << index.row();
}
```

##### 获取选中区域（多个矩形）

```cpp
QList<QTableWidgetSelectionRange> ranges = tableWidget->selectedRanges();
for (const QTableWidgetSelectionRange &range : ranges) {
    int topRow = range.topRow();
    int bottomRow = range.bottomRow();
    int leftCol = range.leftColumn();
    int rightCol = range.rightColumn();
    qDebug() << "Selected block from" << topRow << leftCol << "to" << bottomRow << rightCol;
}
```

#### 设置或取消选中项（代码中）

##### 选中一个单元格

```cpp
tableWidget->setCurrentCell(2, 1); // 选中第3行第2列
```

##### 清除所有选中状态

```cpp
tableWidget->clearSelection();
```

#### 示例代码：选中整行并打印内容

```cpp
tableWidget->setSelectionBehavior(QAbstractItemView::SelectRows);
tableWidget->setSelectionMode(QAbstractItemView::SingleSelection);

connect(tableWidget, &QTableWidget::itemSelectionChanged, [=]() {
    QList<QTableWidgetItem*> selected = tableWidget->selectedItems();
    for (QTableWidgetItem *item : selected) {
        qDebug() << "Row:" << item->row() << "Col:" << item->column() << "Text:" << item->text();
    }
});
```

### 示例：个人信息表

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
    <height>360</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <layout class="QVBoxLayout" name="verticalLayout">
   <item>
    <widget class="QTableWidget" name="tableWidget">
     <property name="rowCount">
      <number>2</number>
     </property>
     <row/>
     <row/>
     <column>
      <property name="text">
       <string>姓名</string>
      </property>
     </column>
     <column>
      <property name="text">
       <string>性别</string>
      </property>
     </column>
     <column>
      <property name="text">
       <string>生日</string>
      </property>
     </column>
     <column>
      <property name="text">
       <string>婚否</string>
      </property>
     </column>
     <column>
      <property name="text">
       <string>住址</string>
      </property>
     </column>
     <item row="0" column="0">
      <property name="text">
       <string>梁山伯</string>
      </property>
      <property name="icon">
       <iconset resource="photos.qrc">
        <normaloff>:/images/butterfly01.png</normaloff>:/images/butterfly01.png</iconset>
      </property>
     </item>
     <item row="0" column="1">
      <property name="text">
       <string>男</string>
      </property>
     </item>
     <item row="0" column="2">
      <property name="text">
       <string>300/3/3</string>
      </property>
     </item>
     <item row="0" column="3">
      <property name="text">
       <string/>
      </property>
      <property name="checkState">
       <enum>Checked</enum>
      </property>
     </item>
     <item row="0" column="4">
      <property name="text">
       <string>梁家村</string>
      </property>
     </item>
     <item row="1" column="0">
      <property name="text">
       <string>祝英台</string>
      </property>
      <property name="icon">
       <iconset resource="photos.qrc">
        <normaloff>:/images/butterfly02.png</normaloff>:/images/butterfly02.png</iconset>
      </property>
     </item>
     <item row="1" column="1">
      <property name="text">
       <string>女</string>
      </property>
     </item>
     <item row="1" column="2">
      <property name="text">
       <string>301/4/4</string>
      </property>
     </item>
     <item row="1" column="3">
      <property name="checkState">
       <enum>Checked</enum>
      </property>
     </item>
     <item row="1" column="4">
      <property name="text">
       <string>祝家庄</string>
      </property>
     </item>
    </widget>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_2">
     <item>
      <widget class="QLabel" name="label">
       <property name="text">
        <string>姓名</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditName"/>
     </item>
     <item>
      <widget class="QLabel" name="label_4">
       <property name="text">
        <string>头像</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QComboBox" name="comboBoxPhotos">
       <item>
        <property name="text">
         <string> </string>
        </property>
        <property name="icon">
         <iconset resource="photos.qrc">
          <normaloff>:/images/butterfly01.png</normaloff>:/images/butterfly01.png</iconset>
        </property>
       </item>
       <item>
        <property name="text">
         <string> </string>
        </property>
        <property name="icon">
         <iconset resource="photos.qrc">
          <normaloff>:/images/butterfly02.png</normaloff>:/images/butterfly02.png</iconset>
        </property>
       </item>
       <item>
        <property name="text">
         <string> </string>
        </property>
        <property name="icon">
         <iconset resource="photos.qrc">
          <normaloff>:/images/cute01.png</normaloff>:/images/cute01.png</iconset>
        </property>
       </item>
       <item>
        <property name="text">
         <string> </string>
        </property>
        <property name="icon">
         <iconset resource="photos.qrc">
          <normaloff>:/images/cute02.png</normaloff>:/images/cute02.png</iconset>
        </property>
       </item>
       <item>
        <property name="text">
         <string> </string>
        </property>
        <property name="icon">
         <iconset resource="photos.qrc">
          <normaloff>:/images/toofat.png</normaloff>:/images/toofat.png</iconset>
        </property>
       </item>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_3">
     <item>
      <widget class="QLabel" name="label_2">
       <property name="text">
        <string>性别</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditGender"/>
     </item>
     <item>
      <widget class="QLabel" name="label_5">
       <property name="text">
        <string>生日</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QDateEdit" name="dateEdit"/>
     </item>
     <item>
      <widget class="QCheckBox" name="checkBoxIsMarried">
       <property name="text">
        <string>婚否</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_4">
     <item>
      <widget class="QLabel" name="label_3">
       <property name="text">
        <string>住址</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditAddress"/>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout">
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
      <widget class="QPushButton" name="btnAdd">
       <property name="text">
        <string>添加</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnDel">
       <property name="text">
        <string>删除</string>
       </property>
      </widget>
     </item>
     <item>
      <spacer name="horizontalSpacer_2">
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
    </layout>
   </item>
  </layout>
 </widget>
 <resources>
  <include location="photos.qrc"/>
 </resources>
 <connections/>
</ui>
```

#### widget.h

```cpp
#ifndef WIDGET_H
#define WIDGET_H

#include <QTableWidgetItem>
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
    void on_tableWidget_currentItemChanged(QTableWidgetItem* current, QTableWidgetItem* previous);

    void on_btnAdd_clicked();

    void on_btnDel_clicked();

  private:
    Ui::Widget* ui;
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QMessageBox>

// 构造函数，初始化界面和控件设置
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this); // 加载 UI 设计器生成的界面

    // 设置日期编辑器可以弹出日历控件，方便用户选择日期
    ui->dateEdit->setCalendarPopup(true);

    // 设置表格控件的行为
    // 每次选中整行
    ui->tableWidget->setSelectionBehavior(QAbstractItemView::SelectRows);
    // 设置只能单选，方便后续删除功能的使用
    ui->tableWidget->setSelectionMode(QAbstractItemView::SingleSelection);

    // 启用自动排序（会根据列头点击进行排序）
    ui->tableWidget->setSortingEnabled(true);
    // 默认按第 0 列升序排序
    ui->tableWidget->sortByColumn(0, Qt::AscendingOrder);

    // 让表格的最后一列自动拉伸填满剩余空间
    ui->tableWidget->horizontalHeader()->setStretchLastSection(true);

    // 设置行高，让图标更大一些看起来更美观
    ui->tableWidget->verticalHeader()->setDefaultSectionSize(36);
    // 设置图标大小
    ui->tableWidget->setIconSize(QSize(32, 32));

    // 修改主窗口宽度，便于展示表格拉伸效果
    QSize sz = this->size();
    sz.setWidth(640);
    this->resize(sz);
}

// 析构函数，释放 UI 内存
Widget::~Widget() {
    delete ui;
}

// 当前选中项发生变化时触发
void Widget::on_tableWidget_currentItemChanged(QTableWidgetItem* current, QTableWidgetItem* previous) {
    // 打印当前条目的行、列、文本内容
    if (current != nullptr) qDebug() << tr("当前条目行号：%1，列号：%2，文本：%3").arg(current->row()).arg(current->column()).arg(current->text());
}

// 添加按钮点击事件
void Widget::on_btnAdd_clicked() {
    QString strName = ui->lineEditName->text().trimmed(); // 获取姓名并去掉前后空格
    if (strName.isEmpty()) {
        QMessageBox::warning(this, tr("添加行"), tr("姓名不能为空！"));
        return;
    }

    // 添加数据时必须先关闭排序，否则新行可能会被移动，导致 setItem 设置错误
    ui->tableWidget->setSortingEnabled(false);

    // 获取当前行数，准备插入新行
    int nOldRowCount = ui->tableWidget->rowCount();
    ui->tableWidget->insertRow(nOldRowCount); // 在末尾插入一行

    // 头像图标（从下拉框当前项获取）
    QIcon iconHead = ui->comboBoxPhotos->itemIcon(ui->comboBoxPhotos->currentIndex());
    // 创建带图标和文本的姓名项
    QTableWidgetItem* itemName = new QTableWidgetItem(iconHead, strName);
    ui->tableWidget->setItem(nOldRowCount, 0, itemName);

    // 性别
    QString strGender = ui->lineEditGender->text();
    QTableWidgetItem* itemGender = new QTableWidgetItem(strGender);
    ui->tableWidget->setItem(nOldRowCount, 1, itemGender);

    // 生日（格式化为 yyyy/MM/dd）
    QString strBirthday = ui->dateEdit->date().toString("yyyy/MM/dd");
    QTableWidgetItem* itemBirthday = new QTableWidgetItem(strBirthday);
    ui->tableWidget->setItem(nOldRowCount, 2, itemBirthday);

    // 婚否（复选框形式）
    Qt::CheckState cks = ui->checkBoxIsMarried->checkState();
    QTableWidgetItem* itemIsMarried = new QTableWidgetItem();
    itemIsMarried->setCheckState(cks); // 设置复选框状态
    ui->tableWidget->setItem(nOldRowCount, 3, itemIsMarried);

    // 地址
    QString strAddress = ui->lineEditAddress->text();
    QTableWidgetItem* itemAddress = new QTableWidgetItem(strAddress);
    ui->tableWidget->setItem(nOldRowCount, 4, itemAddress);

    // 添加完毕后重新开启排序
    ui->tableWidget->setSortingEnabled(true);
    ui->tableWidget->sortByColumn(0, Qt::AscendingOrder);

    // 设置当前选中的单元格为刚插入的 itemName 并滚动到它
    ui->tableWidget->setCurrentItem(itemName);
    ui->tableWidget->scrollToItem(itemName);
}

// 删除按钮点击事件
void Widget::on_btnDel_clicked() {
    // 获取当前选中的单元格
    QTableWidgetItem* curItem = ui->tableWidget->currentItem();
    if (curItem == nullptr) return; // 没有选中时直接返回

    // 如果当前单元格被选中，删除其所在行
    if (curItem->isSelected()) ui->tableWidget->removeRow(curItem->row());
}
```

### 示例：成绩表

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
    <width>480</width>
    <height>400</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <layout class="QVBoxLayout" name="verticalLayout">
   <item>
    <widget class="QTableWidget" name="tableWidget"/>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout">
     <item>
      <widget class="QLabel" name="label">
       <property name="text">
        <string>指定列</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QComboBox" name="comboBoxColumns">
       <item>
        <property name="text">
         <string>语文</string>
        </property>
       </item>
       <item>
        <property name="text">
         <string>数学</string>
        </property>
       </item>
       <item>
        <property name="text">
         <string>英语</string>
        </property>
       </item>
       <item>
        <property name="text">
         <string>物理</string>
        </property>
       </item>
      </widget>
     </item>
     <item>
      <widget class="QLabel" name="label_2">
       <property name="text">
        <string>分值</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QComboBox" name="comboBoxCompares">
       <item>
        <property name="text">
         <string>==</string>
        </property>
       </item>
       <item>
        <property name="text">
         <string>&lt;=</string>
        </property>
       </item>
       <item>
        <property name="text">
         <string>&gt;=</string>
        </property>
       </item>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditFindText"/>
     </item>
     <item>
      <widget class="QPushButton" name="btnFind">
       <property name="text">
        <string>查找</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_2">
     <item>
      <widget class="QLabel" name="label_3">
       <property name="text">
        <string>姓名</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditName"/>
     </item>
     <item>
      <widget class="QPushButton" name="btnAddLines">
       <property name="text">
        <string>增加行</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnDelLines">
       <property name="text">
        <string>删除选中行</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnDesSelectedItems">
       <property name="text">
        <string>删除选中条目</string>
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
    void on_tableWidget_itemSelectionChanged();

    void on_btnFind_clicked();

    void on_btnAddLines_clicked();

    void on_btnDelLines_clicked();

    void on_btnDesSelectedItems_clicked();

  private:
    Ui::Widget* ui;
    // 初始化表格函数
    void InitScoresTable();
    // 设置某行的行首和四个单元格
    void SetTableRow(int nRow, QString strName, QString strChinese, QString strMath, QString strForeignLanguage, QString strFood);
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QDebug>
#include <QMessageBox>
#include <QTableWidgetItem>           // 表格条目
#include <QTableWidgetSelectionRange> // 表格选中区域

Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);
    InitScoresTable(); // 初始化表格
}

Widget::~Widget() {
    delete ui;
}

// 初始化成绩表格
void Widget::InitScoresTable() {
    ui->tableWidget->setRowCount(2);           // 设置2行
    ui->tableWidget->setColumnCount(4);        // 设罤列

    // 列标题
    QStringList listHeaders;
    listHeaders << tr("语文") << tr(" 数学") << tr(" 外语") << tr(" 物理");
    ui->tableWidget->setHorizontalHeaderLabels(listHeaders);

    // 初始化两行数据
    SetTableRow(0, tr(" 小明"), tr("66"), tr("77"), tr("88"), tr("99"));
    SetTableRow(1, tr(" 小萌"), tr("99"), tr("88"), tr("77"), tr("66"));
}

// 设置指定行数据
void Widget::SetTableRow(int nRow, QString strName, QString strChinese, QString strMath, QString strForeignLanguage, QString strPhysic) {
    // 行头姓名
    QTableWidgetItem* itemName = new QTableWidgetItem(strName);
    ui->tableWidget->setVerticalHeaderItem(nRow, itemName);
    // 各科成绩
    ui->tableWidget->setItem(nRow, 0, new QTableWidgetItem(strChinese));
    ui->tableWidget->setItem(nRow, 1, new QTableWidgetItem(strMath));
    ui->tableWidget->setItem(nRow, 2, new QTableWidgetItem(strForeignLanguage));
    ui->tableWidget->setItem(nRow, 3, new QTableWidgetItem(strPhysic));
}

// 选择改变时执行
void Widget::on_tableWidget_itemSelectionChanged() {
    QList<QTableWidgetItem*> listItems = ui->tableWidget->selectedItems();
    QList<QTableWidgetSelectionRange> listRanges = ui->tableWidget->selectedRanges();
    int nItemsCount = listItems.count();
    int nRangesCount = listRanges.count();
    int nCellsCount = 0;

    // 统计选中单元格数量
    for(int i = 0; i < nRangesCount; i++) {
        nCellsCount += listRanges[i].rowCount() * listRanges[i].columnCount();
    }

    // 输出选择信息
    qDebug() << tr(" 选中条目数：%1，选中区域数：%2，选中单元格数：%3")
                    .arg(nItemsCount).arg(nRangesCount).arg(nCellsCount);
}

// 搜索匹配条目
void Widget::on_btnFind_clicked() {
    QString strDstScore = ui->lineEditFindText->text().trimmed();
    if(strDstScore.isEmpty()) return;
    int nDstScore = strDstScore.toInt();

    int nTheColumn = ui->comboBoxColumns->currentIndex();
    int nCompare = ui->comboBoxCompares->currentIndex();

    int nRowCount = ui->tableWidget->rowCount();
    int nFilteredCount = 0;
    double dblTotal = 0;
    double dblAverage = 0;
    QTableWidgetItem *itemFilteredFirst = nullptr;

    ui->tableWidget->setCurrentItem(nullptr, QItemSelectionModel::Clear); // 清除选中

    // 遍历表格查找符合条件的条目
    for(int i = 0; i < nRowCount; i++) {
        QTableWidgetItem *itemCur = ui->tableWidget->item(i, nTheColumn);
        if(!itemCur) continue;

        int nCurScore = itemCur->text().trimmed().toInt();

        bool match = false;
        if(nCompare == 0 && nCurScore == nDstScore)
            match = true;
        else if(nCompare == 1 && nCurScore <= nDstScore)
            match = true;
        else if(nCompare == 2 && nCurScore >= nDstScore)
            match = true;

        if(match) {
            nFilteredCount++;
            dblTotal += nCurScore;
            itemCur->setSelected(true);

            if(!itemFilteredFirst) {
                itemFilteredFirst = itemCur;
                ui->tableWidget->setCurrentItem(itemCur);
                ui->tableWidget->scrollToItem(itemCur);
            }
        }
    }

    if(nFilteredCount > 0)
        dblAverage = dblTotal / nFilteredCount;

    QString strMsg = tr(" 匹配条目数：%1，总值：%2，均值：%3")
                         .arg(nFilteredCount).arg(dblTotal).arg(dblAverage);
    QMessageBox::information(this, tr(" 查找"), strMsg);
    ui->tableWidget->setFocus(); // 让高亮选择显示
}

// 添加新行
void Widget::on_btnAddLines_clicked() {
    QString strName = ui->lineEditName->text().trimmed();
    if(strName.isEmpty()) return;

    int nOldRowCount = ui->tableWidget->rowCount();
    ui->tableWidget->insertRow(nOldRowCount);

    SetTableRow(nOldRowCount, strName, tr("0"), tr("0"), tr("0"), tr("0"));
    ui->tableWidget->scrollToBottom();
}

// 删除选中行
void Widget::on_btnDelLines_clicked() {
    QList<int> listRowIndex;
    QList<QTableWidgetSelectionRange> listRanges = ui->tableWidget->selectedRanges();
    if(listRanges.isEmpty()) return;

    // 编集所有选中行号
    for(const auto &range : listRanges) {
        for(int j = 0; j < range.rowCount(); j++) {
            int nRowIndex = range.topRow() + j;
            if(!listRowIndex.contains(nRowIndex))
                listRowIndex.append(nRowIndex);
        }
    }

    std::sort(listRowIndex.begin(), listRowIndex.end()); // 排序后选择末尾删除
    for(int i = listRowIndex.count() - 1; i >= 0; i--) {
        ui->tableWidget->removeRow(listRowIndex[i]);
    }
}

// 删除选中单元格
void Widget::on_btnDesSelectedItems_clicked() {
    QList<QTableWidgetItem*> listItems = ui->tableWidget->selectedItems();
    if(listItems.isEmpty()) return;

    for(auto item : listItems) {
        int row = item->row();
        int col = item->column();
        delete ui->tableWidget->takeItem(row, col); // 删除单元格
    }
}
```

