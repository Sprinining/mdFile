## Qt_ui_headerlabel被覆盖问题总结

### **ProTreeWidget 类定义与实现**（自定义 QTreeWidget）

#### protreewidget.h

```cpp
#ifndef PROTREEWIDGET_H
#define PROTREEWIDGET_H

#include <QTreeWidget>

class ProTreeWidget : public QTreeWidget {
    Q_OBJECT
public:
    ProTreeWidget(QWidget* parent = nullptr);
};

#endif // PROTREEWIDGET_H
```

#### protreewidget.cpp

```cpp
#include "protreewidget.h"
#include <QDebug>

ProTreeWidget::ProTreeWidget(QWidget* parent) : QTreeWidget(parent) {
    setHeaderLabels(QStringList() << "项目名称222" << "路径");
    qDebug() << "ProTreeWidget 构造函数";
}
```

### ProTreeDialog 类实现

#### protreedialog.cpp

```cpp
#include "protreedialog.h"
#include "ui_protreedialog.h"
#include <QDebug>

ProTreeDialog::ProTreeDialog(QWidget* parent) : QDialog(parent), ui(new Ui::ProTreeDialog) {
    ui->setupUi(this); // setupUi 之后 header 会被覆盖
    // 正确做法：在这里设置 headerLabels 才不会被 UI 覆盖
    ui->treeWidget->setHeaderLabels(QStringList() << "项目名称" << "路径");
    qDebug() << "ProTreeDialog 构造函数";
}

ProTreeDialog::~ProTreeDialog() {
    delete ui;
}
```

### UI 自动生成代码片段（ui_protreedialog.h）

这是 Qt Designer 生成的 UI 代码中关键的一段：

```cpp
treeWidget = new ProTreeWidget(ProTreeDialog);

// Qt Designer 默认设置了一列名为“1”
QTreeWidgetItem *__qtreewidgetitem = new QTreeWidgetItem();
__qtreewidgetitem->setText(0, QString::fromUtf8("1"));
treeWidget->setHeaderItem(__qtreewidgetitem);  // 这里会覆盖 headerLabels
```

- `ProTreeWidget` 构造函数中设置的 `setHeaderLabels(...)`，**会在 setupUi() 调用时被覆盖**；

- 覆盖行为来自 `.ui` 文件生成的代码中的 `setHeaderItem(...)`；

- **正确设置 header 的时机是在 `setupUi()` 之后**，例如在 `ProTreeDialog` 构造函数末尾。

### 解决方法

#### 方法一

**不要在构造函数中 setHeaderLabels**，改成在 `ProTreeDialog` 构造函数末尾设置**

```cpp
ProTreeDialog::ProTreeDialog(QWidget* parent) : QDialog(parent), ui(new Ui::ProTreeDialog) {
    ui->setupUi(this);  // setupUi 之后才可以覆盖
    ui->treeWidget->setHeaderLabels(QStringList() << "项目名称" << "路径");  // 推荐写在这里
}
```

#### 方法二

**修改 `.ui` 文件中的 TreeWidget**

1. 打开 `protreedialog.ui`。
2. 选中 `treeWidget` 控件。
3. 设置列数为 2。
4. 设置列名为：项目名称、路径。
5. 保存、重新构建，生成的 `ui_protreedialog.h` 代码就会是：

```cpp
QTreeWidgetItem *__qtreewidgetitem = new QTreeWidgetItem();
__qtreewidgetitem->setText(0, QString::fromUtf8("项目名称"));
__qtreewidgetitem->setText(1, QString::fromUtf8("路径"));
treeWidget->setHeaderItem(__qtreewidgetitem);
```

### 为什么 Qt Designer 会生成 setHeaderItem

Qt Designer 并不知道 `ProTreeWidget` 的构造函数里面写了什么。它会默认给 `QTreeWidget` 添加一列 `"1"` 作为 placeholder header，这是 Qt Designer 的默认行为。