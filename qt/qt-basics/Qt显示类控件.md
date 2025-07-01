## Qt 显示类控件

### 继承关系图

```css
QObject
 └── QWidget
      ├── QLabel
      ├── QTextEdit
      │    └── QTextBrowser
      ├── QFrame
      │     ├── QLCDNumber
      │     ├── QProgressBar
      │     ├── QCalendarWidget
      │     ├── QGroupBox
      │     ├── QScrollArea
      │     ├── QAbstractScrollArea
      │     │    └── QGraphicsView
      │     └── QAbstractButton
      │          ├── QPushButton
      │          ├── QToolButton
      │          ├── QRadioButton
      │          ├── QCheckBox
      │          └── QCommandLinkButton
      ├── QAbstractScrollArea  (直接继承 QWidget)
      │     ├── QTextEdit  (QTextEdit 也继承自 QWidget 和 QAbstractScrollArea)
      │     └── QGraphicsView
      ├── QOpenGLWidget
      ├── QQuickWidget
      ├── QWebEngineView
      ├── QDialog
      ├── QMainWindow
      ├── QWidget
      └── ...
```

### 典型的「显示用途」控件一览

| 控件名                                | 用途                 | 特点                           |
| ------------------------------------- | -------------------- | ------------------------------ |
| **QLabel**                            | 显示文字或图像       | 可设置纯文本/HTML/图片         |
| **QTextBrowser**                      | 显示富文本内容       | 支持超链接，基于 `QTextEdit`   |
| **QLCDNumber**                        | 显示数字             | 仿 LCD 样式，支持整数/小数     |
| **QProgressBar**                      | 显示进度状态         | 可设置最小值、最大值与当前值   |
| **QCalendarWidget**                   | 显示日历             | 展示和选择日期，带样式         |
| **QGraphicsView**                     | 显示图形场景         | 支持图形视图框架（2D 图形）    |
| **QOpenGLWidget**                     | 显示 OpenGL 渲染图形 | 自定义 3D 图形/图像处理        |
| **QQuickWidget**                      | 显示 QML 界面        | 将 Qt Quick 嵌入 QWidget 应用  |
| **QWebEngineView**                    | 显示网页             | 支持 HTML5、JavaScript、CSS    |
| **QMovie（非控件）**                  | 用于 QLabel 播放 GIF | 辅助 `QLabel` 实现动态图像显示 |
| **QPixmap/QImage/QPicture（非控件）** | 图像载体             | 搭配 `QLabel`、绘图系统显示    |

- QWebEngineView` 需要引入模块：`QT += webenginewidgets

- `QQuickWidget` 用于将 QML 融入传统 QWidget UI

- `QOpenGLWidget` 可用于游戏、图形可视化、图像处理等高性能图形场景

- `QGraphicsView` 与 `QGraphicsScene/QGraphicsItem` 配合使用，适合图形编辑器、连线图、节点图等

### 不属于控件但参与显示的类（辅助）

| 类名                         | 用法                               |
| ---------------------------- | ---------------------------------- |
| `QPixmap` / `QImage`         | 图像载体，用于在控件中显示图像     |
| `QMovie`                     | 播放 GIF 动画                      |
| `QPainter`                   | 自定义绘图（绘制线、图像、文本等） |
| `QLine`, `QRect`, `QPolygon` | 图元类，用于描述图形信息           |

### 示例：图片浏览

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
    <width>472</width>
    <height>473</height>
   </rect>
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
     <height>22</height>
    </rect>
   </property>
   <property name="orientation">
    <enum>Qt::Orientation::Horizontal</enum>
   </property>
  </widget>
  <widget class="QWidget" name="horizontalLayoutWidget">
   <property name="geometry">
    <rect>
     <x>80</x>
     <y>350</y>
     <width>320</width>
     <height>61</height>
    </rect>
   </property>
   <layout class="QHBoxLayout" name="horizontalLayout">
    <item>
     <widget class="QPushButton" name="btnOpenPic">
      <property name="text">
       <string>打开图片</string>
      </property>
     </widget>
    </item>
    <item>
     <widget class="QPushButton" name="btnOpenMov">
      <property name="text">
       <string>打开动态图</string>
      </property>
     </widget>
    </item>
    <item>
     <widget class="QPushButton" name="btnStart">
      <property name="text">
       <string>播放</string>
      </property>
     </widget>
    </item>
    <item>
     <widget class="QPushButton" name="btnStop">
      <property name="text">
       <string>停止</string>
      </property>
     </widget>
    </item>
   </layout>
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
};

