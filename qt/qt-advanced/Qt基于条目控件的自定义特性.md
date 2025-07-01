## Qt 基于条目控件的自定义特性

### 拖拽（Drag and Drop）

在 Qt 中，实现条目的拖拽（Drag and Drop）功能，常见于 `QListWidget`、`QTreeWidget`、`QTableView` 或自定义 `QWidget` 中。Qt 提供了一套完整的拖放（Drag and Drop）机制，可以实现条目的拖动、拖入、拖出、接受或拒绝等交互行为。

#### 启用拖放的基本步骤

Qt 拖放涉及以下几个关键类与函数：

- `QDrag`：表示一个拖拽操作。
- `QMimeData`：存储被拖动的数据。
- `dragEnterEvent(QDragEnterEvent *event)`：拖入部件区域时触发。
- `dragMoveEvent(QDragMoveEvent *event)`：拖动过程中在部件区域移动时触发。
- `dropEvent(QDropEvent *event)`：放下时触发。
- `setAcceptDrops(true)`：允许部件接受拖拽。
- `setDragEnabled(true)`：允许部件发起拖拽。

#### 在 `QListWidget` 中实现拖放

```cpp
#include <QApplication>
#include <QListWidget>

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    QListWidget listWidget;
    listWidget.setWindowTitle("Drag and Drop Example");

    // 启用拖拽支持
    listWidget.setSelectionMode(QAbstractItemView::SingleSelection);
    listWidget.setDragEnabled(true);
    listWidget.setAcceptDrops(true);
    listWidget.setDropIndicatorShown(true);
    listWidget.setDragDropMode(QAbstractItemView::InternalMove); // 启用内部拖动

    // 添加条目
    listWidget.addItem("Item 1");
    listWidget.addItem("Item 2");
    listWidget.addItem("Item 3");

    listWidget.show();
    return app.exec();
}
```

- 该例中拖动条目会在列表内部重新排序，完全由 Qt 管理。

#### 自定义拖拽逻辑（继承 QWidget）

```cpp
class DragLabel : public QLabel {
public:
    DragLabel(const QString &text, QWidget *parent = nullptr) : QLabel(text, parent) {
        setFrameStyle(QFrame::Box | QFrame::Raised);
        setAlignment(Qt::AlignCenter);
    }

protected:
    void mousePressEvent(QMouseEvent *event) override {
        if (event->button() == Qt::LeftButton) {
            QDrag *drag = new QDrag(this);
            QMimeData *mimeData = new QMimeData;
            mimeData->setText(text());
            drag->setMimeData(mimeData);
            drag->exec(Qt::CopyAction);
        }
    }
};

class DropArea : public QLabel {
public:
    DropArea(QWidget *parent = nullptr) : QLabel(parent) {
        setMinimumSize(200, 100);
        setFrameStyle(QFrame::Sunken | QFrame::StyledPanel);
        setAlignment(Qt::AlignCenter);
        setAcceptDrops(true);
        setText("Drop here");
    }

protected:
    void dragEnterEvent(QDragEnterEvent *event) override {
        if (event->mimeData()->hasText())
            event->acceptProposedAction();
    }

    void dropEvent(QDropEvent *event) override {
        setText(event->mimeData()->text());
        event->acceptProposedAction();
    }
};
```

在主窗口中使用：

```cpp
int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    QWidget window;
    QVBoxLayout *layout = new QVBoxLayout(&window);

    DragLabel *dragLabel = new DragLabel("Drag me");
    DropArea *dropArea = new DropArea();

    layout->addWidget(dragLabel);
    layout->addWidget(dropArea);

    window.show();
    return app.exec();
}
```

#### 在模型视图结构中（如 QTableView）启用拖拽

需要自定义模型（继承 QAbstractItemModel），重写以下函数：

- `flags()`：返回包含 `Qt::ItemIsDragEnabled` 和 `Qt::ItemIsDropEnabled` 的 `Qt::ItemFlags`。
- `mimeData()`：定义拖拽中使用的数据格式。
- `dropMimeData()`：处理放下时的行为。
- `supportedDropActions()`：返回支持的动作，如 `Qt::CopyAction | Qt::MoveAction`。

