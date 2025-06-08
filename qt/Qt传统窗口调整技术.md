## Qt 传统窗口调整技术

### `QWidget` 中与控件/窗口大小相关

#### 大小设置相关函数

| 函数名                                                       | 参数           | 作用                                                  | 是否允许用户调整大小 |
| ------------------------------------------------------------ | -------------- | ----------------------------------------------------- | -------------------- |
| `setFixedSize(int w, int h)` / `setFixedSize(const QSize &)` | 宽度、高度     | 设置固定大小                                          | ❌ 不允许             |
| `resize(int w, int h)` / `resize(const QSize &)`             | 宽度、高度     | 设置当前大小                                          | ✅ 允许               |
| `setMinimumSize(int w, int h)` / `setMinimumSize(const QSize &)` | 最小宽度、高度 | 设置最小尺寸限制                                      | ✅ 允许               |
| `setMaximumSize(int w, int h)` / `setMaximumSize(const QSize &)` | 最大宽度、高度 | 设置最大尺寸限制                                      | ✅ 允许               |
| `setGeometry(int x, int y, int w, int h)`                    | 坐标和宽高     | 设置位置和大小                                        | ✅ 允许               |
| **`adjustSize()`**                                           | 无             | 根据内容自动调整控件大小（调用 `resize(sizeHint())`） | ✅ 允许               |

#### 大小获取函数

| 函数名                            | 返回值类型 | 作用                            |
| --------------------------------- | ---------- | ------------------------------- |
| `size()`                          | `QSize`    | 获取当前控件大小                |
| `width()` / `height()`            | `int`      | 获取当前宽度或高度              |
| `minimumSize()` / `maximumSize()` | `QSize`    | 获取最小/最大尺寸               |
| `geometry()`                      | `QRect`    | 获取控件的矩形区域（位置+尺寸） |

#### 推荐尺寸（用于布局管理器）

| 函数名              | 返回值类型 | 作用               | 备注                   |
| ------------------- | ---------- | ------------------ | ---------------------- |
| `sizeHint()`        | `QSize`    | 返回推荐的大小     | 可重写                 |
| `minimumSizeHint()` | `QSize`    | 返回推荐的最小大小 | 默认为 `(0,0)`，可重写 |

### 手动计算调整控件分布

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
    <width>472</width>
    <height>473</height>
   </rect>
  </property>
  <property name="minimumSize">
   <size>
    <width>0</width>
    <height>0</height>
   </size>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <widget class="QSlider" name="horizontalSlider">
   <property name="geometry">
    <rect>
     <x>160</x>
     <y>420</y>
     <width>231</width>
     <height>21</height>
    </rect>
   </property>
   <property name="orientation">
    <enum>Qt::Orientation::Horizontal</enum>
   </property>
  </widget>
  <widget class="QLabel" name="labelShow">
   <property name="geometry">
    <rect>
     <x>40</x>
     <y>10</y>
     <width>400</width>
     <height>300</height>
    </rect>
   </property>
   <property name="text">
    <string/>
   </property>
  </widget>
  <widget class="QPushButton" name="btnOpenPic">
   <property name="geometry">
    <rect>
     <x>10</x>
     <y>380</y>
     <width>75</width>
     <height>23</height>
    </rect>
   </property>
   <property name="text">
    <string>打开图片</string>
   </property>
  </widget>
  <widget class="QPushButton" name="btnOpenMov">
   <property name="geometry">
    <rect>
     <x>80</x>
     <y>380</y>
     <width>102</width>
     <height>23</height>
    </rect>
   </property>
   <property name="text">
    <string>打开动态图</string>
   </property>
  </widget>
  <widget class="QPushButton" name="btnStart">
   <property name="geometry">
    <rect>
     <x>200</x>
     <y>380</y>
     <width>91</width>
     <height>23</height>
    </rect>
   </property>
   <property name="text">
    <string>播放</string>
   </property>
  </widget>
  <widget class="QPushButton" name="btnStop">
   <property name="geometry">
    <rect>
     <x>330</x>
     <y>380</y>
     <width>91</width>
     <height>23</height>
    </rect>
   </property>
   <property name="text">
    <string>停止</string>
   </property>
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

