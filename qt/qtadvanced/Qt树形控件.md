## Qt 树形控件

### QTreeWidget

`QTreeWidget` 是 Qt 提供的一个用于**显示层级结构数据**的控件，类似文件资源管理器中的文件夹树。它继承自 `QTreeView`，但使用起来更简单，适合用于结构不太复杂的场景。

#### 基本特性

- 支持多层级树状结构

- 每个节点是 `QTreeWidgetItem`

- 每列可自定义内容，可设置标题、图标、复选框等

- 支持展开/收起、选择、拖拽排序、编辑

- 可响应信号处理交互（如点击、双击、选中等）

#### 常用用法示例

```cpp
QTreeWidget* tree = new QTreeWidget(this);
tree->setColumnCount(2);                      // 设置列数
tree->setHeaderLabels({"名称", "描述"});      // 设置表头标题

// 添加顶层节点
QTreeWidgetItem* root = new QTreeWidgetItem(tree);
root->setText(0, "根节点");
root->setText(1, "这是根节点");

// 添加子节点
QTreeWidgetItem* child1 = new QTreeWidgetItem(root);
child1->setText(0, "子节点1");
child1->setText(1, "子节点1的描述");

QTreeWidgetItem* child2 = new QTreeWidgetItem(root);
child2->setText(0, "子节点2");

// 展开所有
tree->expandAll();
```

#### 常用函数

| 函数名                          | 作用                                   |
| ------------------------------- | -------------------------------------- |
| `addTopLevelItem()`             | 添加顶层节点                           |
| `topLevelItem(int)`             | 获取顶层节点                           |
| `currentItem()`                 | 获取当前选中项                         |
| `invisibleRootItem()`           | 获取隐藏的根节点，常用于统一添加子节点 |
| `clear()`                       | 清空所有内容                           |
| `expandAll()` / `collapseAll()` | 展开/收起所有节点                      |

#### 信号（Signals）

| 信号                                                     | 说明                     |
| -------------------------------------------------------- | ------------------------ |
| `itemClicked(QTreeWidgetItem*, int)`                     | 单击某项                 |
| `itemDoubleClicked(QTreeWidgetItem*, int)`               | 双击某项                 |
| `itemChanged(QTreeWidgetItem*, int)`                     | 项目内容变化（如勾选框） |
| `currentItemChanged(QTreeWidgetItem*, QTreeWidgetItem*)` | 当前选中项变化           |

#### 注意事项

- 若需要响应复选框状态变化，需先设置：

```cpp
// 为 item 这个 QTreeWidgetItem 的第 0 列设置一个复选框，并将其状态设为未选中。
item->setCheckState(0, Qt::Unchecked);
```

- 然后监听 `itemChanged` 信号。

`QTreeWidgetItem` 不自动管理父子关系销毁，使用时注意内存管理，推荐设置父对象或使用 `QTreeWidget` 管理生命周期。

### QTreeWidgetItem

`QTreeWidgetItem` 是 Qt 框架中用于表示树形控件（`QTreeWidget`）中每一项的数据结构。它属于 `QtWidgets` 模块，是构建树形结构 UI 的关键组件。

#### 构造函数常见用法

```cpp
// 创建一个没有父节点的根项
QTreeWidgetItem *item = new QTreeWidgetItem();

// 创建并添加子项到指定父项
QTreeWidgetItem *child = new QTreeWidgetItem(parentItem);

// 指定列数并赋值
QTreeWidgetItem *item = new QTreeWidgetItem(QStringList() << "Name" << "Age");
```

#### 常用方法