#### 小结

| 功能类型       | 方法                                               |
| -------------- | -------------------------------------------------- |
| 内部拖动       | `QListWidget`、`QTreeWidget` 使用 `InternalMove`   |
| 跨组件拖动     | 自定义控件，使用 `QDrag` + `QMimeData`             |
| 视图+模型拖动  | 重写 `QAbstractItemModel` 的拖拽相关函数           |
| 设置是否可拖拽 | `setDragEnabled(true)` / `flags()` 返回对应标志    |
| 设置是否接受   | `setAcceptDrops(true)` + 重写 `drag/drop` 事件函数 |

### 示例：拖拽

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
    <width>500</width>
    <height>500</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <layout class="QVBoxLayout" name="verticalLayout">
   <item>
    <widget class="QListWidget" name="listWidget"/>
   </item>
   <item>
    <widget class="QTreeWidget" name="treeWidget">
     <column>
      <property name="text">
       <string notr="true">1</string>
      </property>
     </column>
    </widget>
   </item>
   <item>
    <widget class="QTableWidget" name="tableWidget"/>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout">
     <item>
      <widget class="QRadioButton" name="radioButtonInter">
       <property name="text">
        <string>内部拖拽</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QRadioButton" name="radioButtonOuter">
       <property name="text">
        <string>跨界拖拽</string>
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

#include <QListWidget>  //列表控件
#include <QTableWidget> //表格控件
#include <QTreeWidget>  //树形控件
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
    void on_radioButtonInter_clicked(bool checked);

    void on_radioButtonOuter_clicked(bool checked);

  private:
    Ui::Widget* ui;
    // 设置 QAbstractItemView 派生类的跨界拖拽功能
    // 对列表控件、树形控件、表格控件通用，C++多态性
    void setOuterDragDrop(QAbstractItemView* view);
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"

// 构造函数
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);

    // ========== 初始化 QListWidget 控件条目 ==========
    for (int i = 0; i < 5; i++) {
        QListWidgetItem* itemL = new QListWidgetItem(ui->listWidget); // 创建列表条目
        itemL->setText(tr("listItem %1").arg(i));                     // 设置文本，如 "listItem 0"
    }

    // ========== 初始化 QTreeWidget 控件 ==========
    ui->treeWidget->setColumnCount(2);                                    // 设置树形控件有两列
    ui->treeWidget->header()->setSectionResizeMode(QHeaderView::Stretch); // 所有列自动均分宽度

    // 创建若干条目，每个条目有两列文本
    for (int i = 0; i < 5; i++) {
        QTreeWidgetItem* itemT = new QTreeWidgetItem(ui->treeWidget); // 添加根节点
        itemT->setText(0, tr("treeItem %1, 0").arg(i));               // 第一列文本
        itemT->setText(1, tr("t%1, 1").arg(i));                       // 第二列文本
    }

    // ========== 初始化 QTableWidget 控件 ==========
    ui->tableWidget->setColumnCount(3);                                              // 设置列数为 3
    ui->tableWidget->setRowCount(3);                                                 // 设置行数为 3
    ui->tableWidget->horizontalHeader()->setSectionResizeMode(QHeaderView::Stretch); // 所有列自动拉伸

    // 创建表格项
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            QTableWidgetItem* itemTA = new QTableWidgetItem();
            itemTA->setText(tr("tableItem %1, %2").arg(i).arg(j)); // 设置内容，如 "tableItem 0, 1"
            ui->tableWidget->setItem(i, j, itemTA);                // 设置到表格中
        }
    }

    // 默认选择内部移动模式（radioButtonInter 被选中）
    ui->radioButtonInter->setChecked(true);
    on_radioButtonInter_clicked(true); // 调用槽函数，启用内部拖动
}

// 析构函数
Widget::~Widget() {
    delete ui;
}

