## QPixmap

QPixmap 是 Qt 中用于显示位图图像的类，适合 GUI 界面绘制。它在后台会尽可能使用硬件加速，在屏幕上显示时性能很好，但不适合频繁修改像素数据。

### 主要特点

- 只能在 GUI 线程中使用（需要 GUI 环境）
- 支持透明通道（Alpha）
- 适合快速绘制
- 不适合像素逐点修改，若需要修改请用 QImage，再转回 QPixmap
- 支持从文件、资源加载图片
- 支持缩放、转换、裁剪等操作

### 常用 API 和用法示例

#### 创建与加载

```cpp
// 1. 空的 QPixmap
QPixmap pixmapEmpty;

// 2. 指定大小的空白 QPixmap（透明背景）
QPixmap pixmapSized(200, 100);
pixmapSized.fill(Qt::transparent);  // 初始化为透明色

// 3. 从文件加载图像（支持多种格式）
QPixmap pixmapFile(":/images/logo.png");
if (pixmapFile.isNull()) {
    qDebug() << "加载失败";
}

// 4. 动态加载文件（返回 bool 判断是否成功）
QPixmap pixmapDynamic;
bool ok = pixmapDynamic.load("C:/Users/user/Pictures/sample.jpg");
if (!ok) {
    qDebug() << "加载图片失败";
}
```

#### 绘制 QPixmap 到窗口

```cpp
// 继承 QWidget 重写 paintEvent 来绘制 QPixmap
void MyWidget::paintEvent(QPaintEvent *event) {
    QPainter painter(this);
    // 绘制pixmap，起点为窗口左上角(0,0)
    painter.drawPixmap(0, 0, pixmapFile);
}
```

#### 缩放和裁剪

```cpp
// 等比缩放，保持宽高比，缩放到最大200x200像素
QPixmap scaledPixmap = pixmapFile.scaled(200, 200, Qt::KeepAspectRatio, Qt::SmoothTransformation);

// 裁剪，裁剪出左上角100x100区域
QPixmap croppedPixmap = pixmapFile.copy(0, 0, 100, 100);
```

#### 旋转和变换

```cpp
// 使用 QTransform 旋转45度
QTransform transform;
transform.rotate(45);
QPixmap rotatedPixmap = pixmapFile.transformed(transform, Qt::SmoothTransformation);
```

#### 透明度与蒙版

```cpp
// 设置蒙版（只显示蒙版覆盖部分）
QBitmap mask(":/images/mask.bmp");
pixmapFile.setMask(mask);

// 如果要实现透明度渐变，需借助 QPainter 绘制
void MyWidget::paintEvent(QPaintEvent *event) {
    QPainter painter(this);
    painter.setOpacity(0.5);  // 设置透明度50%
    painter.drawPixmap(0, 0, pixmapFile);
}
```

- “**蒙版**”（英文：**mask**）在图像处理中指的是一种**用来控制图像哪些部分显示、哪些部分隐藏的透明遮罩**，就像一张“覆盖在图像上、带有透明度信息”的图层。
- `setOpacity()` 简单适合只绘制单张图或者统一透明度。

#### 保存图片

```cpp
// 将 QPixmap 保存为 PNG 文件
bool saved = pixmapFile.save("output.png");
if (!saved) {
    qDebug() << "保存失败";
}
```

### QPixmap 与 QImage 转换

QPixmap 不支持直接访问像素，若要像素级操作，需要转换成 QImage。

```cpp
QImage image = pixmapFile.toImage();

// 修改像素（将所有像素变成红色）
for (int y = 0; y < image.height(); ++y) {
    for (int x = 0; x < image.width(); ++x) {
        image.setPixelColor(x, y, QColor(255, 0, 0));
    }
}

// 转换回 QPixmap
QPixmap modifiedPixmap = QPixmap::fromImage(image);
```

### 示例

#### 自定义 Widget 显示和操作 QPixmap

```cpp
#include <QWidget>
#include <QPainter>
#include <QPixmap>
#include <QTimer>

class PixmapWidget : public QWidget {
    Q_OBJECT
public:
    PixmapWidget(QWidget *parent = nullptr) : QWidget(parent), opacity_(1.0f) {
        pixmap_.load(":/images/logo.png");

        // 定时器用于渐变透明度动画
        timer_ = new QTimer(this);
        connect(timer_, &QTimer::timeout, this, [this]() {
            opacity_ -= 0.05;
            if (opacity_ <= 0) {
                opacity_ = 1.0;
            }
            update();  // 触发重绘
        });
        timer_->start(100);
    }

protected:
    void paintEvent(QPaintEvent *) override {
        QPainter painter(this);
        painter.setOpacity(opacity_);
        painter.drawPixmap(0, 0, pixmap_);
    }

private:
    QPixmap pixmap_;
    QTimer *timer_;
    float opacity_;
};
```

- 加载图片后，每 100ms 触发一次定时器，让图片透明度从 1.0 递减到 0，再循环。
- 重写 `paintEvent` 并用 `QPainter::setOpacity` 设置透明度，绘制 `QPixmap`。

#### 用 `QPainter::setOpacity()` 实现的两张图片交替淡入淡出

