## Qt 的界面绘制机制

### Qt 界面绘制的核心组成

#### 绘制相关事件与函数

| 事件 / 函数     | 作用                       | 特点/说明                             |
| --------------- | -------------------------- | ------------------------------------- |
| `resizeEvent()` | 控件尺寸变化时触发         | 可以用于更新缓存或计算布局            |
| `update()`      | 异步请求绘制，标记脏区域   | 推荐使用，效率高，自动合并多次请求    |
| `repaint()`     | 同步立即绘制（阻塞）       | 不推荐频繁使用，强制触发 `paintEvent` |
| `paintEvent()`  | 控件实际绘制逻辑入口       | 使用 `QPainter` 绘制界面内容          |
| `QPaintEvent`   | 提供脏区域（`rect()`）信息 | 可以实现**局部绘制优化**              |

#### Qt 的绘制流程（事件驱动）

```css
用户或系统触发变化（如窗口大小改变）
        ↓
调用 resizeEvent()
        ↓（程序中手动调用）
      update()
        ↓（Qt 事件循环空闲时）
  自动触发 paintEvent()
        ↓
   使用 QPainter 绘制内容
```

### 示例：动态圆随窗口大小变化

```cpp
#include <QApplication>
#include <QWidget>
#include <QPainter>
#include <QResizeEvent>

class MyWidget : public QWidget {
public:
    MyWidget(QWidget *parent = nullptr) : QWidget(parent) {
        setMinimumSize(200, 200);
    }

protected:
    // [1] 尺寸变化时触发
    void resizeEvent(QResizeEvent *event) override {
        // 保存新的窗口大小
        windowSize = event->size();

        // 请求 Qt 重绘（异步）
        update();

        // 始终调用基类实现
        QWidget::resizeEvent(event);
    }

    // [2] 真正绘制发生在 paintEvent 中
    void paintEvent(QPaintEvent *event) override {
        QPainter painter(this);

        // 填充背景
        painter.fillRect(event->rect(), Qt::white);

        // 设置画笔和画刷
        painter.setPen(Qt::black);
        painter.setBrush(Qt::blue);

        // 计算一个随窗口宽度变化的圆
        int r = windowSize.width() / 4;
        QPoint center = rect().center();

        // 绘制圆
        painter.drawEllipse(center, r, r);
    }

private:
    QSize windowSize;
};

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    MyWidget w;
    w.setWindowTitle("Qt 绘制示例：随窗口变化的圆");
    w.show();

    return app.exec();
}
```

#### `resizeEvent(QResizeEvent*)`

- 当窗口尺寸发生变化时，**Qt 自动调用此函数**。
- 可以在里面调整布局、控件位置、缓存大小等。
- **如果需要重绘，必须手动调用 `update()`**！

#### `update()`

- 不立刻重绘，而是告诉 Qt：“我需要绘制！”
- Qt 会在 **事件循环空闲时** 批量处理这些请求。
- 减少频繁绘图带来的卡顿，**支持绘图请求合并（脏区域合并）**。

#### `paintEvent(QPaintEvent*)`

- **唯一绘图入口**。系统或 `update()` 触发时调用。
- 使用 `QPainter` 在控件上绘图（必须在 paintEvent 中创建）。
- `QPaintEvent::rect()` 可以知道当前需要绘制的区域。

### 示例：画板

#### 相关核心类

##### QPainter — 绘图引擎

Qt 中最主要的绘图类，负责在控件、图像、打印机等设备上绘制图形和文本。用于画线、画形状（矩形、圆、椭圆等）、绘制文字、绘制图片、设置画笔和画刷样式等。

关键方法：

- `begin(QWidget*)` / `end()` — 开始和结束绘制（通常不直接调用，用 `QPainter painter(this);` RAII 管理）
- `drawLine(QPoint p1, QPoint p2)` — 画线
- `drawEllipse(QPoint center, int rx, int ry)` — 画椭圆（圆）
- `drawRect(QRect rect)` — 画矩形
- `drawText(QPoint, QString)` — 画文本
- `setPen(QPen)` — 设置画笔（线条颜色、宽度、风格）
- `setBrush(QBrush)` — 设置画刷（填充颜色、渐变、图案）

简单示例：

```cpp
QPainter painter(this);
painter.setPen(Qt::red);
painter.setBrush(Qt::blue);
painter.drawEllipse(QPoint(50, 50), 20, 20);  // 画一个蓝色填充、红色边框的圆
```