| 方法                                                   | 说明                                                |
| ------------------------------------------------------ | --------------------------------------------------- |
| `setText(int column, const QString &text)`             | 设置指定列的文本                                    |
| `text(int column)`                                     | 获取指定列的文本                                    |
| `setIcon(int column, const QIcon &icon)`               | 设置图标                                            |
| `setCheckState(int column, Qt::CheckState state)`      | 设置复选框状态（`Qt::Unchecked`、`Qt::Checked` 等） |
| `checkState(int column)`                               | 获取复选框状态                                      |
| `addChild(QTreeWidgetItem *child)`                     | 添加子项                                            |
| `child(int index)`                                     | 获取子项                                            |
| `childCount()`                                         | 获取子项数量                                        |
| `setFlags(Qt::ItemFlags flags)`                        | 设置行为属性（可选中、可编辑等）                    |
| `setData(int column, int role, const QVariant &value)` | 设置任意数据（如隐藏 ID 等）                        |
| `data(int column, int role)`                           | 获取数据                                            |

#### 示例代码

```cpp
QTreeWidget *tree = new QTreeWidget(this);
tree->setColumnCount(2);
tree->setHeaderLabels(QStringList() << "Name" << "Age");

// 添加根节点
QTreeWidgetItem *root = new QTreeWidgetItem(tree);
root->setText(0, "Parent");
root->setText(1, "50");

// 添加子节点
QTreeWidgetItem *child = new QTreeWidgetItem();
child->setText(0, "Child");
child->setText(1, "20");
root->addChild(child);

// 设置复选框
root->setCheckState(0, Qt::Unchecked);
child->setCheckState(0, Qt::Checked);

// 展开树
tree->expandAll();
```

#### 设置项行为 Flags 示例

```cpp
item->setFlags(item->flags() | Qt::ItemIsEditable | Qt::ItemIsUserCheckable);
```

#### Tips

- 不要忘记用 `setHeaderLabels()` 设置列标题。

- 可以用 `QTreeWidget::invisibleRootItem()` 操作顶级节点。

- 可以使用 `QTreeWidgetItem::setData()` 存储自定义结构或标识符。

### 迭代器和递归遍历

在使用 `QTreeWidget` / `QTreeWidgetItem` 构建树形结构时，遍历所有节点（包括子节点）是常见需求。可以通过 **递归遍历** 或使用 **迭代器（`QTreeWidgetItemIterator`）** 实现。

#### 递归遍历 QTreeWidgetItem

```cpp
void traverseRecursive(QTreeWidgetItem* item) {
    if (!item) return;

    // 示例：打印第 0 列的文本
    qDebug() << item->text(0);

    // 遍历所有子节点
    for (int i = 0; i < item->childCount(); ++i) {
        traverseRecursive(item->child(i));
    }
}

// 从顶层节点开始遍历
QTreeWidget* tree = ui->treeWidget;
for (int i = 0; i < tree->topLevelItemCount(); ++i) {
    traverseRecursive(tree->topLevelItem(i));
}
```

#### 使用 QTreeWidgetItemIterator（迭代器遍历）

```cpp
QTreeWidget* tree = ui->treeWidget;
QTreeWidgetItemIterator it(tree);
while (*it) {
    QTreeWidgetItem* item = *it;
    qDebug() << item->text(0);  // 打印第0列
    ++it;
}
```

加筛选条件（如带勾选框的项）：

```cpp
QTreeWidgetItemIterator it(tree, QTreeWidgetItemIterator::Checked);
while (*it) {
    qDebug() << (*it)->text(0);
    ++it;
}
```

支持的筛选条件（`QTreeWidgetItemIterator::IteratorFlag`）：

| 枚举值        | 说明                 |
| ------------- | -------------------- |
| `All`         | 所有项（默认）       |
| `Hidden`      | 隐藏的项             |
| `NotHidden`   | 可见项               |
| `Selected`    | 已选中项             |
| `Selectable`  | 可选中项             |
| `DragEnabled` | 可拖动项             |
| `DropEnabled` | 可接收拖放项         |
| `HasChildren` | 有子节点项           |
| `NoChildren`  | 无子节点项           |
| `Checked`     | 勾选项               |
| `NotChecked`  | 未勾选项             |
| ...           | 可按位或组合多个条件 |

#### 对比：递归 vs 迭代器