```cpp
#include <QWidget>
#include <QPainter>
#include <QPixmap>
#include <QTimer>

// 该类实现两个 QPixmap 的交替淡入淡出动画效果
class SimpleCrossFadeWidget : public QWidget {
    Q_OBJECT

public:
    // 构造函数，初始化成员变量与定时器
    explicit SimpleCrossFadeWidget(QWidget *parent = nullptr)
        : QWidget(parent),
          opacityFirst_(1.0f),     // 第一张图初始为完全不透明
          opacitySecond_(0.0f),    // 第二张图初始为完全透明
          fadingToSecond_(true)    // 初始方向为：从第一张淡出，第二张淡入
    {
        // 加载资源图片（你需要确保路径正确，比如 Qt Resource）
        pixmapFirst_.load(":/images/image1.png");
        pixmapSecond_.load(":/images/image2.png");

        // 设置控件大小为两张图中较大的尺寸，防止裁切
        int w = std::max(pixmapFirst_.width(), pixmapSecond_.width());
        int h = std::max(pixmapFirst_.height(), pixmapSecond_.height());
        setFixedSize(w, h);

        // 创建定时器控制动画更新
        timer_ = new QTimer(this);
        connect(timer_, &QTimer::timeout, this, &SimpleCrossFadeWidget::updateOpacity);
        timer_->start(50); // 每50ms更新一次，即约20帧/秒
    }

protected:
    // 绘图事件，每次控件刷新都会触发
    void paintEvent(QPaintEvent *) override {
        QPainter painter(this);

        // 开启平滑缩放渲染（抗锯齿对位图不起作用）
        painter.setRenderHint(QPainter::SmoothPixmapTransform);

        // 先绘制第一张图，设置当前透明度
        painter.setOpacity(opacityFirst_);
        painter.drawPixmap(0, 0, pixmapFirst_);

        // 再绘制第二张图，透明度与第一张互补
        painter.setOpacity(opacitySecond_);
        painter.drawPixmap(0, 0, pixmapSecond_);
    }

private slots:
    // 每隔50ms由定时器触发一次，更新透明度，推动动画前进
    void updateOpacity() {
        constexpr float delta = 0.05f; // 每帧变化量，越大动画越快

        if (fadingToSecond_) {
            // 第一张逐渐透明，第二张逐渐变得不透明
            opacityFirst_ -= delta;
            opacitySecond_ += delta;

            if (opacitySecond_ >= 1.0f) {
                // 第二张完全不透明后，切换方向（倒转）
                opacitySecond_ = 1.0f;
                opacityFirst_ = 0.0f;
                fadingToSecond_ = false;
            }
        } else {
            // 第二张逐渐透明，第一张逐渐变得不透明
            opacityFirst_ += delta;
            opacitySecond_ -= delta;

            if (opacityFirst_ >= 1.0f) {
                // 第一张完全不透明后，切换方向（倒转）
                opacityFirst_ = 1.0f;
                opacitySecond_ = 0.0f;
                fadingToSecond_ = true;
            }
        }

        // 触发窗口重绘（调用 paintEvent）
        update();
    }

private:
    QPixmap pixmapFirst_;   // 第一张图片
    QPixmap pixmapSecond_;  // 第二张图片
    float opacityFirst_;    // 第一张图片当前透明度（0.0 ~ 1.0）
    float opacitySecond_;   // 第二张图片当前透明度（0.0 ~ 1.0）
    bool fadingToSecond_;   // 当前动画方向标志
    QTimer *timer_;         // 控制动画刷新间隔的定时器
};
```

- 直接用 `painter.setOpacity()` 实现淡入淡出，适合大多数场景。

#### 用透明画布+透明度蒙版（`CompositionMode_DestinationIn`）实现的两张图片交替淡入淡出