##### QPoint — 二维点坐标

表示二维空间中的一个点，封装了 `x` 和 `y` 坐标。用来指定绘制的位置，记录鼠标位置等。

常用接口：

- 构造：`QPoint(int x, int y)`
- 访问坐标：`x()`, `y()`
- 操作符重载：`+`, `-` 等方便点的计算
- 与 `QPointF`（浮点点）相似，但精度为整数

示例：

```cpp
QPoint pt(10, 20);
int x = pt.x();
int y = pt.y();
```

##### QColor — 颜色类

封装颜色信息，支持 RGB、ARGB、HSV、CMYK 等多种颜色空间。用于设置画笔和画刷颜色，处理颜色变化。

常用构造：

- `QColor(Qt::red)` 预定义颜色
- `QColor(int r, int g, int b, int a=255)` 自定义RGBA颜色
- `QColor::fromHsv()`, `QColor::fromRgb()`

常用方法：

- `red()`, `green()`, `blue()`, `alpha()` 获取分量
- `setRed()`, `setAlpha()` 设置分量
- `name()` 返回颜色的字符串表示（如 `#RRGGBB`）

示例：

```cpp
QColor color(255, 0, 0); // 红色
color.setAlpha(128);     // 半透明
```

##### QPixmap — 优化的图片表示

专门用于屏幕显示的位图（图片）类，底层经常调用硬件加速，性能优于 `QImage` 用于绘图和显示。用于加载图片文件，绘制图像，做双缓冲绘图等。

关键方法：

- 加载：`QPixmap::load("file.png")`
- 保存：`QPixmap::save("out.png")`
- 绘制：配合 `QPainter::drawPixmap()`
- 缩放：`scaled()`

与 `QImage` 的区别：

- `QPixmap` 适合显示（GUI 渲染），
- `QImage` 适合图像处理（像素操作）

示例：

```cpp
QPixmap pixmap;
pixmap.load(":/images/logo.png");

QPainter painter(this);
painter.drawPixmap(0, 0, pixmap);
```

##### QMouseEvent — 鼠标事件

封装鼠标事件信息，如点击、移动、释放等事件数据。响应鼠标输入，获取鼠标位置、按键信息，做交互逻辑。

常用方法：

- `pos()` — 返回事件发生时鼠标相对控件的位置（QPoint）
- `globalPos()` — 鼠标相对于屏幕的坐标
- `button()` — 哪个鼠标键触发（左键、右键、中键）
- `buttons()` — 当前所有按下的鼠标键（支持多键同时按）
- `type()` — 事件类型（按下、移动、释放等）

常用事件：

- `mousePressEvent(QMouseEvent *event)`
- `mouseMoveEvent(QMouseEvent *event)`
- `mouseReleaseEvent(QMouseEvent *event)`

示例：

```cpp
void MyWidget::mousePressEvent(QMouseEvent *event) {
    if (event->button() == Qt::LeftButton) {
        QPoint pos = event->pos();
        // 处理点击事件
    }
}
```

#### drawingarea.h

```cpp
#pragma once

#include <QColor>
#include <QPoint>
#include <QVector>
#include <QWidget>

// 绘图区域控件类，继承自 QWidget，实现基本的鼠标绘图功能
class DrawingArea : public QWidget {
    Q_OBJECT

public:
    explicit DrawingArea(QWidget *parent = nullptr);

    // 清空所有绘制的点和数据，刷新界面
    void clearPoints();
    // 设置画笔颜色，会自动关闭橡皮擦模式
    void setPenColor(const QColor &color);
    // 设置画笔大小（圆点半径）
    void setPenSize(int size);
    // 切换橡皮擦模式，开启时笔色为白色（背景色），关闭时恢复上一次画笔颜色
    void toggleEraserMode();
    // 保存当前绘图区域为图片文件，支持png等格式
    void saveToImage(const QString &filePath);

protected:
    // 鼠标按下事件，开始绘图（仅响应左键）
    void mousePressEvent(QMouseEvent *event) override;
    // 鼠标移动事件，按住左键时持续绘图
    void mouseMoveEvent(QMouseEvent *event) override;
    // 鼠标释放事件，结束绘图
    void mouseReleaseEvent(QMouseEvent *event) override;
    // 绘图事件，所有绘制操作都在此完成
    void paintEvent(QPaintEvent *event) override;

private:
    // 当前是否处于绘图状态（鼠标左键按下未释放）
    bool drawing;
    // 存储所有绘制的点坐标
    QVector<QPoint> points;
    // 存储每个点对应的颜色（支持多颜色绘制）
    QVector<QColor> colors;
    // 存储每个点对应的大小（笔粗）
    QVector<int> sizes;
    // 当前画笔颜色（若开启橡皮擦模式，此颜色会被覆盖为白色）
    QColor penColor;
    // 当前画笔大小（圆点半径）
    int penSize;
    // 是否处于橡皮擦模式（开启时用白色绘制）
    bool eraseMode;
    // 记录最后一次用户设置的画笔颜色，用于从橡皮擦切换回时恢复
    QColor lastPenColor;

    // 添加一个绘制点，包含坐标、颜色和大小，完成后请求重绘
    void addPoint(const QPoint &pt);
};
```