// 内部拖动模式：控件内条目可通过拖动重新排序（不支持跨控件）
void Widget::on_radioButtonInter_clicked(bool checked) {
    if (checked) {
        // 设置列表控件为内部移动模式
        ui->listWidget->setDragDropMode(QAbstractItemView::InternalMove);
        // 设置树形控件为内部移动模式
        ui->treeWidget->setDragDropMode(QAbstractItemView::InternalMove);
        // 设置表格控件为内部移动模式
        ui->tableWidget->setDragDropMode(QAbstractItemView::InternalMove);
    }
}

// 跨控件拖动模式：支持拖动条目到其他控件（如列表 -> 表格）
void Widget::on_radioButtonOuter_clicked(bool checked) {
    if (checked) {
        // 分别为各控件启用跨控件拖动支持
        setOuterDragDrop(ui->listWidget);
        setOuterDragDrop(ui->treeWidget);
        setOuterDragDrop(ui->tableWidget);
    }
}

// 为传入的视图控件启用跨界拖拽
void Widget::setOuterDragDrop(QAbstractItemView* view) {
    view->setSelectionMode(QAbstractItemView::SingleSelection); // 设置为单选模式，避免多项拖动
    view->setDragEnabled(true);                                 // 启用拖动功能（作为拖动源）
    view->viewport()->setAcceptDrops(true);                     // 视口接收拖放（作为拖动目标）
    view->setDropIndicatorShown(true);                          // 拖动过程中显示插入指示器
    view->setDragDropMode(QAbstractItemView::DragDrop);         // 既可拖出又可拖入，支持跨控件拖放
}
```

### 右键菜单

在 Qt 中，可以通过自定义 **右键菜单（Context Menu）** 来为控件添加快捷操作项。这个功能常用于 `QListWidget`、`QTreeWidget`、`QTableWidget`、`QTextEdit` 等控件，支持用户通过右键点击弹出功能菜单。

#### 实现步骤

1. **设置上下文菜单策略**

调用 `setContextMenuPolicy(Qt::CustomContextMenu)`，允许使用自定义菜单。

2. **监听菜单信号**

连接 `customContextMenuRequested(const QPoint &pos)` 信号，在用户右键点击时弹出菜单。

3. **创建并显示 QMenu**

在槽函数中根据点击位置创建 `QMenu`，添加 `QAction`，绑定操作。

#### 示例：为 `QListWidget` 添加右键菜单

```cpp
// widget.h
#ifndef WIDGET_H
#define WIDGET_H

#include <QWidget>
#include <QListWidget>
#include <QMenu>

QT_BEGIN_NAMESPACE
namespace Ui { class Widget; }
QT_END_NAMESPACE

class Widget : public QWidget {
    Q_OBJECT

public:
    Widget(QWidget *parent = nullptr);
    ~Widget();

private slots:
    void showListContextMenu(const QPoint &pos); // 右键菜单槽函数
    void onActionDelete();                       // 删除项的动作

private:
    Ui::Widget *ui;
    QMenu *contextMenu;        // 右键菜单
    QAction *deleteAction;     // 删除操作
};

#endif // WIDGET_H
```

```cpp
// widget.cpp
#include "widget.h"
#include "ui_widget.h"

Widget::Widget(QWidget *parent)
    : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);

    // 添加测试条目
    for (int i = 0; i < 5; ++i)
        ui->listWidget->addItem(QString("Item %1").arg(i));

    // 设置自定义右键菜单策略
    ui->listWidget->setContextMenuPolicy(Qt::CustomContextMenu);

    // 连接右键菜单请求信号
    connect(ui->listWidget, &QListWidget::customContextMenuRequested,
            this, &Widget::showListContextMenu);

    // 初始化菜单和动作
    contextMenu = new QMenu(this);
    deleteAction = new QAction("删除", this);

    // 绑定动作槽函数
    connect(deleteAction, &QAction::triggered, this, &Widget::onActionDelete);

    // 添加动作到菜单
    contextMenu->addAction(deleteAction);
}

Widget::~Widget() {
    delete ui;
}