| 比较项     | 递归遍历             | 迭代器遍历             |
| ---------- | -------------------- | ---------------------- |
| 结构       | 更贴近树结构         | 更像线性遍历           |
| 控制灵活性 | 高，可随时控制层级   | 中，依赖 Qt 提供的条件 |
| 可读性     | 清晰（适合层级处理） | 简洁（适合全量过滤）   |
| 栈消耗     | 可能较高（大树）     | 较低                   |

### 示例：省市行政区

省市经纬度举例如下：

```css
安徽省 合肥市 117.250 31.833
安徽省 安庆市 117.050 30.533
广东省 广州市 113.267 23.133
广东省 深圳市 114.050 22.550
湖南省 长沙市 112.933 28.233
湖南省 株洲市 113.133 27.833
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
    <width>440</width>
    <height>330</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <layout class="QVBoxLayout" name="verticalLayout">
   <item>
    <widget class="QTreeWidget" name="treeWidget">
     <property name="columnCount">
      <number>3</number>
     </property>
     <column>
      <property name="text">
       <string>省市名称</string>
      </property>
     </column>
     <column>
      <property name="text">
       <string>经度</string>
      </property>
     </column>
     <column>
      <property name="text">
       <string>纬度</string>
      </property>
     </column>
     <item>
      <property name="text">
       <string>安徽省</string>
      </property>
      <property name="text">
       <string>117.250</string>
      </property>
      <property name="text">
       <string>31.833</string>
      </property>
      <item>
       <property name="text">
        <string>合肥市</string>
       </property>
       <property name="text">
        <string>117.250</string>
       </property>
       <property name="text">
        <string>31.833</string>
       </property>
      </item>
      <item>
       <property name="text">
        <string>安庆市</string>
       </property>
       <property name="text">
        <string>117.050</string>
       </property>
       <property name="text">
        <string>30.533</string>
       </property>
      </item>
     </item>
     <item>
      <property name="text">
       <string>广东省</string>
      </property>
      <property name="text">
       <string>113.267</string>
      </property>
      <property name="text">
       <string>23.133</string>
      </property>
      <item>
       <property name="text">
        <string>广州市</string>
       </property>
       <property name="text">
        <string>113.267</string>
       </property>
       <property name="text">
        <string>23.133</string>
       </property>
      </item>
      <item>
       <property name="text">
        <string>深圳市</string>
       </property>
       <property name="text">
        <string>114.050</string>
       </property>
       <property name="text">
        <string>22.550</string>
       </property>
      </item>
     </item>
    </widget>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout">
     <item>
      <widget class="QLabel" name="label">
       <property name="text">
        <string>省市名称</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditName"/>
     </item>
     <item>
      <widget class="QLabel" name="label_2">
       <property name="text">
        <string>经度</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditLon"/>
     </item>
     <item>
      <widget class="QLabel" name="label_3">
       <property name="text">
        <string>纬度</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditLat"/>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_2">
     <item>
      <widget class="QPushButton" name="btnAddTop">
       <property name="text">
        <string>添加顶级节点</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnAddChild">
       <property name="text">
        <string>添加子节点</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnDelLeaf">
       <property name="text">
        <string>删除叶子节点</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnDelSubtree">
       <property name="text">
        <string>删除节点子树</string>
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

#include <QTreeWidget>     //树形控件头文件
#include <QTreeWidgetItem> //条目类的头文件
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
    void on_btnAddTop_clicked();

    void on_btnAddChild_clicked();

    void on_btnDelLeaf_clicked();

    void on_btnDelSubtree_clicked();

  private:
    Ui::Widget* ui;
    void removeSubtree(QTreeWidgetItem* curLevelItem);
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
    ui->setupUi(this); // 初始化界面
}

Widget::~Widget() {
    delete ui; // 释放 UI 内存
}

// 添加顶层节点（省市）
void Widget::on_btnAddTop_clicked() {
    // 获取省市名称、经度、纬度三个文本框内容
    QString strName = ui->lineEditName->text();
    QString strLon = ui->lineEditLon->text();
    QString strLat = ui->lineEditLat->text();

    // 检查是否全部输入
    if (strName.isEmpty() || strLon.isEmpty() || strLat.isEmpty()) {
        QMessageBox::information(this, tr("输入检查"), tr("三个编辑框均需要输入信息！"));
        return;
    }

    // 创建一个新的树形节点并设置三列文本
    QTreeWidgetItem* itemNew = new QTreeWidgetItem();
    itemNew->setText(0, strName);
    itemNew->setText(1, strLon);
    itemNew->setText(2, strLat);

    // 添加到树的顶层（根节点）
    ui->treeWidget->addTopLevelItem(itemNew);
    ui->treeWidget->setFocus(); // 设置焦点，方便键盘操作
}

// 添加子节点（市县）
void Widget::on_btnAddChild_clicked() {
    // 获取当前选中的节点
    QTreeWidgetItem* curItem = ui->treeWidget->currentItem();
    if (curItem == nullptr) {
        QMessageBox::information(this, tr("无选中节点"), tr("请先选中一个节点，然后为其添加子节点！"));
        return;
    }

    // 获取输入框内容
    QString strName = ui->lineEditName->text();
    QString strLon = ui->lineEditLon->text();
    QString strLat = ui->lineEditLat->text();

    // 检查是否全部输入
    if (strName.isEmpty() || strLon.isEmpty() || strLat.isEmpty()) {
        QMessageBox::information(this, tr("输入检查"), tr("三个编辑框均需要输入信息！"));
        return;
    }

    // 创建新的子节点
    QTreeWidgetItem* itemChild = new QTreeWidgetItem();
    itemChild->setText(0, strName);
    itemChild->setText(1, strLon);
    itemChild->setText(2, strLat);

    // 添加为当前选中节点的子节点
    curItem->addChild(itemChild);
    ui->treeWidget->expandItem(curItem); // 展开当前节点以显示子项
    ui->treeWidget->setFocus();          // 设置焦点
}

// 删除选中的叶子节点（无子节点）
void Widget::on_btnDelLeaf_clicked() {
    // 获取当前选中的节点
    QTreeWidgetItem* curItem = ui->treeWidget->currentItem();
    if (curItem == nullptr) {
        QMessageBox::warning(this, tr("未选中节点"), tr("未选中节点，没东西删除。"));
        return;
    }

    // 判断是否是叶子节点（无子节点）
    if (curItem->childCount() > 0) {
        QMessageBox::warning(this, tr("不是叶子节点"), tr("不是叶子节点，不能删除！"));
        return;
    }

    // 是叶子节点，直接 delete，QTreeWidget 会自动移除显示
    delete curItem;
    curItem = nullptr;
}

// 删除选中节点及其整个子树
void Widget::on_btnDelSubtree_clicked() {
    // 获取当前选中节点
    QTreeWidgetItem* curItem = ui->treeWidget->currentItem();
    if (curItem == nullptr) {
        QMessageBox::warning(this, tr("未选中节点"), tr("未选中节点，没东西删除。"));
        return;
    }

    // 递归删除以当前节点为根的整棵子树
    removeSubtree(curItem);
}

// 递归删除子树的函数
void Widget::removeSubtree(QTreeWidgetItem* curLevelItem) {
    if (curLevelItem == nullptr) return;

    int nCount = curLevelItem->childCount(); // 获取子节点数量

    // 若没有子节点，说明是叶子节点，直接删除
    if (nCount < 1) {
        delete curLevelItem; // 删除该节点
        curLevelItem = nullptr;
        return;
    }

    // 注意：删除时不能直接用 curLevelItem->child(i)，因为删除会导致索引混乱
    while (curLevelItem->childCount() > 0) {
        QTreeWidgetItem* curChild = curLevelItem->takeChild(0); // 每次取第一个子项
        removeSubtree(curChild);                                // 递归删除该子项及其后代
    }

    // 子节点都删除完毕后，删除当前节点
    delete curLevelItem;
    curLevelItem = nullptr;
}
```