#include <QImageReader> // 用于读取图像（错误类型也在此）
#include <QMovie>       // 用于播放动态图（如 GIF）
#include <QPixmap>      // 用于显示静态图像
#include <QWidget>

QT_BEGIN_NAMESPACE
namespace Ui {
class Widget;
}
QT_END_NAMESPACE

class Widget : public QWidget {
    Q_OBJECT

public:
    explicit Widget(QWidget* parent = nullptr);
    ~Widget();

public slots:
    // 动图播放错误的槽函数，连接 QMovie::error 信号
    void recvPlayError(QImageReader::ImageReaderError error);

    // 帧变化的槽函数，用于更新进度条，连接 QMovie::frameChanged 信号
    void recvFrameNumber(int frameNumber);

private slots:
    // UI 按钮点击的槽函数（自动连接）
    void on_btnOpenPic_clicked(); // 打开静态图按钮
    void on_btnOpenMov_clicked(); // 打开动态图按钮
    void on_btnStart_clicked();   // 播放按钮
    void on_btnStop_clicked();    // 停止按钮

private:
    Ui::Widget* ui; // 指向 UI 界面类的指针，自动生成并管理所有控件

    // 用于显示静态图的指针（建议用智能指针管理）
    QPixmap* pixmap = nullptr;

    // 用于播放动态图的指针（如 gif/mng）
    QMovie* movie = nullptr;

    // 标志位：当前是否为动态图（true 表示是 QMovie）
    bool isMovie = false;

    // 标志位：动态图是否正在播放
    bool isPlaying = false;

    // 清除上一个图像或动画的辅助函数，释放资源并重置状态
    void clearOldShow();

    // QWidget interface
protected:
    void resizeEvent(QResizeEvent* event) override;
};