// 槽函数：右键菜单弹出位置
void Widget::showListContextMenu(const QPoint &pos) {
    QListWidgetItem *item = ui->listWidget->itemAt(pos);
    if (item) {
        // 将菜单显示在全局坐标上
        contextMenu->exec(ui->listWidget->mapToGlobal(pos));
    }
}

// 槽函数：删除当前选中的条目
void Widget::onActionDelete() {
    QListWidgetItem *item = ui->listWidget->currentItem();
    if (item) {
        delete item;
    }
}
```

#### 说明要点

| 操作                         | 描述                                                 |
| ---------------------------- | ---------------------------------------------------- |
| `setContextMenuPolicy`       | 控件开启右键菜单（通常使用 `Qt::CustomContextMenu`） |
| `customContextMenuRequested` | 右键点击信号，提供点击坐标（相对控件）               |
| `mapToGlobal`                | 将控件内的相对坐标转换为屏幕坐标，供菜单使用         |
| `QMenu::exec()`              | 在指定位置同步显示菜单，执行完后返回                 |
| `QAction::triggered()`       | 用户点击菜单项时发出信号，触发操作                   |

- 可以根据不同条目动态生成菜单项（如不同的右键功能）

- 支持子菜单 `addMenu()`、图标 `setIcon()`、快捷键 `setShortcut()`

- 可用于任意 QWidget 子类（甚至绘图区域）

### 示例：右键菜单

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
  <layout class="QVBoxLayout" name="verticalLayout">
   <item>
    <widget class="QLabel" name="label">
     <property name="text">
      <string>请用右键菜单操作：</string>
     </property>
    </widget>
   </item>
   <item>
    <widget class="QListWidget" name="listWidget"/>
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

#include <QAction>     //菜单项
#include <QListWidget> //列表控件
#include <QMenu>       //菜单
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

  public slots:
    // 弹出右键菜单的槽函数
    void onCustomContextMenuRequested(const QPoint& pos);
    // 添加条目菜单项的槽函数
    void onAddItemTriggered();
    // 编辑条目菜单项的槽函数
    void onEditItemTriggered();
    // 删除条目菜单项的槽函数
    void onDelItemTriggered();
    // 清空所有条目的菜单项槽函数
    void onClearAllTriggered();

  private:
    Ui::Widget* ui;
    // 保存右键菜单的指针
    QMenu* m_menuContext;
    // 创建菜单并关联信号和槽函数
    void createMenu();
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QMessageBox>

Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);
    createMenu(); // 创建右键菜单
}

Widget::~Widget() {
    delete ui;
}

// 创建并初始化右键菜单
void Widget::createMenu() {
    // 创建菜单对象（菜单标题文本不会显示，仅用于调试可读性）
    m_menuContext = new QMenu(tr("ContextMenu"), this);

    // 创建“添加条目”菜单项
    QAction* actAdd = new QAction(tr("添加条目"), this);
    m_menuContext->addAction(actAdd);

    // 创建“编辑条目”菜单项
    QAction* actEdit = new QAction(tr("编辑条目"), this);
    m_menuContext->addAction(actEdit);

    // 创建“删除条目”菜单项
    QAction* actDel = new QAction(tr("删除条目"), this);
    m_menuContext->addAction(actDel);

    // 创建“清空所有”菜单项
    QAction* actClearAll = new QAction(tr("清空所有"), this);
    m_menuContext->addAction(actClearAll);

    // 启用列表控件的自定义右键菜单功能
    ui->listWidget->setContextMenuPolicy(Qt::CustomContextMenu);

    // 将“请求右键菜单”的信号连接到自定义槽函数
    connect(ui->listWidget, &QListWidget::customContextMenuRequested, this, &Widget::onCustomContextMenuRequested);

    // 为每个菜单项连接点击槽函数
    connect(actAdd, &QAction::triggered, this, &Widget::onAddItemTriggered);
    connect(actEdit, &QAction::triggered, this, &Widget::onEditItemTriggered);
    connect(actDel, &QAction::triggered, this, &Widget::onDelItemTriggered);
    connect(actClearAll, &QAction::triggered, this, &Widget::onClearAllTriggered);
}

// 槽函数：处理右键菜单请求
void Widget::onCustomContextMenuRequested(const QPoint& pos) {
    // 将控件内相对坐标转换为屏幕全局坐标
    QPoint screenPos = ui->listWidget->mapToGlobal(pos);
    // 显示右键菜单（阻塞式，用户点了才返回）
    QAction* actRet = m_menuContext->exec(screenPos);
    if (actRet != nullptr) {
        // 菜单项非空，打印被点击的菜单项文本（调试用）
        qDebug() << tr("返回的菜单项：") + actRet->text();
    }
}

// 槽函数：添加条目
void Widget::onAddItemTriggered() {
    // 创建新条目
    QListWidgetItem* itemNew = new QListWidgetItem(tr("新建条目"));
    // 设置为可编辑条目
    itemNew->setFlags(itemNew->flags() | Qt::ItemIsEditable);
    // 加入列表控件
    ui->listWidget->addItem(itemNew);
    // 设置当前项为新条目
    ui->listWidget->setCurrentItem(itemNew);
    // 弹出编辑框以立即修改文本
    ui->listWidget->editItem(itemNew);
}

// 槽函数：编辑当前选中条目
void Widget::onEditItemTriggered() {
    // 获取当前选中项
    QListWidgetItem* curItem = ui->listWidget->currentItem();
    if (curItem == nullptr) {
        // 没有选中项，打印提示并返回
        qDebug() << tr("没有选中的条目。");
        return;
    }
    // 设置为可编辑状态
    curItem->setFlags(curItem->flags() | Qt::ItemIsEditable);
    // 弹出编辑框
    ui->listWidget->editItem(curItem);
}

// 槽函数：删除当前选中条目
void Widget::onDelItemTriggered() {
    QListWidgetItem* curItem = ui->listWidget->currentItem();
    if (curItem == nullptr) {
        qDebug() << tr("没有选中的条目。");
        return;
    }
    // 删除选中项
    delete curItem;
    curItem = nullptr;
}

// 槽函数：清空所有条目（带确认）
void Widget::onClearAllTriggered() {
    int nCount = ui->listWidget->count();
    if (nCount < 1) return; // 没有内容就不处理

    // 弹出确认对话框
    int buttonRet = QMessageBox::question(this, tr("清空所有"), tr("请确认是否清空所有条目？"));
    if (buttonRet == QMessageBox::Yes) {
        ui->listWidget->clear(); // 确认后清空
    } else {
        return; // 取消不处理
    }
}
```