### 示例：二叉树

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
    <widget class="QTreeWidget" name="treeWidget">
     <column>
      <property name="text">
       <string notr="true">1</string>
      </property>
     </column>
    </widget>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout">
     <item>
      <widget class="QPushButton" name="btnPreorder">
       <property name="text">
        <string>先序遍历</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnPostorder">
       <property name="text">
        <string>后序遍历</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnMidorder">
       <property name="text">
        <string>中序遍历 </string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnLevelorder">
       <property name="text">
        <string>层序遍历</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnIterator">
       <property name="text">
        <string>迭代器遍历</string>
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

#include <QTreeWidget>             //树形控件
#include <QTreeWidgetItem>         //树形条目
#include <QTreeWidgetItemIterator> //树形迭代器
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
    void on_btnPreorder_clicked();

    void on_btnPostorder_clicked();

    void on_btnMidorder_clicked();

    void on_btnLevelorder_clicked();

    void on_btnIterator_clicked();

  private:
    Ui::Widget* ui;
    // 先序遍历递归函数，只打印字符，不需要返回值
    void preorderTraversal(QTreeWidgetItem* curItem);
    // 后序遍历递归函数
    void postorderTraversal(QTreeWidgetItem* curItem);
    // 中序遍历递归函数
    void midorderTraversal(QTreeWidgetItem* curItem);
    // 迭代器遍历
    void iteratorTraversal(QTreeWidgetItem* curItem);
    // 按层遍历
    void levelorderTraversal(QTreeWidgetItem* curItem);
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"

Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);

    // 设置树形控件只有 1 列
    ui->treeWidget->setColumnCount(1);

    // 创建 A 节点，并作为顶级节点加入树中
    QTreeWidgetItem* itemA = new QTreeWidgetItem();
    itemA->setText(0, "A");
    ui->treeWidget->addTopLevelItem(itemA);

    // 创建 B、C 节点并作为 A 的子节点
    QTreeWidgetItem* itemB = new QTreeWidgetItem();
    itemB->setText(0, "B");
    itemA->addChild(itemB);

    QTreeWidgetItem* itemC = new QTreeWidgetItem();
    itemC->setText(0, "C");
    itemA->addChild(itemC);

    // 创建 D、E 节点，直接将 B 作为父节点（自动建立父子关系）
    QTreeWidgetItem* itemD = new QTreeWidgetItem(itemB);
    itemD->setText(0, "D");

    QTreeWidgetItem* itemE = new QTreeWidgetItem(itemB);
    itemE->setText(0, "E");

    // 创建 F、G 节点，直接将 C 作为父节点
    QTreeWidgetItem* itemF = new QTreeWidgetItem(itemC);
    itemF->setText(0, "F");

    QTreeWidgetItem* itemG = new QTreeWidgetItem(itemC);
    itemG->setText(0, "G");

    // 展开所有子节点
    ui->treeWidget->expandAll();
}

