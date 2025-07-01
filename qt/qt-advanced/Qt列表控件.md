## Qt 列表控件

### 继承图

```css
QWidget
 └── QAbstractScrollArea
      └── QAbstractItemView
           ├── QListView
           │    └── QListWidget
           ├── QTreeView
           │    └── QTreeWidget
           └── QTableView
                └── QTableWidget
```

### QListWidget

`QListWidget` 是 Qt 框架中用于展示和管理列表项（List Items）的控件，基于 `QListView` 和 `QListWidgetItem` 封装而成，适合快速实现简单的列表功能。

#### 核心特点

- 显示一个**垂直列表**，每个列表项是 `QListWidgetItem` 对象。

- 支持文字、图标、复选框、自定义项等。

- 内建多选、拖拽、排序、编辑等功能。

- 与 `QListView + QStandardItemModel` 相比，`QListWidget` 更适合小型项目和快速开发。

#### 示例代码

##### 基本用法

```cpp
QListWidget *listWidget = new QListWidget(this);
listWidget->addItem("Apple");
listWidget->addItem("Banana");

QListWidgetItem *item = new QListWidgetItem("Cherry");
item->setIcon(QIcon(":/icons/cherry.png"));
listWidget->addItem(item);
```

##### 获取当前项

```cpp
connect(listWidget, &QListWidget::itemClicked, [](QListWidgetItem *item){
    qDebug() << "Clicked item:" << item->text();
});
```

#####  删除项

```cpp
delete listWidget->takeItem(listWidget->currentRow());
```

##### 设置选择模式

```cpp
listWidget->setSelectionMode(QAbstractItemView::MultiSelection);
```

#### 常用 API

| 函数/属性                    | 说明                                  |
| ---------------------------- | ------------------------------------- |
| `addItem(QString)`           | 添加文本项                            |
| `addItem(QListWidgetItem *)` | 添加自定义项                          |
| `insertItem(int, QString)`   | 指定位置插入项                        |
| `takeItem(int row)`          | 移除并返回指定行的项（需手动 delete） |
| `clear()`                    | 清空所有项                            |
| `count()`                    | 获取总项数                            |
| `item(int row)`              | 获取指定行的项                        |
| `currentItem()`              | 当前被选中的项                        |
| `selectedItems()`            | 返回所有选中的项                      |
| `setSelectionMode()`         | 设置选择模式（单选、多选等）          |
| `sortItems(Qt::SortOrder)`   | 对列表项排序                          |

#### 自定义项（高级）

可以继承 `QListWidgetItem` 或使用 `setItemWidget()` 将 `QWidget` 嵌入某个 item：

```cpp
QListWidgetItem *item = new QListWidgetItem(listWidget);
QWidget *customWidget = new CustomWidget(); // 自定义 QWidget
listWidget->setItemWidget(item, customWidget);
```

#### 适用场景

- 选项列表（如设置面板、菜单）

- 简单的任务列表或消息列表

- 拖拽排序的 UI

- 项目选择器等

### QListWidgetItem

`QListWidgetItem` 是 Qt 框架中 `QListWidget` 控件使用的列表项类，用于表示列表控件中的每一个条目。每个 `QListWidgetItem` 都可以携带文本、图标、自定义数据，并支持编辑、拖放、对齐、排序等功能。

#### 基本用途

`QListWidgetItem` 通常配合 `QListWidget` 一起使用：

```cpp
QListWidget *listWidget = new QListWidget(this);
QListWidgetItem *item = new QListWidgetItem("Item 1");
listWidget->addItem(item);
```

#### 常用构造函数

```cpp
QListWidgetItem(const QString &text, QListWidget *parent = nullptr, int type = Type);
QListWidgetItem(const QIcon &icon, const QString &text, QListWidget *parent = nullptr, int type = Type);
```

- `text`：显示的文本内容

- `icon`：可选图标