### 示例：基于条目控件的样式表

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
    <width>440</width>
    <height>330</height>
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
    <layout class="QGridLayout" name="gridLayout">
     <item row="0" column="0">
      <widget class="QPushButton" name="pushButtonAlternatingRowColors">
       <property name="text">
        <string>双色交替行</string>
       </property>
      </widget>
     </item>
     <item row="0" column="1">
      <widget class="QPushButton" name="pushButtonSelectionCustom">
       <property name="text">
        <string>选中条目定制</string>
       </property>
      </widget>
     </item>
     <item row="0" column="2">
      <widget class="QPushButton" name="pushButtonItemCustom">
       <property name="text">
        <string>所有条目定制</string>
       </property>
      </widget>
     </item>
     <item row="1" column="0">
      <widget class="QPushButton" name="pushButtonCornerButtonCustom">
       <property name="text">
        <string>角按钮定制</string>
       </property>
      </widget>
     </item>
     <item row="1" column="1">
      <widget class="QPushButton" name="pushButtonHeaderCustom">
       <property name="text">
        <string>表头定制</string>
       </property>
      </widget>
     </item>
     <item row="1" column="2">
      <widget class="QPushButton" name="pushButtonClearStyle">
       <property name="text">
        <string>清空样式表</string>
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
    void on_pushButtonAlternatingRowColors_clicked();

    void on_pushButtonSelectionCustom_clicked();

    void on_pushButtonItemCustom_clicked();

    void on_pushButtonCornerButtonCustom_clicked();

    void on_pushButtonHeaderCustom_clicked();

    void on_pushButtonClearStyle_clicked();

  private:
    Ui::Widget* ui;
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"

Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);

    // 设置表格为 4 行 4 列
    ui->tableWidget->setColumnCount(4);
    ui->tableWidget->setRowCount(4);

    // 设置表格列宽自动拉伸，所有列均匀分配宽度
    ui->tableWidget->horizontalHeader()->setSectionResizeMode(QHeaderView::Stretch);

    // 初始化表格内容
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            // 新建条目，并设置内容为 “tableItem i, j”
            QTableWidgetItem* itemNew = new QTableWidgetItem();
            itemNew->setText(tr("tableItem %1, %2").arg(i).arg(j));
            ui->tableWidget->setItem(i, j, itemNew); // 插入到表格中
        }
    }
}