#endif // WIDGET_H
```

- `virtual void resizeEvent(QResizeEvent* event);` 是 `QWidget` 中的一个**虚函数**，用于处理 **窗口或控件大小变化时的事件**。

- 该事件对象提供了控件**新旧尺寸**的信息：

| 函数               | 作用                   |
| ------------------ | ---------------------- |
| `event->size()`    | 返回新的大小 (`QSize`) |
| `event->oldSize()` | 返回旧的大小 (`QSize`) |

-  注意事项

  - 重写时不要忘记调用 `QWidget::resizeEvent(event);`，除非你**完全取代默认行为**。

  - 如果控件用布局管理器（如 `QVBoxLayout`、`QGridLayout`），一般不需要手动处理大小变化。

- 从 **C++11** 开始，加入 `override` 有个好处：如果写错函数签名、参数、拼写等，**没有 `override` 就不会报错**，导致函数不会被调用。

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QDebug>
#include <QFileDialog>
#include <QMessageBox>
#include <QResizeEvent>
#include <QScrollArea>

// 构造函数：初始化 UI 并用 QScrollArea 包装 label 实现滚动支持
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);

    // 获取 labelShow 的原始几何尺寸
    // 表示该控件相对于其父控件的几何信息（位置 + 大小）
    QRect rcLabel = ui->labelShow->geometry();

    // 创建一个滚动区域并将 labelShow 设置为其子控件
    QScrollArea* scrollArea = new QScrollArea(this);
    // 把 labelShow 这个 QLabel 设置为 scrollArea（滚动区域）的子控件。
    // scrollArea 会自动显示 labelShow 的内容；
    // 如果 labelShow 太大（超出 scrollArea 大小），scrollArea 会提供滚动条；
    // scrollArea 会接管 labelShow 的父对象和显示逻辑。
    scrollArea->setWidget(ui->labelShow);
    // 将 scrollArea 的大小和位置设置为 labelShow 原本在窗口中的位置和大小
    scrollArea->setGeometry(rcLabel);

    // 输出当前支持的图片与动画格式
    qDebug() << QImageReader::supportedImageFormats();
    qDebug() << QMovie::supportedFormats();

    // 设置主界面窗体最小尺寸
    this->setMinimumSize(350, 350);
}

// 析构函数：释放资源
Widget::~Widget() {
    clearOldShow(); // 清除旧显示内容（手动释放 pixmap 或 movie）
    delete ui;
}

// 清除旧的图像/动画内容，释放内存
void Widget::clearOldShow() {
    ui->labelShow->clear(); // 清空显示

    // 释放静态图资源
    if (pixmap != nullptr) {
        delete pixmap;
        pixmap = nullptr;
    }

    // 释放动态图资源
    if (movie != nullptr) {
        if (isPlaying) movie->stop(); // 正在播放先停止
        delete movie;
        movie = nullptr;
    }

    isMovie = false;
    isPlaying = false;
}

// 点击“打开图片”按钮后的响应槽函数
void Widget::on_btnOpenPic_clicked() {
    QString fileName;

    // 弹出文件选择对话框
    fileName = QFileDialog::getOpenFileName(this, tr("打开静态图"), "", "Pictures (*.bmp *.jpg *.jpeg *.png *.xpm);;All files(*)");
    if (fileName.isEmpty()) return;

    clearOldShow(); // 释放上一个资源
    qDebug() << fileName;

    pixmap = new QPixmap();
    if (pixmap->load(fileName)) {
        ui->labelShow->setPixmap(*pixmap);          // 设置图像
        ui->labelShow->setGeometry(pixmap->rect()); // 自动调整 label 大小
        isMovie = false;
        isPlaying = false;
    } else {
        delete pixmap;
        pixmap = nullptr;
        QMessageBox::critical(this, tr("打开失败"), tr("打开图片失败，文件名为：\r\n%1").arg(fileName));
    }
}

// 点击“打开动画”按钮后的响应槽函数
void Widget::on_btnOpenMov_clicked() {
    QString fileName;

    // 弹出文件选择对话框
    fileName = QFileDialog::getOpenFileName(this, tr("打开动态图"), "", "Movies (*.gif *.mng);;All files(*)");
    if (fileName.isEmpty()) return;

    clearOldShow(); // 清除旧资源
    qDebug() << fileName;

    movie = new QMovie(fileName);
    if (!movie->isValid()) {
        QMessageBox::critical(this, tr("动态图格式不可用"), tr("动态图格式不支持或读取出错，文件名为：\r\n%1").arg(fileName));
        delete movie;
        movie = nullptr;
        return;
    }

    // 获取总帧数（有些 gif 不支持，返回 -1）
    int count = movie->frameCount();
    qDebug() << tr("总帧数：%1").arg(count);

    // 设置滑动条最大值（回退默认值 100 以支持未知帧数）
    ui->horizontalSlider->setMaximum(count > 0 ? count : 100);

    // 设置动画显示到 label 中
    ui->labelShow->setMovie(movie);
    isMovie = true;
    isPlaying = false;

    // 使用新信号槽语法连接错误处理与帧更新
    connect(movie, &QMovie::error, this, &Widget::recvPlayError);
    connect(movie, &QMovie::frameChanged, this, &Widget::recvFrameNumber);

    // 跳转到第一帧并设置 label 大小
    if (movie->jumpToFrame(0)) {
        ui->labelShow->setGeometry(movie->frameRect());
    }
}

// “播放”按钮点击槽函数
void Widget::on_btnStart_clicked() {
    if (!isMovie || isPlaying) return; // 非动画或已经在播放
    isPlaying = true;
    movie->start();
    qDebug() << tr("循环计数：%1").arg(movie->loopCount());
}

// “暂停”按钮点击槽函数
void Widget::on_btnStop_clicked() {
    if (!isMovie || !isPlaying) return;
    isPlaying = false;
    movie->stop();
}

// 动画播放出错时的处理槽函数
void Widget::recvPlayError(QImageReader::ImageReaderError error) {
    qDebug() << tr("读取动态图错误的代码：%1").arg(error);
    QMessageBox::critical(this, tr("播放出错"), tr("播放动态图出错，文件名为：\r\n%1").arg(movie->fileName()));
    isPlaying = false;
}

// 每一帧更新时，设置滑动条位置
void Widget::recvFrameNumber(int frameNumber) {
    ui->horizontalSlider->setValue(frameNumber);
}

// 重写
void Widget::resizeEvent(QResizeEvent* event) {
    int W = event->size().width();
    int H = event->size().height();

    // 先计算第二行四个按钮的左上角坐标，按钮尺寸固定为 75*23
    // 第一个按钮
    int x1 = 10;                    // 左边距 10
    int y1 = H - 10 - 21 - 10 - 23; // 10 都是间隔，21 是水平滑动条高度，23 是按钮高度
    // 第四个按钮
    int x4 = W - 10 - 75; // 10 是右边距，75 是按钮宽度
    int y4 = y1;          // 与第一个按钮同一水平线
    // 计算四个按钮的三个间隙总大小
    int nTriGap = W - 10 - 10 - 75 * 4;
    // 计算单个间隙
    int nGap = nTriGap / 3;
    // 计算第二个按钮坐标
    int x2 = x1 + 75 + nGap;
    int y2 = y1;
    // 计算第三个按钮左边
    int x3 = x4 - 75 - nGap;
    int y3 = y1;

    // 设置四个按钮的矩形
    ui->btnOpenPic->setGeometry(x1, y1, 75, 23);
    ui->btnOpenMov->setGeometry(x2, y2, 75, 23);
    ui->btnStart->setGeometry(x3, y3, 75, 23);
    ui->btnStop->setGeometry(x4, y4, 75, 23);

    // 计算第三行水平滑动条的坐标和尺寸
    int xSlider = x2;
    int ySlider = H - 10 - 21;
    int wSlider = W - x2 - 10;
    int hSlider = 21;
    // 设置水平滑动条的矩形
    ui->horizontalSlider->setGeometry(xSlider, ySlider, wSlider, hSlider);

    // 计算包裹标签的滚动区域占用的矩形
    int xLabel = 10;
    int yLabel = 10;
    int wLabel = W - 10 - 10;
    int hLabel = H - 10 - 21 - 10 - 23 - 10 - 10;
    // 设置包裹标签的滚动区域矩形
    QScrollArea* pSA = this->findChild<QScrollArea*>(); // 查找子对象
    // 如果 pSA 不为 nullptr 才能设置矩形
    if (pSA != nullptr) pSA->setGeometry(xLabel, yLabel, wLabel, hLabel);
}
```