- `parent`：所属的 `QListWidget`（可省略后手动添加）

- `type`：用户自定义的 item 类型（可用于识别特殊项）

#### 常用方法

##### 文本 & 图标

```cpp
item->setText("New Text");
QString text = item->text();
item->setIcon(QIcon(":/img/icon.png"));
```

##### 字体 & 对齐

```cpp
item->setFont(QFont("Arial", 12));
item->setTextAlignment(Qt::AlignCenter);
```

##### 状态控制

```cpp
item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable | Qt::ItemIsEditable);
```

##### 颜色

```cpp
item->setForeground(Qt::red);  // 文本颜色
item->setBackground(Qt::yellow); // 背景颜色
```

##### 自定义数据

可以使用 `QVariant` 储存任意类型数据（用于业务逻辑关联）：

```cpp
item->setData(Qt::UserRole, 1234);
int id = item->data(Qt::UserRole).toInt();
```

#### 与 `QListWidget` 交互

- **添加项目**

```cpp
listWidget->addItem(new QListWidgetItem("Apple"));
listWidget->insertItem(0, new QListWidgetItem("Banana"));
```

- **访问项目**

```cpp
QListWidgetItem *item = listWidget->item(0);
```

- **删除项目**

```cpp
delete listWidget->takeItem(index); // 释放内存
```

#### 自定义项扩展

如果需要更复杂的表现，可以为每个条目设置自定义控件（用 `QListWidget::setItemWidget()`）：

```cpp
QListWidgetItem *item = new QListWidgetItem(listWidget);
QWidget *customWidget = new QWidget(); // 控件
listWidget->setItemWidget(item, customWidget);
```

