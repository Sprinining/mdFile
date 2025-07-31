## 用 QStyledItemDelegate 自定义 QListView Item 外观

Qt 提供的 `QListView` 默认只支持文本/图标列表，而现实中我们经常需要显示更复杂的内容，比如一行里显示多个“基因标签”、“操作按钮”或其他控件。

技术核心：

- 使用 `QAbstractListModel` 管理种子数据，实现列表数据模型与视图解耦；
- 使用 `QStyledItemDelegate` 自定义种子项的显示样式，每个种子展示 6 个圆形代表其基因；
- 使用 `QListView` 作为显示组件，支持右键删除、动态添加；
- 基因组合逻辑封装于 `GeneCalculator` 类，通过信号槽触发计算并输出结果；
- 计算结果显示于 `QTextBrowser`，包含：四个父代种子基因与生成的最佳后代。

### 项目结构

```txt
/gene_editor_demo/
├── genelistpanel.h / .cpp    // 主控件，管理列表和按钮
├── seedmodel.h / .cpp        // 数据模型，继承 QAbstractListModel
├── seeddelegate.h / .cpp     // 自定义渲染每个种子的 Delegate
├── seed.h / .cpp             // Seed 类型定义（基因组合）
├── genecalculator.h / .cpp   // 计算逻辑
```

### Seed 数据结构定义

```cpp
// seed.h
enum class GeneType { G, Y, H, X, W, Unknown };

struct Seed {
    std::array<GeneType, 6> genes_;
};
```

### SeedModel：继承 QAbstractListModel

```cpp
// seedmodel.h

#pragma once

#include <QAbstractListModel>
#include <QVector>
#include "seed.h"  // 假设这里定义了 Seed 类型和 GeneType 枚举

// SeedModel 是一个基于 QAbstractListModel 的模型类，
// 用于管理“种子”对象（Seed）的列表，供 QListView 使用。
class SeedModel : public QAbstractListModel {
    Q_OBJECT

public:
    // 构造函数，允许设置父对象，默认为 nullptr。
    explicit SeedModel(QObject* parent = nullptr);

    // 返回当前种子列表的条目数量，用于视图绘制。
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;

    // 返回指定 index 的数据，用于视图展示。
    // 自定义的 role（如 Qt::UserRole）用于传递 Seed 对象。
    QVariant data(const QModelIndex& index, int role) const override;

    // 添加一个新的种子到模型中。
    void appendSeed(const Seed& seed);

    // 移除指定行的种子对象。
    void removeSeed(int row);

    // 获取指定行的种子对象。
    Seed getSeed(int row) const;

private:
    // 存储所有种子数据的容器。
    QVector<Seed> seeds_;
};
```

```cpp
// seedmodel.cpp
int SeedModel::rowCount(const QModelIndex&) const {
    return seeds_.size();
}

QVariant SeedModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || role != Qt::UserRole) return {};
    return QVariant::fromValue(seeds_.at(index.row())); // Seed 需注册为 Qt 元类型
}
```

### SeedDelegate：自定义显示每个 Item

```cpp
// seeddelegate.h
#pragma once

#include <QStyledItemDelegate>
#include <QPainter>
#include "seed.h"  // 假设这个头文件中包含了 Seed 类型和 GeneType 枚举

// SeedDelegate 用于自定义 QListView 中每个种子条目的绘制方式。
// 每个条目会显示 6 个圆形颜色块，对应一个 Seed 的六个基因位。
class SeedDelegate : public QStyledItemDelegate {
    Q_OBJECT

public:
    // 构造函数，允许传入父对象。
    explicit SeedDelegate(QObject* parent = nullptr);

    // 重写 paint 函数来自定义绘制每个 item 的内容。
    void paint(QPainter* painter, const QStyleOptionViewItem& option,
               const QModelIndex& index) const override;

    // 返回每个条目的大小（用于视图排布）。
    QSize sizeHint(const QStyleOptionViewItem& option,
                   const QModelIndex& index) const override;

private:
    // 帮助函数：根据 GeneType 返回对应的颜色。
    QColor geneTypeToColor(AppConsts::GeneType type) const;
};
```