#### drawingarea.cpp

```cpp
#include "drawingarea.h"
#include <QMouseEvent>
#include <QPainter>
#include <QPixmap>

DrawingArea::DrawingArea(QWidget *parent)
    : QWidget(parent), drawing(false), // 初始不绘图
      penColor(Qt::red),               // 默认画笔颜色红色
      penSize(5),                      // 默认笔粗为5
      eraseMode(false) {               // 默认不开启橡皮擦
    setMouseTracking(true); // 开启鼠标追踪，即使无按键移动也能响应mouseMoveEvent
}

// 清空所有绘制数据，重绘界面为空白
void DrawingArea::clearPoints() {
    points.clear(); // 清除所有点坐标
    colors.clear(); // 清除对应颜色数据
    sizes.clear();  // 清除对应大小数据
    update();       // 请求重绘，刷新界面
}

// 设置画笔颜色，同时关闭橡皮擦模式，记录颜色用于恢复
void DrawingArea::setPenColor(const QColor &color) {
    lastPenColor = color; // 记录用户设置的颜色
    penColor = color;     // 当前画笔颜色设为该颜色
    eraseMode = false;    // 关闭橡皮擦模式
}

// 设置画笔大小（圆点半径）
void DrawingArea::setPenSize(int size) { penSize = size; }

// 切换橡皮擦模式，开启时画笔颜色为白色（背景色），关闭时恢复用户上次颜色
void DrawingArea::toggleEraserMode() {
    eraseMode = !eraseMode; // 状态取反切换
    if (eraseMode) {
        penColor = Qt::white; // 橡皮擦模式画白色
    } else {
        penColor = lastPenColor; // 恢复上次画笔颜色
    }
    update(); // 刷新界面，颜色改变可能会有视觉提示
}

// 保存绘图区为图片文件（png等格式）
void DrawingArea::saveToImage(const QString &filePath) {
    QPixmap pixmap(size()); // 创建与控件同尺寸的画布
    render(&pixmap);        // 把当前控件内容渲染到 pixmap
    pixmap.save(filePath);  // 保存到指定文件
}

// 鼠标左键按下事件，开启绘图状态，添加第一个点
void DrawingArea::mousePressEvent(QMouseEvent *event) {
    if (event->button() == Qt::LeftButton) {
        drawing = true;         // 标记绘图开始
        addPoint(event->pos()); // 添加当前点
    }
}

// 鼠标移动事件，若处于绘图状态，持续添加点
void DrawingArea::mouseMoveEvent(QMouseEvent *event) {
    if (drawing) {
        addPoint(event->pos()); // 添加当前点
    }
}

// 鼠标左键释放事件，结束绘图状态
void DrawingArea::mouseReleaseEvent(QMouseEvent *event) {
    if (event->button() == Qt::LeftButton) {
        drawing = false; // 标记绘图结束
    }
}

// 绘图事件，绘制所有记录的点（圆形），使用对应颜色和大小
void DrawingArea::paintEvent(QPaintEvent *event) {
    QPainter painter(this);
    painter.fillRect(event->rect(), Qt::white); // 清空区域，填充背景色白色

    for (int i = 0; i < points.size(); ++i) {
        painter.setBrush(colors[i]);                        // 设置画刷颜色
        painter.setPen(Qt::NoPen);                          // 无边框
        painter.drawEllipse(points[i], sizes[i], sizes[i]); // 画圆点
    }
}

// 添加绘制点（坐标、颜色、大小），添加后请求重绘
void DrawingArea::addPoint(const QPoint &pt) {
    points.append(pt); // 记录点坐标
    colors.append(eraseMode
                      ? Qt::white
                      : penColor); // 当前模式决定颜色（橡皮擦白色，正常画笔色）
    sizes.append(penSize);         // 当前画笔大小
    update();                      // 请求刷新界面，触发paintEvent
}
```