### 示例：游戏装备列表

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
    <width>545</width>
    <height>341</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <layout class="QHBoxLayout" name="horizontalLayout">
   <item>
    <layout class="QVBoxLayout" name="verticalLayout_2">
     <item>
      <widget class="QListWidget" name="listWidget">
       <item>
        <property name="text">
         <string>大刀</string>
        </property>
        <property name="toolTip">
         <string>&lt;html&gt;&lt;head/&gt;&lt;body&gt;&lt;p&gt;&lt;img src=&quot;:/icons/afac.jpg&quot;/&gt;&lt;/p&gt;&lt;p&gt;&lt;span style=&quot; font-family:'宋体,arial,sans-serif'; font-size:12px; color:#0090ff; background-color:#121212;&quot;&gt;+999点攻击力&lt;br/&gt;+30%攻速&lt;br/&gt;-20点敏 捷&lt;br/&gt;&lt;/span&gt;&lt;span style=&quot; font-family:'宋体,arial,sans-serif'; font-size:12px; color:#66ffff; background-color:#121212;&quot;&gt;+35%的物理攻击闪避&lt;/span&gt;&lt;/p&gt;&lt;/body&gt;&lt;/html&gt;</string>
        </property>
        <property name="icon">
         <iconset resource="icons.qrc">
          <normaloff>:/icons/afac.jpg</normaloff>:/icons/afac.jpg</iconset>
        </property>
       </item>
       <item>
        <property name="text">
         <string>宝典</string>
        </property>
        <property name="toolTip">
         <string>&lt;html&gt;&lt;head/&gt;&lt;body&gt;&lt;p&gt;&lt;img src=&quot;:/icons/ajen.jpg&quot;/&gt;&lt;/p&gt;&lt;p&gt;&lt;span style=&quot; font-family:'宋体,arial,sans-serif'; font-size:12px; color:#0090ff; background-color:#121212;&quot;&gt;+10点攻击力&lt;br/&gt;+10%攻速&lt;br/&gt;+10点敏 捷&lt;br/&gt;&lt;/span&gt;&lt;span style=&quot; font-family:'宋体,arial,sans-serif'; font-size:12px; color:#66ffff; background-color:#121212;&quot;&gt;+40%的物理攻击闪避&lt;/span&gt;&lt;/p&gt;&lt;/body&gt;&lt;/html&gt;</string>
        </property>
        <property name="icon">
         <iconset resource="icons.qrc">
          <normaloff>:/icons/ajen.jpg</normaloff>:/icons/ajen.jpg</iconset>
        </property>
       </item>
       <item>
        <property name="text">
         <string>鞋子</string>
        </property>
        <property name="toolTip">
         <string>&lt;html&gt;&lt;head/&gt;&lt;body&gt;&lt;p&gt;&lt;img src=&quot;:/icons/belv.jpg&quot;/&gt;&lt;/p&gt;&lt;p&gt;&lt;span style=&quot; font-family:'宋体,arial,sans-serif'; font-size:12px; color:#0090ff; background-color:#121212;&quot;&gt;+10点攻击力&lt;br/&gt;+10%攻速&lt;br/&gt;+80点敏 捷&lt;br/&gt;&lt;/span&gt;&lt;span style=&quot; font-family:'宋体,arial,sans-serif'; font-size:12px; color:#66ffff; background-color:#121212;&quot;&gt;+50%的物理攻击闪避&lt;/span&gt;&lt;/p&gt;&lt;/body&gt;&lt;/html&gt;</string>
        </property>
        <property name="icon">
         <iconset resource="icons.qrc">
          <normaloff>:/icons/belv.jpg</normaloff>:/icons/belv.jpg</iconset>
        </property>
       </item>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditToolTip"/>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QVBoxLayout" name="verticalLayout">
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
      <widget class="QPushButton" name="btnViewMode">
       <property name="text">
        <string>切换显示模式</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnLoad">
       <property name="text">
        <string>加载</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnSave">
       <property name="text">
        <string>保存</string>
       </property>
      </widget>
     </item>
     <item>
      <spacer name="verticalSpacer">
       <property name="orientation">
        <enum>Qt::Orientation::Vertical</enum>
       </property>
       <property name="sizeHint" stdset="0">
        <size>
         <width>20</width>
         <height>40</height>
        </size>
       </property>
      </spacer>
     </item>
     <item>
      <widget class="QPushButton" name="btnEditToolTip">
       <property name="text">
        <string>编辑工具提示</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
  </layout>
 </widget>
 <resources>
  <include location="icons.qrc"/>
 </resources>
 <connections/>
</ui>
```

#### widget.h

```cpp
#ifndef WIDGET_H
#define WIDGET_H

#include <QWidget>
#include <QListWidget>
#include <QListWidgetItem>

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
    void on_listWidget_currentItemChanged(QListWidgetItem *current, QListWidgetItem *previous);
    void on_listWidget_itemChanged(QListWidgetItem *item);
    void on_btnAdd_clicked();
    void on_btnDel_clicked();
    void on_btnViewMode_clicked();
    void on_btnLoad_clicked();
    void on_btnSave_clicked();
    void on_btnEditToolTip_clicked();

  private:
    Ui::Widget* ui;
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QDataStream>
#include <QDebug>
#include <QFile>
#include <QFileDialog>
#include <QIcon>
#include <QMessageBox>

// 构造函数，初始化界面并设置列表项的属性
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);
    int nCount = ui->listWidget->count();
    for (int i = 0; i < nCount; i++) {
        QListWidgetItem* item = ui->listWidget->item(i);
        item->setFlags((item->flags()) | Qt::ItemIsEditable); // 设置可编辑
        item->setCheckState(Qt::Unchecked);                   // 初始化为未选中状态
    }
}

// 析构函数，释放资源
Widget::~Widget() {
    delete ui;
}

// 当当前选中项改变时，更新右侧文本框内容为该项的 ToolTip
void Widget::on_listWidget_currentItemChanged(QListWidgetItem* current, QListWidgetItem* previous) {
    if (current == nullptr) return;
    QString strToolTip = current->toolTip();
    ui->lineEditToolTip->setText(strToolTip);
}