### 计算文本显示宽度

#### QWidget::adjustSize()

`QWidget::adjustSize()` 会根据控件内容（比如子控件的大小、布局、字体等）**自动调整当前控件的大小，以“刚好能包住内容”**为目标。

```cpp
QLabel* label = new QLabel(this);
label->setText("动态内容");
label->adjustSize();  // 让 QLabel 自动变大以显示完整内容
```

`adjustSize()` 实际上是调用 `sizeHint()` 获取推荐尺寸，然后调用 `resize(sizeHint())`。

```cpp
void QWidget::adjustSize() {
    resize(sizeHint());
}
```

如果你重写了 `sizeHint()`，它就会使用你提供的尺寸。

#### QFontMetrics

`QFontMetrics` 是 Qt 中用于 **测量字体相关尺寸信息** 的类，主要功能是根据某个字体 `QFont` 来**计算文本的大小、行高、对齐、间距等**信息。它对布局、自定义绘制控件、精确控制文本位置等非常重要。

##### 常用构造方式

```cpp
QFont font("Microsoft YaHei", 12);
QFontMetrics metrics(font);
```

也可以在 widget 的 paintEvent 中直接使用当前字体：

```cpp
QFontMetrics metrics(this->font());
```

##### 常用函数速查表

| 函数名                                                       | 返回类型  | 说明                                   |
| ------------------------------------------------------------ | --------- | -------------------------------------- |
| `width(const QString &text)`（Qt5）`horizontalAdvance(const QString &text)`（Qt6） | `int`     | 获取字符串的**水平宽度（像素）**       |
| `height()`                                                   | `int`     | 获取总高度（行高）                     |
| `ascent()`                                                   | `int`     | 获取字体**基线以上**的高度             |
| `descent()`                                                  | `int`     | 获取字体**基线以下**的高度             |
| `leading()`                                                  | `int`     | 获取**行间距**（行与行之间的额外空间） |
| `boundingRect(const QString &text)`                          | `QRect`   | 返回包围文字的矩形区域                 |
| `elidedText(text, mode, width)`                              | `QString` | 超出宽度时加省略号（...）的文本        |

 示例：计算字符串宽度并设置 QLabel 宽度