#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"
#include <QDebug>
#include <QFileDialog>
#include <QMessageBox>
#include <QScrollArea>

// 构造函数：初始化 UI 并用 QScrollArea 包装 label 实现滚动支持
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);

    // 获取 labelShow 的原始几何尺寸
    QRect rcLabel = ui->labelShow->geometry();

    // 创建一个滚动区域并将 labelShow 设置为其子控件
    QScrollArea* scrollArea = new QScrollArea(this);
    scrollArea->setWidget(ui->labelShow);
    scrollArea->setGeometry(rcLabel);

    // 输出当前支持的图片与动画格式
    qDebug() << QImageReader::supportedImageFormats();
    qDebug() << QMovie::supportedFormats();
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
```

### 示例：数字钟

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
    <width>400</width>
    <height>310</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Widget</string>
  </property>
  <widget class="QLCDNumber" name="lcdNumber">
   <property name="geometry">
    <rect>
     <x>10</x>
     <y>10</y>
     <width>341</width>
     <height>95</height>
    </rect>
   </property>
   <property name="digitCount">
    <number>8</number>
   </property>
   <property name="segmentStyle">
    <enum>QLCDNumber::SegmentStyle::Flat</enum>
   </property>
   <property name="value" stdset="0">
    <double>88888888.000000000000000</double>
   </property>
  </widget>
  <widget class="QCalendarWidget" name="calendarWidget">
   <property name="geometry">
    <rect>
     <x>13</x>
     <y>110</y>
     <width>341</width>
     <height>191</height>
    </rect>
   </property>
  </widget>
  <widget class="QPushButton" name="pushButton">
   <property name="geometry">
    <rect>
     <x>360</x>
     <y>110</y>
     <width>31</width>
     <height>191</height>
    </rect>
   </property>
   <property name="text">
    <string>回
到
今
天</string>
   </property>
  </widget>
  <widget class="QProgressBar" name="progressBar">
   <property name="geometry">
    <rect>
     <x>360</x>
     <y>10</y>
     <width>31</width>
     <height>95</height>
    </rect>
   </property>
   <property name="maximum">
    <number>9</number>
   </property>
   <property name="value">
    <number>9</number>
   </property>
   <property name="textVisible">
    <bool>false</bool>
   </property>
   <property name="orientation">
    <enum>Qt::Orientation::Vertical</enum>
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

#include <QTimer>
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
    void recvTimer();

private slots:
    void on_pushButton_clicked();

private:
    Ui::Widget* ui;
    QTimer* timer;
};
#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "./ui_widget.h"

// 构造函数：初始化界面和定时器
Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this);              // 设置 UI（绑定 .ui 文件中控件）
    this->setWindowTitle("电子钟"); // 设置窗口标题

    // 创建定时器，用于每秒更新时间
    timer = new QTimer(this);     // 创建 QTimer 对象，parent 是 this 表示归属当前窗口
    timer->setSingleShot(false);  // 设置为重复定时（非一次性）
    timer->setInterval(1 * 1000); // 设置定时器间隔为 1 秒（单位：毫秒）

    // 连接定时器超时信号到自定义槽函数 recvTimer
    connect(timer, &QTimer::timeout, this, &Widget::recvTimer);

    // 启动定时器
    timer->start();

    // 初始化日历控件选中今天日期
    on_pushButton_clicked();
}

Widget::~Widget() {
    delete ui;
}

// 定时器超时后的槽函数（每秒调用一次）
void Widget::recvTimer() {
    QDateTime dt = QDateTime::currentDateTime();      // 获取当前系统时间
    QString timeStr = dt.time().toString("HH:mm:ss"); // 格式化为“时:分:秒”的字符串

    ui->lcdNumber->display(timeStr);                    // 在 LCD 显示时间
    ui->progressBar->setValue(dt.time().second() % 10); // 进度条表示当前秒数模 10，用于循环效果
}

// 点击按钮后设置日历控件为当前日期
void Widget::on_pushButton_clicked() {
    QDateTime dt = QDateTime::currentDateTime();    // 获取当前时间
    ui->calendarWidget->setSelectedDate(dt.date()); // 设置日历控件选中的日期为今天
    ui->calendarWidget->setFocus();                 // 设置焦点到日历控件（方便键盘操作）
}
```