```cpp
// seeddelegate.cpp
void SeedDelegate::paint(QPainter* painter, const QStyleOptionViewItem& option,
                         const QModelIndex& index) const {
    Seed seed = index.data(Qt::UserRole).value<Seed>();
    painter->save();

    QRect rect = option.rect;
    int circleSize = 20;
    int spacing = 8;

    for (int i = 0; i < 6; ++i) {
        QColor color = geneTypeToColor(seed.genes_[i]);
        QRect circle(rect.left() + i * (circleSize + spacing), rect.top() + 10, circleSize, circleSize);
        painter->setBrush(color);
        painter->drawEllipse(circle);
    }

    painter->restore();
}

QSize SeedDelegate::sizeHint(const QStyleOptionViewItem&, const QModelIndex&) const {
    return QSize(160, 40);
}
```

### GeneListPanel：连接 View + Model + Delegate + 操作逻辑

```cpp
// genelistpanel.cpp
// 创建种子模型，管理所有 Seed 数据
model_ = new SeedModel(this);

// 创建委托，用于自定义 QListView 中每个 Seed 的绘制（6 个彩色圆点）
delegate_ = new SeedDelegate(this);

// 设置模型：数据来源是 model_
ui->listView->setModel(model_);

// 设置委托：绘制方式交由 delegate_ 实现
ui->listView->setItemDelegate(delegate_);

// 设置右键菜单触发策略：使用自定义方式（即 customContextMenuRequested 信号）
ui->listView->setContextMenuPolicy(Qt::CustomContextMenu);

// 连接右键菜单信号到槽函数 onListViewContextMenu，
// 当用户在列表中右键点击时，弹出菜单处理删除等操作
connect(ui->listView, &QListView::customContextMenuRequested,
        this, &GeneListPanel::onListViewContextMenu);

// 连接“计算”按钮点击信号到槽函数 onCalculateRequested，
// 用户点击后会收集所有种子，传入 GeneCalculator 进行计算
connect(ui->calcButton, &QPushButton::clicked,
        this, &GeneListPanel::onCalculateRequested);
```

### 右键删除功能

```cpp
void GeneListPanel::onListViewContextMenu(const QPoint &pos) {
    QModelIndex index = ui->listView->indexAt(pos);
    if (!index.isValid()) return;

    QMenu menu(this);
    QAction* delAction = menu.addAction("删除");
    if (menu.exec(ui->listView->viewport()->mapToGlobal(pos)) == delAction) {
        model_->removeSeed(index.row());
    }
}
```

### 种子配种计算功能 + QTextBrowser 显示结果

```cpp
void GeneListPanel::onCalculateRequested() {
    if (model_->rowCount() < 4) {
        QMessageBox::warning(this, "错误", "至少需要 4 个种子用于计算");
        return;
    }

    GeneCalculator calculator;
    for (int i = 0; i < model_->rowCount(); ++i)
        calculator.addSeed(model_->getSeed(i));

    calculator.calculate();
    QString result;

    const auto& parents = calculator.getBreedingSeeds();
    for (int i = 0; i < parents.size(); ++i) {
        result += QString("Parent %1 genes: ").arg(i + 1);
        for (auto g : parents[i]->genes_)
            result += geneTypeToChar(g) + QString(" ");
        result += "\n";
    }

    result += "Best offspring seed genes: ";
    for (auto g : calculator.getOffspringSeed().genes_)
        result += geneTypeToChar(g) + QString(" ");
    result += "\n";

    ui->textBrowser->setText(result);
}
```

### 注册 Seed 为 Qt 元类型

```cpp
Q_DECLARE_METATYPE(Seed)
```

在 `main.cpp` 或程序入口前加：

```cpp
qRegisterMetaType<Seed>("Seed");
```