// 当列表项状态改变时触发（例如勾选状态变化）
void Widget::on_listWidget_itemChanged(QListWidgetItem* item) {
    if (item == nullptr) return;
    if (item->checkState() != Qt::Checked) return;

    // 统计已勾选的项数
    int nCount = ui->listWidget->count();
    int nUsingItemsCount = 0;
    for (int i = 0; i < nCount; ++i) {
        QListWidgetItem* theItem = ui->listWidget->item(i);
        if (theItem->checkState() == Qt::Checked) nUsingItemsCount++;
    }

    // 超过 6 个时弹出警告框并撤销本次勾选
    if (nUsingItemsCount > 6) {
        QMessageBox::warning(this, tr("携带数目检查"), tr("DOTA 装备最多带 6 个！"));
        item->setCheckState(Qt::Unchecked);
    }
}

// 添加新装备按钮：选择图标文件，创建带图标的新项，并进入编辑模式
void Widget::on_btnAdd_clicked() {
    QString strItemFileName = QFileDialog::getOpenFileName(this, tr("选择装备图标文件"), tr("."), tr("Image files(*.jpg *.png *.bmp);;All files(*)"));

    if (strItemFileName.isEmpty()) return;

    QIcon iconNew(strItemFileName);
    QListWidgetItem* itemNew = new QListWidgetItem(iconNew, tr("新装备名称"), ui->listWidget);
    itemNew->setFlags((itemNew->flags()) | Qt::ItemIsEditable);
    itemNew->setCheckState(Qt::Unchecked);
    ui->listWidget->setCurrentItem(itemNew);
    ui->listWidget->editItem(itemNew);
}

// 删除当前选中项
void Widget::on_btnDel_clicked() {
    int nCurRow = ui->listWidget->currentRow();
    if (nCurRow < 0) return;
    QListWidgetItem* itemDel = ui->listWidget->takeItem(nCurRow); // 从列表中移除
    delete itemDel;                                               // 删除对象
    itemDel = nullptr;
}

// 切换视图模式：列表模式 <-> 图标模式
void Widget::on_btnViewMode_clicked() {
    QListView::ViewMode vm = ui->listWidget->viewMode();
    if (QListView::ListMode == vm) {
        ui->listWidget->setViewMode(QListView::IconMode);
    } else {
        ui->listWidget->setViewMode(QListView::ListMode);
    }
}

// 加载保存的 items 文件
void Widget::on_btnLoad_clicked() {
    QString strOpenName = QFileDialog::getOpenFileName(this, tr("打开items文件"), tr("."), tr("Items files(*.items)"));
    if (strOpenName.isEmpty()) return;

    QFile fileOpen(strOpenName);
    if (!fileOpen.open(QIODevice::ReadOnly)) {
        QMessageBox::warning(this, tr("打开文件"), tr("打开指定文件失败，请检查文件是否存在和读取权限！"));
        return;
    }

    QDataStream dsIn(&fileOpen);
    qint32 nCount;
    dsIn >> nCount;

    if (nCount <= 0) {
        QMessageBox::warning(this, tr("文件加载"), tr("文件中无条目数据可以加载！"));
        return;
    }

    for (qint32 i = 0; i < nCount; i++) {
        QListWidgetItem* theItem = new QListWidgetItem(ui->listWidget);
        dsIn >> *theItem;
        theItem->setFlags((theItem->flags()) | Qt::ItemIsEditable);
    }
}

// 保存当前列表到 items 文件
void Widget::on_btnSave_clicked() {
    QString strSaveName = QFileDialog::getSaveFileName(this, tr("保存items文件"), tr("."), tr("Items files(*.items)"));
    if (strSaveName.isEmpty()) return;

    QFile fileSave(strSaveName);
    if (!fileSave.open(QIODevice::WriteOnly)) {
        QMessageBox::warning(this, tr("打开写入文件"), tr("打开要写入的文件失败，请检查文件名和是否具有写入权限！"));
        return;
    }

    QDataStream dsOut(&fileSave);
    qint32 nCount = ui->listWidget->count();
    dsOut << nCount;

    for (qint32 i = 0; i < nCount; i++) {
        QListWidgetItem* theItem = ui->listWidget->item(i);
        dsOut << *theItem;
    }
}