```cpp
QLabel* label = new QLabel("Hello Qt");
QFontMetrics metrics(label->font());
int width = metrics.horizontalAdvance("Hello Qt");
label->setFixedWidth(width);  // 宽度正好包住文字
```

##### QFontMetrics vs QFontMetricsF

- `QFontMetrics` 返回的是整数，精度较低，常用于普通控件；

- `QFontMetricsF` 返回的是浮点数，适用于高精度绘制（比如自定义 OpenGL 渲染控件）。

#### QFontMetrics::size()

```cpp
QSize QFontMetrics::size(int flags, const QString &text) const;
```

返回给定 `text` 在指定绘图标志（`flags`）下所需的尺寸（`QSize`），**适用于多行文本和复杂格式的测量**。

这比 `horizontalAdvance()` 更通用（后者只测一行宽度），**支持多行、对齐方式等更多排版控制**。

| 参数    | 含义说明                                              |
| ------- | ----------------------------------------------------- |
| `flags` | `Qt::TextFlag` 类型的标志位，例如对齐方式、是否换行等 |
| `text`  | 要计算的文本内容                                      |

常用 `flags` 值有：

- `Qt::TextSingleLine`：单行显示（默认不换行）
- `Qt::TextWordWrap`：自动换行
- `Qt::AlignLeft`, `Qt::AlignCenter`, `Qt::AlignRight`：对齐方式

##### 示例代码

```cpp
QFont font("Microsoft YaHei", 12);
QFontMetrics metrics(font);

QString text = "This is a\nmulti-line text.";
QSize size = metrics.size(Qt::TextWordWrap, text);

qDebug() << "宽度:" << size.width() << "高度:" << size.height();
```

#### 示例

##### widget.ui

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>Widget</class>
 <widget class="QWidget" name="Widget">
  <property name="geometry">
   <rect>
    <x>0</x>
    <y>0</y>
    <width>391</width>
    <height>267</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <widget class="QLabel" name="label_1">
   <property name="geometry">
    <rect>
     <x>30</x>
     <y>30</y>
     <width>53</width>
     <height>24</height>
    </rect>
   </property>
   <property name="text">
    <string>按钮文本</string>
   </property>
  </widget>
  <widget class="QLabel" name="label_2">
   <property name="geometry">
    <rect>
     <x>20</x>
     <y>80</y>
     <width>53</width>
     <height>24</height>
    </rect>
   </property>
   <property name="text">
    <string>动态按钮</string>
   </property>
  </widget>
  <widget class="QLabel" name="label_3">
   <property name="geometry">
    <rect>
     <x>20</x>
     <y>130</y>
     <width>53</width>
     <height>24</height>
    </rect>
   </property>
   <property name="text">
    <string>固定按钮</string>
   </property>
  </widget>
  <widget class="QLineEdit" name="lineEdit">
   <property name="geometry">
    <rect>
     <x>100</x>
     <y>30</y>
     <width>113</width>
     <height>24</height>
    </rect>
   </property>
  </widget>
  <widget class="QPushButton" name="btnDynamic">
   <property name="geometry">
    <rect>
     <x>110</x>
     <y>80</y>
     <width>75</width>
     <height>24</height>
    </rect>
   </property>
   <property name="text">
    <string>动态</string>
   </property>
  </widget>
  <widget class="QPushButton" name="btnFixed">
   <property name="geometry">
    <rect>
     <x>120</x>
     <y>130</y>
     <width>75</width>
     <height>24</height>
    </rect>
   </property>
   <property name="text">
    <string>固定</string>
   </property>
  </widget>
 </widget>
 <resources/>
 <connections/>