#### widget.h

```cpp
#pragma once

#include <QWidget>

class DrawingArea;

class Widget : public QWidget {
    Q_OBJECT

public:
    explicit Widget(QWidget *parent = nullptr);

private:
    DrawingArea *drawingArea;
};
```

#### widget.cpp

```cpp
#include "widget.h"
#include "drawingarea.h"

#include <QColorDialog>
#include <QFileDialog>
#include <QHBoxLayout>
#include <QLabel>
#include <QPushButton>
#include <QSlider>
#include <QVBoxLayout>

Widget::Widget(QWidget *parent) : QWidget(parent) {
    // 创建主垂直布局，作为整个窗口的布局容器
    auto *mainLayout = new QVBoxLayout(this);

    // 创建绘图区域控件实例，设置最小高度
    drawingArea = new DrawingArea(this);
    drawingArea->setMinimumHeight(400);

    // 创建水平布局，用于放置按钮和控件
    auto *buttonLayout = new QHBoxLayout();

    // 创建几个功能按钮
    auto *clearBtn = new QPushButton("清除画布", this);
    auto *colorBtn = new QPushButton("选择颜色", this);
    auto *eraserBtn = new QPushButton("橡皮擦 ❌", this);
    auto *saveBtn = new QPushButton("保存图片", this);

    // 创建画笔粗细滑动条，水平滑动，范围1-30，默认值5
    auto *slider = new QSlider(Qt::Horizontal);
    slider->setRange(1, 30);
    slider->setValue(5);

    // 显示当前笔粗的标签
    auto *sliderLabel = new QLabel("笔粗: 5", this);

    // 将按钮和控件添加到水平布局中
    buttonLayout->addWidget(clearBtn);
    buttonLayout->addWidget(colorBtn);
    buttonLayout->addWidget(eraserBtn);
    buttonLayout->addWidget(saveBtn);
    buttonLayout->addWidget(sliderLabel);
    buttonLayout->addWidget(slider);

    // 主布局依次添加绘图区域和按钮布局
    mainLayout->addWidget(drawingArea);
    mainLayout->addLayout(buttonLayout);

    // 连接“清除画布”按钮点击信号，调用绘图区的 clearPoints() 清空画布
    connect(clearBtn, &QPushButton::clicked, drawingArea,
            &DrawingArea::clearPoints);

    // 连接“选择颜色”按钮，弹出颜色选择对话框，设置画笔颜色
    connect(colorBtn, &QPushButton::clicked, this, [=]() {
        QColor color = QColorDialog::getColor(Qt::red, this, "选择画笔颜色");
        if (color.isValid()) {
            drawingArea->setPenColor(color);
        }
    });

    // 连接“橡皮擦”按钮，点击时切换橡皮擦模式，并更新按钮文字状态
    connect(eraserBtn, &QPushButton::clicked, this, [=]() {
        drawingArea->toggleEraserMode();

        // 静态变量记录当前是否处于橡皮擦状态，用于切换按钮文字
        static bool erasing = false;
        erasing = !erasing;
        eraserBtn->setText(erasing ? "橡皮擦 ✅" : "橡皮擦 ❌");
    });

    // 连接“保存图片”按钮，弹出文件保存对话框，保存绘图内容为PNG图片
    connect(saveBtn, &QPushButton::clicked, this, [=]() {
        QString file =
            QFileDialog::getSaveFileName(this, "保存图片", "", "PNG 图片 (*.png)");
        if (!file.isEmpty()) {
            drawingArea->saveToImage(file);
        }
    });

    // 连接滑动条值改变信号，更新标签显示当前笔粗，同时设置绘图区域画笔大小
    connect(slider, &QSlider::valueChanged, this, [=](int value) {
        sliderLabel->setText(QString("笔粗: %1").arg(value));
        drawingArea->setPenSize(value);
    });
}
```

#### main.cpp

```cpp
#include "widget.h"

#include <QApplication>

int main(int argc, char *argv[]) {
    QApplication a(argc, argv);
    Widget w;
    w.setWindowTitle("Qt 简易绘图板");
    w.resize(800, 600);
    w.show();
    return a.exec();
}
```