Widget::~Widget() {
    delete ui;
}

// ------------------------ 先序遍历 ------------------------
void Widget::on_btnPreorder_clicked() {
    QTreeWidgetItem* itemA = ui->treeWidget->topLevelItem(0);
    qDebug() << tr("先序遍历：");
    preorderTraversal(itemA);
}

void Widget::preorderTraversal(QTreeWidgetItem* curItem) {
    if (!curItem) return;

    int nChildCount = curItem->childCount();
    qDebug() << curItem->text(0);

    for (int i = 0; i < nChildCount; ++i) {
        QTreeWidgetItem* child = curItem->child(i);
        preorderTraversal(child);
    }
}

// ------------------------ 后序遍历 ------------------------
void Widget::on_btnPostorder_clicked() {
    QTreeWidgetItem* itemA = ui->treeWidget->topLevelItem(0);
    qDebug() << tr("后序遍历：");
    postorderTraversal(itemA);
}

void Widget::postorderTraversal(QTreeWidgetItem* curItem) {
    if (!curItem) return;

    int nChildCount = curItem->childCount();

    for (int i = 0; i < nChildCount; ++i) {
        QTreeWidgetItem* child = curItem->child(i);
        postorderTraversal(child);
    }

    qDebug() << curItem->text(0);
}