// 编辑当前选中项的 ToolTip（提示信息）
void Widget::on_btnEditToolTip_clicked() {
    QString strNew = ui->lineEditToolTip->text();
    QListWidgetItem* curItem = ui->listWidget->currentItem();
    if (curItem != nullptr) curItem->setToolTip(strNew);
}
```

### 示例：歌曲列表

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
  <layout class="QHBoxLayout" name="horizontalLayout">
   <item>
    <layout class="QVBoxLayout" name="verticalLayout">
     <item>
      <widget class="QListWidget" name="listWidget"/>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditTemplate"/>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QVBoxLayout" name="verticalLayout_2">
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
      <widget class="QPushButton" name="btnExportM3U">
       <property name="text">
        <string>导出m3u</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QCheckBox" name="checkBoxAutoSort">
       <property name="text">
        <string>自动排序</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QCheckBox" name="checkBoxReverse">
       <property name="text">
        <string>逆序排列</string>
       </property>
      </widget>
     </item>
     <item>
      <spacer name="verticalSpacer">
       <property name="orientation">
        <enum>Qt::Orientation::Vertical</enum>
       </property>
       <property name="sizeHint" stdset="0">
        <size>
         <width>20</width>
         <height>40</height>
        </size>
       </property>
      </spacer>
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
    void on_btnAdd_clicked();
    void on_btnDel_clicked();
    void on_btnExportM3U_clicked();
    void on_btnFind_clicked();
    void on_checkBoxAutoSort_clicked(bool checked);
    void on_checkBoxReverse_clicked(bool checked);

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
#include <QFileDialog>     // 文件对话框，用于选择文件
#include <QFileInfo>       // 用于获取文件信息（如文件名、路径等）
#include <QListWidget>     // 列表控件类
#include <QListWidgetItem> // 列表控件的条目类
#include <QMessageBox>     // 消息框控件，用于弹出提示信息

// 构造函数
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);                                                      // 设置 UI
    ui->listWidget->setSelectionMode(QAbstractItemView::ExtendedSelection); // 设置列表支持多选
    // 默认勾选自动排序复选框
    ui->checkBoxAutoSort->setCheckState(Qt::Checked);
}

// 析构函数
Widget::~Widget() {
    delete ui;
}

// 点击“添加”按钮的槽函数
void Widget::on_btnAdd_clicked() {
    // 弹出文件选择对话框，允许用户选择多个音乐文件
    QStringList slist = QFileDialog::getOpenFileNames(this, tr("添加多个音乐文件"), tr("."), tr("Music files(*.mp3 *.wma *.wav);;All files(*)"));
    int nCount = slist.count(); // 获取选中的文件数
    if (nCount < 1) return;     // 没有选中文件就直接返回

    // 遍历每一个选中的文件
    for (int i = 0; i < nCount; i++) {
        // 创建新条目，并添加到 listWidget 中
        QListWidgetItem* theItem = new QListWidgetItem(ui->listWidget);
        QFileInfo fi(slist[i]);                     // 获取文件信息
        theItem->setText(fi.completeBaseName());    // 设置显示的名称为不带扩展名的基本名
        theItem->setToolTip(fi.absoluteFilePath()); // 设置工具提示为完整路径，便于后续导出
    }
}

// 点击“删除”按钮的槽函数
void Widget::on_btnDel_clicked() {
    QList<QListWidgetItem*> itemList = ui->listWidget->selectedItems(); // 获取所有被选中的条目
    int nCount = itemList.count();                                      // 数量
    if (nCount < 1) return;
    // 删除选中的条目（从后往前删以避免索引混乱）
    for (int i = nCount - 1; i >= 0; i--) {
        int theRow = ui->listWidget->row(itemList[i]); // 获取条目的行号
        ui->listWidget->takeItem(theRow);              // 从控件中移除条目
        delete itemList[i];                            // 删除对象释放内存
        itemList[i] = nullptr;
    }
    itemList.clear(); // 清空指针列表
}

// 点击“导出M3U”按钮的槽函数
void Widget::on_btnExportM3U_clicked() {
    int nCount = ui->listWidget->count(); // 获取列表条目数量
    if (nCount < 1) return;               // 没有条目就返回

    // 弹出保存文件对话框，获取要保存的文件名
    QString strName = QFileDialog::getSaveFileName(this, tr("保存为 M3U 文件"), tr("."), tr("M3U files(*.m3u)"));
    if (strName.isEmpty()) return;

    QFile fileOut(strName); // 创建文件对象
    // 尝试以写文本方式打开文件
    if (!fileOut.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QMessageBox::warning(this, tr("打开文件"), tr("无法打开指定文件，请检查是否有写入权限！"));
        return;
    }

    QTextStream tsOut(&fileOut);        // 创建文本流用于写入
    tsOut << tr("#EXTM3U") << Qt::endl; // 写入 M3U 文件头

    // 将每一个条目的完整路径写入文件
    for (int i = 0; i < nCount; i++) {
        QString strCurName = ui->listWidget->item(i)->toolTip(); // 获取完整路径
        tsOut << strCurName << Qt::endl;
    }
}

// 点击“查找”按钮的槽函数
void Widget::on_btnFind_clicked() {
    QString strTemplate = ui->lineEditTemplate->text(); // 获取查找关键词
    if (strTemplate.isEmpty()) return;

    // 清除之前选中的条目
    ui->listWidget->setCurrentItem(NULL, QItemSelectionModel::Clear);

    // 查找所有包含关键词的条目
    QList<QListWidgetItem*> list = ui->listWidget->findItems(strTemplate, Qt::MatchContains);
    int nCount = list.count();
    if (nCount < 1) {
        QMessageBox::information(this, tr("查找条目"), tr("没有找到匹配的条目文本。"));
        return;
    }

    // 高亮第一个匹配项并滚动到它的位置
    ui->listWidget->setCurrentItem(list[0]);
    ui->listWidget->scrollToItem(list[0], QAbstractItemView::PositionAtTop);

    // 设置所有匹配项为选中状态
    for (int i = 0; i < nCount; i++) {
        list[i]->setSelected(true);
    }

    // 设置焦点到列表控件
    ui->listWidget->setFocus();
}

// “自动排序”复选框点击槽函数
void Widget::on_checkBoxAutoSort_clicked(bool checked) {
    if (checked) {
        ui->listWidget->setSortingEnabled(true); // 启用排序功能
        ui->checkBoxReverse->setEnabled(true);   // 启用“逆序”复选框
        // 根据“逆序”复选框判断排序方式
        if (ui->checkBoxReverse->checkState() != Qt::Checked) {
            ui->listWidget->sortItems(Qt::AscendingOrder); // 正序排序
        } else {
            ui->listWidget->sortItems(Qt::DescendingOrder); // 逆序排序
        }
    } else {
        ui->listWidget->setSortingEnabled(false); // 关闭排序功能
        ui->checkBoxReverse->setEnabled(false);   // 禁用“逆序”复选框
    }
}

// “逆序排序”复选框点击槽函数
void Widget::on_checkBoxReverse_clicked(bool checked) {
    if (!checked) {
        ui->listWidget->sortItems(Qt::AscendingOrder); // 正序
    } else {
        ui->listWidget->sortItems(Qt::DescendingOrder); // 逆序
    }
}
```