</ui>
```

##### widget.h

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
    void on_lineEdit_textEdited(const QString& arg1);

  private:
    Ui::Widget* ui;

    // QWidget interface
  protected:
    void resizeEvent(QResizeEvent* event) override;
};
#endif // WIDGET_H
```

##### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QResizeEvent>

Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);
    // 设置窗口的最小尺寸，确保内容不会被挤压得太小
    // 计算最小宽度：10（左边距） + 54（标签宽度） + 10（间隙） + 75（第三行按钮宽度） + 10（右边距）
    // 计算最小高度：24（单行控件高度） * 3（行数） + 10（上下间隙） * 4（行间及边距数量）
    this->setMinimumSize(10 + 54 + 10 + 75 + 10, 24 * 3 + 10 * 4);
}

Widget::~Widget() {
    delete ui;
}

void Widget::on_lineEdit_textEdited(const QString& arg1) {
    QFontMetrics fm = ui->btnDynamic->fontMetrics();

    // 计算文本的宽度（像素）
    int nTextWidth = fm.horizontalAdvance(arg1);
    // 获取动态按钮当前大小
    QSize szButtonDynamic = ui->btnDynamic->size();
    // 按文本宽度调整按钮宽度，增加10像素边距留白
    szButtonDynamic.setWidth(nTextWidth + 10);
    ui->btnDynamic->resize(szButtonDynamic);
    // 设置按钮文本和提示内容
    ui->btnDynamic->setText(arg1);
    ui->btnDynamic->setToolTip(arg1);

    // 固定按钮文本处理：如果文本宽度小于等于65，直接显示
    if (nTextWidth <= 65) {
        ui->btnFixed->setText(arg1);
    } else {
        // 否则截断文本并加省略号，确保按钮宽度不超过65像素
        QString strPart;
        QString strDot = "...";
        int nStrLen = arg1.length();
        int nNewTextWidth = 0;
        for (int i = 0; i < nStrLen; i++) {
            strPart += arg1[i];
            nNewTextWidth = fm.horizontalAdvance(strPart + strDot);
            if (nNewTextWidth >= 65) break;
        }
        ui->btnFixed->setText(strPart + strDot);
    }
    ui->btnFixed->setToolTip(arg1);
}

void Widget::resizeEvent(QResizeEvent* event) {
    // 获取窗口当前宽度和高度
    int W = event->size().width();
    int H = event->size().height();

    // 第一行控件布局
    // 标签1 固定大小54x24，垂直居中在窗口的1/4高度处
    int xLabel1 = 10;         // 左边距10像素
    int yLabel1 = H / 4 - 12; // 标签垂直居中，24高度减半为12
    ui->label_1->move(xLabel1, yLabel1);

    // 单行编辑控件布局
    int xLineEdit = xLabel1 + 54 + 10; // 紧邻标签右侧，间隙10像素
    int yLineEdit = yLabel1;
    int wLineEdit = W - xLineEdit - 10; // 编辑框宽度占剩余宽度，右边距10像素
    int hLineEdit = 24;                 // 高度固定24像素
    ui->lineEdit->setGeometry(xLineEdit, yLineEdit, wLineEdit, hLineEdit);

    // 第二行控件布局
    // 标签2 固定大小54x24，垂直居中在窗口的2/4高度处
    int xLabel2 = 10;
    int yLabel2 = 2 * H / 4 - 12;
    ui->label_2->move(xLabel2, yLabel2);
    // 动态按钮紧邻标签右侧，大小由槽函数动态调整
    int xButtonDynamic = xLabel2 + 54 + 10;
    int yButtonDynamic = yLabel2;
    ui->btnDynamic->move(xButtonDynamic, yButtonDynamic);

    // 第三行控件布局
    // 标签3 固定大小54x24，垂直居中在窗口的3/4高度处
    int xLabel3 = 10;
    int yLabel3 = 3 * H / 4 - 12;
    ui->label_3->move(xLabel3, yLabel3);
    // 固定按钮紧邻标签右侧，大小固定
    int xButtonFixed = xLabel3 + 54 + 10;
    int yButtonFixed = yLabel3;
    ui->btnFixed->move(xButtonFixed, yButtonFixed);
}
```