// ------------------------ 中序遍历（非标准，适用于树形控件） ------------------------
void Widget::on_btnMidorder_clicked() {
    QTreeWidgetItem* itemA = ui->treeWidget->topLevelItem(0);
    qDebug() << tr("中序遍历：");
    midorderTraversal(itemA);
}

void Widget::midorderTraversal(QTreeWidgetItem* curItem) {
    if (!curItem) return;

    int nChildCount = curItem->childCount();
    if (nChildCount == 0) {
        qDebug() << curItem->text(0);
        return;
    }

    // 遍历第一个子节点（作为“左子树”）
    midorderTraversal(curItem->child(0));

    // 打印当前节点
    qDebug() << curItem->text(0);

    // 遍历剩下的子节点（作为“右子树”）
    for (int i = 1; i < nChildCount; ++i) {
        midorderTraversal(curItem->child(i));
    }
}

// ------------------------ 层序遍历 ------------------------
void Widget::on_btnLevelorder_clicked() {
    QTreeWidgetItem* itemA = ui->treeWidget->topLevelItem(0);
    qDebug() << tr("按层遍历：（没有回归的特性，使用队列实现）");
    levelorderTraversal(itemA);
}

void Widget::levelorderTraversal(QTreeWidgetItem* curItem) {
    if (!curItem) return;

    QList<QTreeWidgetItem*> queue;
    queue.append(curItem);

    while (!queue.isEmpty()) {
        QTreeWidgetItem* node = queue.takeFirst();
        qDebug() << node->text(0);

        int childCount = node->childCount();
        for (int i = 0; i < childCount; ++i) {
            queue.append(node->child(i));
        }
    }
}

// ------------------------ 迭代器遍历（同先序） ------------------------
void Widget::on_btnIterator_clicked() {
    QTreeWidgetItem* itemA = ui->treeWidget->topLevelItem(0);
    qDebug() << tr("迭代器遍历：（同先序）");
    iteratorTraversal(itemA);
}