```cpp
#include <QWidget>
#include <QPainter>
#include <QPixmap>
#include <QTimer>

// 该类实现使用透明度遮罩（alpha 渐变）方式进行两张图片的淡入淡出动画
class DetailedCrossFadeWidget : public QWidget {
    Q_OBJECT

public:
    explicit DetailedCrossFadeWidget(QWidget *parent = nullptr)
        : QWidget(parent),
          blendFactor_(0.0f),  // 初始混合因子为0，表示“from图”完全可见，“to图”完全透明
          fadingIn_(true)      // 当前状态是淡入 toPixmap_
    {
        // 加载两张图片（使用 Qt 资源系统路径）
        fromPixmap_.load(":/images/image1.png");
        toPixmap_.load(":/images/image2.png");

        // 设置控件尺寸为两张图中尺寸较大的，以防止绘制时裁剪
        int w = std::max(fromPixmap_.width(), toPixmap_.width());
        int h = std::max(fromPixmap_.height(), toPixmap_.height());
        setFixedSize(w, h);

        // 创建定时器驱动动画
        timer_ = new QTimer(this);
        connect(timer_, &QTimer::timeout, this, &DetailedCrossFadeWidget::updateBlendFactor);
        timer_->start(50);  // 每50毫秒更新一次，约20帧每秒
    }

protected:
    // 绘图事件：每次动画更新都会触发 repaint → 调用此函数
    void paintEvent(QPaintEvent *) override {
        // 图片加载失败则跳过绘制
        if (fromPixmap_.isNull() || toPixmap_.isNull())
            return;

        QPainter painter(this);
        painter.setRenderHint(QPainter::Antialiasing);  // 抗锯齿，用于平滑边缘（主要对路径有效）

        int widgetW = width();
        int widgetH = height();

        // 将图片按控件大小进行缩放，保持宽高比，防止拉伸
        QPixmap scaledFrom = fromPixmap_.scaled(widgetW, widgetH, Qt::KeepAspectRatio, Qt::SmoothTransformation);
        QPixmap scaledTo   = toPixmap_.scaled(widgetW, widgetH, Qt::KeepAspectRatio, Qt::SmoothTransformation);

        // 计算两个图片的透明度（范围0~255），从 blendFactor_ 插值得到
        int alphaFrom = static_cast<int>(255 * (1.0f - blendFactor_));  // from图逐渐变透明
        int alphaTo   = static_cast<int>(255 * blendFactor_);           // to图逐渐变不透明

        // === 构建 fromPixmap_ 的透明副本 ===
        QPixmap fromWithAlpha(scaledFrom.size());
        fromWithAlpha.fill(Qt::transparent);  // 初始化为全透明背景

        {
            QPainter p(&fromWithAlpha);

            // 使用 CompositionMode_Source 完全覆盖图像内容（包括 alpha 通道）
            p.setCompositionMode(QPainter::CompositionMode_Source);
            p.drawPixmap(0, 0, scaledFrom);

            // 使用 DestinationIn 模式，根据指定 alpha 值构建遮罩（黑色部分保留 alpha）
            p.setCompositionMode(QPainter::CompositionMode_DestinationIn);
            p.fillRect(fromWithAlpha.rect(), QColor(0, 0, 0, alphaFrom));
        }

        // === 构建 toPixmap_ 的透明副本 ===
        QPixmap toWithAlpha(scaledTo.size());
        toWithAlpha.fill(Qt::transparent);

        {
            QPainter p(&toWithAlpha);
            p.setCompositionMode(QPainter::CompositionMode_Source);
            p.drawPixmap(0, 0, scaledTo);
            p.setCompositionMode(QPainter::CompositionMode_DestinationIn);
            p.fillRect(toWithAlpha.rect(), QColor(0, 0, 0, alphaTo));
        }

        // 计算图片居中绘制位置（使其在控件中央）
        int drawXFrom = (widgetW - scaledFrom.width()) / 2;
        int drawYFrom = (widgetH - scaledFrom.height()) / 2;

        int drawXTo = (widgetW - scaledTo.width()) / 2;
        int drawYTo = (widgetH - scaledTo.height()) / 2;

        // 按照透明度合成的结果依次绘制两张图，实现平滑过渡
        painter.drawPixmap(drawXFrom, drawYFrom, fromWithAlpha);
        painter.drawPixmap(drawXTo, drawYTo, toWithAlpha);
    }

private slots:
    // 控制 blendFactor_ 在0~1之间反复变化，实现循环渐变
    void updateBlendFactor() {
        constexpr float step = 0.05f;  // 每次动画的步进值

        if (fadingIn_) {
            blendFactor_ += step;
            if (blendFactor_ >= 1.0f) {
                blendFactor_ = 1.0f;   // 达到最大混合值后反转方向
                fadingIn_ = false;
            }
        } else {
            blendFactor_ -= step;
            if (blendFactor_ <= 0.0f) {
                blendFactor_ = 0.0f;   // 达到最小混合值后反转方向
                fadingIn_ = true;
            }
        }

        update();  // 触发重绘
    }

private:
    QPixmap fromPixmap_;   // 当前正在淡出的图片
    QPixmap toPixmap_;     // 当前正在淡入的图片
    float blendFactor_;    // 混合因子（0~1），控制透明度插值
    bool fadingIn_;        // 当前是否是“淡入”状态
    QTimer *timer_;        // 控制动画时间的定时器
};
```

- 使用透明画布和透明度蒙版，粒度更细，灵活度更高。

### 注意事项

- **不要频繁创建销毁 QPixmap**，尤其是大图片，尽量复用。
- 频繁修改像素时，应用 QImage 操作后再转 QPixmap。
- QPixmap 依赖于 GUI 线程，非 GUI 线程操作可能崩溃。
- 在绘制大量动画时，使用 QPixmap 可提升性能。
- 尽量使用 `Qt::SmoothTransformation` 参数实现平滑缩放，防止锯齿。

### 小结

| 操作       | 推荐用法或建议                 |
| ---------- | ------------------------------ |
| 加载图片   | `QPixmap::load` / 构造函数     |
| 绘制图片   | 继承 QWidget 重写 `paintEvent` |
| 修改像素   | 转 QImage 修改后转回 QPixmap   |
| 缩放旋转   | `scaled` / `transformed`       |
| 透明度控制 | QPainter 中使用 `setOpacity`   |
| 蒙版遮罩   | 使用 `setMask` 或带 alpha 图像 |