Widget::~Widget() {
    delete ui;
}

// 槽函数：启用交替行颜色显示
void Widget::on_pushButtonAlternatingRowColors_clicked() {
    // 启用交替行颜色功能
    ui->tableWidget->setAlternatingRowColors(true);

    // 设置交替行的背景颜色为天蓝色，网格线颜色为深绿色
    QString strStyle = " QTableWidget{ alternate-background-color: skyblue; "
                       "gridline-color: darkgreen; } ";

    // 追加样式表（保留旧样式）
    ui->tableWidget->setStyleSheet(ui->tableWidget->styleSheet() + strStyle);
}

// 槽函数：设置选中条目的前景色和背景色
void Widget::on_pushButtonSelectionCustom_clicked() {
    // 设置选中条目的前景色为红色，背景色为黄色
    QString strStyle = " QTableWidget{ selection-color: red; "
                       "selection-background-color: yellow; } ";

    // 追加样式表
    ui->tableWidget->setStyleSheet(ui->tableWidget->styleSheet() + strStyle);

    // 获取当前选中的条目
    QTableWidgetItem* curItem = ui->tableWidget->currentItem();
    if (curItem != nullptr) curItem->setSelected(true); // 强制将当前条目标记为选中状态
}

// 槽函数：设置所有单元格条目的颜色样式
void Widget::on_pushButtonItemCustom_clicked() {
    // 设置所有条目的前景色为蓝色，背景色为浅绿色
    QString strStyle = " QTableWidget::item{ "
                       "color: blue; "
                       "background-color: lightgreen; "
                       "} ";

    // 追加样式表（注意：此样式可能覆盖其他样式）
    ui->tableWidget->setStyleSheet(ui->tableWidget->styleSheet() + strStyle);
}

// 槽函数：设置左上角按钮（角按钮）的样式
void Widget::on_pushButtonCornerButtonCustom_clicked() {
    // 设置左上角的按钮（行列头交叉处）为绿色，边框为立体效果
    QString strStyle = " QTableCornerButton::section{ "
                       " background: green;  "
                       " border: 2px outset green; "
                       "} ";

    // 追加样式表
    ui->tableWidget->setStyleSheet(ui->tableWidget->styleSheet() + strStyle);
}

// 槽函数：设置表头（行头/列头）的样式
void Widget::on_pushButtonHeaderCustom_clicked() {
    // 设置表头文字颜色为深蓝色，背景颜色为青色
    QString strStyle = " QHeaderView::section { "
                       " color: darkblue; "
                       " background-color: cyan; "
                       "} ";

    // 追加样式表
    ui->tableWidget->setStyleSheet(ui->tableWidget->styleSheet() + strStyle);
}

// 槽函数：清除所有样式
void Widget::on_pushButtonClearStyle_clicked() {
    // 打印当前样式表内容，便于调试
    qDebug() << "old style sheets: \r\n" << ui->tableWidget->styleSheet() << Qt::endl;

    // 清空样式表，恢复默认样式
    ui->tableWidget->setStyleSheet("");

    // 同时关闭交替行颜色显示
    ui->tableWidget->setAlternatingRowColors(false);
}
```