void Widget::iteratorTraversal(QTreeWidgetItem* curItem) {
    if (!curItem) return;

    // 使用 QTreeWidgetItemIterator 进行先序遍历
    QTreeWidgetItemIterator it(curItem);
    while (*it) {
        qDebug() << (*it)->text(0);
        ++it; // 前进到下一个节点
    }
}
```

### 示例：树形节点读写

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
    <widget class="QTreeWidget" name="treeWidget">
     <column>
      <property name="text">
       <string notr="true">1</string>
      </property>
     </column>
    </widget>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout">
     <item>
      <widget class="QLabel" name="label">
       <property name="text">
        <string>条目文本</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditItemText"/>
     </item>
     <item>
      <widget class="QPushButton" name="btnAddTop">
       <property name="text">
        <string>添加顶级条目</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnAddChild">
       <property name="text">
        <string>添加子条目</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnEditHeader">
       <property name="text">
        <string>修改树头条目</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_2">
     <item>
      <widget class="QLabel" name="label_2">
       <property name="text">
        <string>文件路径</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditFileName"/>
     </item>
     <item>
      <widget class="QPushButton" name="btnSaveFile">
       <property name="text">
        <string>保存文件</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnClearTree">
       <property name="text">
        <string>清空树</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="btnLoadFile">
       <property name="text">
        <string>加载文件</string>
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

#include <QDataStream>     //用数据流保存树
#include <QFile>           //文件类
#include <QTreeWidget>     //树形控件
#include <QTreeWidgetItem> //树形条目
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
    void on_btnAddTop_clicked();

    void on_btnAddChild_clicked();

    void on_btnEditHeader_clicked();

    void on_btnSaveFile_clicked();

    void on_btnClearTree_clicked();

    void on_btnLoadFile_clicked();

  private:
    Ui::Widget* ui;
    // 文件对象，用于保存或打开
    QFile m_file;
    // 数据流对象
    QDataStream m_ds;
    // 保存树的先序递归函数，自顶向下保存
    void saveTree(QTreeWidgetItem* curItem);
    // 加载树的先序递归函数，自顶向下创建树形结构
    void loadFile(QTreeWidgetItem* curItem);
    // 加载时的列数限制
    static const int MAX_COLS = 1000;
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QDebug>
#include <QMessageBox>

// 构造函数，设置 UI 与初始树结构
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this); // 初始化 UI 控件

    // 设置树的列数为 1，设置树头标题
    ui->treeWidget->setColumnCount(1);
    ui->treeWidget->headerItem()->setText(0, "TreeHeader");

    // 创建顶级节点 A
    QTreeWidgetItem* itemA = new QTreeWidgetItem();
    itemA->setText(0, "A");
    // 设置节点 A 支持双击编辑
    itemA->setFlags(itemA->flags() | Qt::ItemIsEditable);
    ui->treeWidget->addTopLevelItem(itemA);

    // 创建 A 的两个子节点 B 和 C，并设置为可编辑
    QTreeWidgetItem* itemB = new QTreeWidgetItem(itemA);
    itemB->setText(0, "B");
    itemB->setFlags(itemB->flags() | Qt::ItemIsEditable);

    QTreeWidgetItem* itemC = new QTreeWidgetItem(itemA);
    itemC->setText(0, "C");
    itemC->setFlags(itemC->flags() | Qt::ItemIsEditable);

    // 展开所有节点
    ui->treeWidget->expandAll();

    // 设置默认文件名为 s.tree
    ui->lineEditFileName->setText("s.tree");
}

// 析构函数，释放 UI 内存
Widget::~Widget() {
    delete ui;
}

// 添加顶级节点按钮槽函数
void Widget::on_btnAddTop_clicked() {
    QString strText = ui->lineEditItemText->text();
    if (strText.isEmpty()) {
        QMessageBox::warning(this, tr("添加"), tr("条目文本为空不能添加。"));
        return;
    }

    // 创建顶级节点并添加到树中
    QTreeWidgetItem* itemNew = new QTreeWidgetItem();
    itemNew->setText(0, strText);
    itemNew->setFlags(itemNew->flags() | Qt::ItemIsEditable);
    ui->treeWidget->addTopLevelItem(itemNew);
    ui->treeWidget->setFocus();
}

// 添加子节点按钮槽函数
void Widget::on_btnAddChild_clicked() {
    QTreeWidgetItem* curItem = ui->treeWidget->currentItem();
    if (curItem == nullptr) {
        QMessageBox::warning(this, tr("添加子节点"), tr("未选中节点，无法添加子节点。"));
        return;
    }

    QString strText = ui->lineEditItemText->text();
    if (strText.isEmpty()) {
        QMessageBox::warning(this, tr("添加子节点"), tr("条目文本为空不能添加。"));
        return;
    }

    // 创建子节点并添加到当前选中节点
    QTreeWidgetItem* itemChild = new QTreeWidgetItem(curItem);
    itemChild->setText(0, strText);
    itemChild->setFlags(itemChild->flags() | Qt::ItemIsEditable);

    // 展开父节点
    ui->treeWidget->expandItem(curItem);
    ui->treeWidget->setFocus();
}

// 修改树头按钮槽函数
void Widget::on_btnEditHeader_clicked() {
    QString strText = ui->lineEditItemText->text();
    if (strText.isEmpty()) {
        QMessageBox::warning(this, tr("修改树头"), tr("条目文本为空，不能修改树头文本。"));
        return;
    }

    // 修改树头文本
    ui->treeWidget->headerItem()->setText(0, strText);
}

// 保存文件按钮槽函数
void Widget::on_btnSaveFile_clicked() {
    QString strFileName = ui->lineEditFileName->text().trimmed();
    if (strFileName.isEmpty()) {
        QMessageBox::warning(this, tr("保存"), tr("文件名为空，无法保存。"));
        return;
    }

    m_file.setFileName(strFileName);
    if (!m_file.open(QIODevice::WriteOnly)) {
        QMessageBox::warning(this, tr("打开"), tr("要写入的文件无法打开，请检查文件名或权限。"));
        return;
    }

    // 配置数据流绑定文件
    m_ds.setDevice(&m_file);

    // 写入树头信息
    QTreeWidgetItem* iHeader = ui->treeWidget->headerItem();
    m_ds << (*iHeader);

    // 获取隐形根条目（用于遍历所有顶级条目）
    QTreeWidgetItem* iroot = ui->treeWidget->invisibleRootItem();
    // 递归保存整棵树
    saveTree(iroot);

    QMessageBox::information(this, tr("保存完毕"), tr("保存节点到文件完毕。"));

    // 清理资源
    m_file.close();
    m_ds.setDevice(nullptr);
}

// 清空树按钮槽函数
void Widget::on_btnClearTree_clicked() {
    ui->treeWidget->clear();
    ui->treeWidget->headerItem()->setText(0, "");
}

// 加载文件按钮槽函数
void Widget::on_btnLoadFile_clicked() {
    QString strFileName = ui->lineEditFileName->text().trimmed();
    if (strFileName.isEmpty()) {
        QMessageBox::warning(this, tr("文件名"), tr("文件名为空，无法加载。"));
        return;
    }

    m_file.setFileName(strFileName);
    if (!m_file.open(QIODevice::ReadOnly)) {
        QMessageBox::warning(this, tr("打开"), tr("无法打开目标文件，请检查文件名或权限。"));
        return;
    }

    m_ds.setDevice(&m_file);

    // 清空原树
    on_btnClearTree_clicked();

    // 读取树头信息
    QTreeWidgetItem* iHeader = ui->treeWidget->headerItem();
    m_ds >> (*iHeader);
    int nColCount = iHeader->columnCount();
    qDebug() << "Header columns: " << nColCount;

    if ((nColCount < 0) || (nColCount > MAX_COLS)) {
        QMessageBox::critical(this, tr("树头加载异常"), tr("树头条目加载异常，列计数小于 0 或大于 1000。"));
        ui->treeWidget->setColumnCount(1);
        m_file.close();
        m_ds.setDevice(nullptr);
        return;
    }

    // 获取隐形根条目
    QTreeWidgetItem* iroot = ui->treeWidget->invisibleRootItem();
    // 递归加载树结构
    loadFile(iroot);

    // 判断是否加载完整
    QString strMsg = tr("加载文件中树形节点结束。");
    if (m_ds.status() != QDataStream::Ok) {
        strMsg += tr("\r\n文件读取异常，只加载了合格的部分数据。");
    }
    if (!m_ds.atEnd()) {
        int nres = m_file.size() - m_file.pos();
        strMsg += tr("\r\n文件内容未全部加载，后面数据不合格或与该树无关。\r\n剩余未读数据： %1 B").arg(nres);
    }

    QMessageBox::information(this, tr("加载文件结束"), strMsg);
    ui->treeWidget->expandAll();
    m_file.close();
    m_ds.setDevice(nullptr);
}

// 递归保存树结构（先序遍历）
void Widget::saveTree(QTreeWidgetItem* curItem) {
    if (curItem == nullptr) return;

    int nChildCount = curItem->childCount();

    // 保存当前节点和其子节点数量
    m_ds << (*curItem) << nChildCount;

    // 递归保存子节点
    for (int i = 0; i < nChildCount; i++) {
        QTreeWidgetItem* curChild = curItem->child(i);
        saveTree(curChild);
    }
}

// 递归加载树结构（先序遍历）
void Widget::loadFile(QTreeWidgetItem* parentItem) {
    if (m_ds.atEnd()) return;

    // 创建一个新节点，并读取其内容
    QTreeWidgetItem* item = new QTreeWidgetItem();
    m_ds >> (*item);

    // 加入父节点
    parentItem->addChild(item);

    // 读取当前节点的子节点数量
    int nChildCount = 0;
    m_ds >> nChildCount;

    // 递归读取所有子节点
    for (int i = 0; i < nChildCount; ++i) {
        loadFile(item);
    }
}
```