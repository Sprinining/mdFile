## QDialog 多窗口使用

### QDialog

`QDialog` 是 Qt 框架中用于创建**对话框窗口**（Dialog）的类，是 GUI 应用开发中非常常用的组件之一。它继承自 `QWidget`，意味着它本质上是一个窗口部件，但被专门设计用来创建“模态”或“非模态”的对话框。

#### 模态 vs 非模态

##### 模态对话框（Modal Dialog）

- 会阻塞父窗口的交互。
- 使用 `.exec()` 启动。
- 常见场景：确认、保存、设置。

```cpp
MyDialog dlg;
if (dlg.exec() == QDialog::Accepted) {
    // 用户点击了“确定”
}
```

##### 非模态对话框（Modeless Dialog）

- 不阻塞父窗口，用户可以切换回主窗口。

- 使用 `.show()` 启动。

- 通常用于辅助工具窗口等。

```cpp
MyDialog *dlg = new MyDialog(this);
dlg->show();  // 不阻塞主窗口
```

| 类型                   | 特点                                           | 常用方法  |
| ---------------------- | ---------------------------------------------- | --------- |
| **模态（Modal）**      | 阻止用户与其他窗口交互必须先关闭它才能继续操作 | `.exec()` |
| **非模态（Modeless）** | 不会阻止主窗口，可以自由切换交互               | `.show()` |

#### 常用成员函数

| 函数名             | 说明                           |
| ------------------ | ------------------------------ |
| `exec()`           | 启动模态对话框，并阻塞直到关闭 |
| `show()`           | 启动非模态对话框               |
| `accept()`         | 设置返回值为 `Accepted` 并关闭 |
| `reject()`         | 设置返回值为 `Rejected` 并关闭 |
| `done(int r)`      | 设置任意返回码并关闭           |
| `result()`         | 获取 `.exec()` 的返回结果      |
| `setModal(bool)`   | 设置是否为模态                 |
| `setWindowTitle()` | 设置窗口标题                   |

#### 使用示例

```cpp
// 自定义对话框类，继承自 QDialog
class MyDialog : public QDialog {
    Q_OBJECT  // Qt 元对象系统宏，支持信号与槽机制

public:
    // 构造函数，parent 默认为空指针
    MyDialog(QWidget *parent = nullptr) : QDialog(parent) {
        // 创建一个垂直布局管理器，并设置为该对话框的布局器
        QVBoxLayout *layout = new QVBoxLayout(this);

        // 创建一个名为 "OK" 的按钮
        QPushButton *okBtn = new QPushButton("OK");

        // 将按钮点击信号与 QDialog 的 accept() 槽函数连接
        // 点击按钮后对话框会以“接受”状态关闭（即 exec() 返回 QDialog::Accepted）
        connect(okBtn, &QPushButton::clicked, this, &QDialog::accept);

        // 将按钮添加到布局中
        layout->addWidget(okBtn);

        // 设置布局到当前对话框
        setLayout(layout);
    }
};
```

调用方式示例：

```cpp
MyDialog dlg;                         // 创建对话框对象
if (dlg.exec() == QDialog::Accepted) // 启动模态对话框，等待用户操作
{
    // 如果用户点击了 OK（即触发 accept），则进入这个分支
}
```

#### 衍生类（常见）

- `QFileDialog`：文件选择对话框
- `QColorDialog`：颜色选择器
- `QFontDialog`：字体选择器
- `QMessageBox`：信息提示框

这些都是从 `QDialog` 派生的封装类。

### 示例：QDialog 多窗口

#### resizeimagedialog.ui

```cpp
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>ResizeImageDialog</class>
 <widget class="QDialog" name="ResizeImageDialog">
  <property name="geometry">
   <rect>
    <x>0</x>
    <y>0</y>
    <width>320</width>
    <height>200</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Dialog</string>
  </property>
  <layout class="QVBoxLayout" name="verticalLayout">
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout">
     <item>
      <widget class="QLabel" name="label">
       <property name="text">
        <string>当前尺寸</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditOldSize"/>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_2">
     <item>
      <widget class="QLabel" name="label_2">
       <property name="text">
        <string>宽度×高度</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QSpinBox" name="spinBoxWidthNew">
       <property name="sizePolicy">
        <sizepolicy hsizetype="Expanding" vsizetype="Fixed">
         <horstretch>0</horstretch>
         <verstretch>0</verstretch>
        </sizepolicy>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QSpinBox" name="spinBoxHeightNew">
       <property name="sizePolicy">
        <sizepolicy hsizetype="Expanding" vsizetype="Fixed">
         <horstretch>0</horstretch>
         <verstretch>0</verstretch>
        </sizepolicy>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="pushButtonSetNewSize">
       <property name="text">
        <string>设置新尺寸</string>
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

#### resizeimagedialog.h

```cpp
#ifndef RESIZEIMAGEDIALOG_H
#define RESIZEIMAGEDIALOG_H

#include <QDialog> // 引入 QDialog 基类

// Qt Designer 生成的命名空间，前向声明 UI 类（界面元素封装）
namespace Ui {
class ResizeImageDialog;
}

// 缩放图片的对话框类，继承自 QDialog
class ResizeImageDialog : public QDialog {
    Q_OBJECT // 启用 Qt 的信号槽机制

  public :
    // 构造函数，parent 可选，默认无父对象
    explicit ResizeImageDialog(QWidget* parent = nullptr);

    // 析构函数，释放资源
    ~ResizeImageDialog();

  signals:
    // 发送新尺寸信号（宽度和高度），由主窗口接收并完成缩放操作
    void sendNewSize(int nNewWidth, int nNewHeight);

  public slots:
    // 接收旧尺寸（来自主窗口），用于初始化输入框显示等
    void recvOldSize(int nOldWidth, int nOldHeight);

  private slots:
    // 点击“设置新尺寸”按钮的槽函数，读取输入并发出 sendNewSize 信号
    void on_pushButtonSetNewSize_clicked();

  private:
    Ui::ResizeImageDialog* ui; // Qt UI 界面指针（由 Designer 自动生成）
    void init();               // 初始化函数，用于设置界面默认状态、信号槽连接等
};

#endif // RESIZEIMAGEDIALOG_H
```

#### resizeimagedialog.cpp

```cpp
#include "resizeimagedialog.h"
#include "ui_resizeimagedialog.h"

// 构造函数：初始化 UI，并调用自定义初始化函数
ResizeImageDialog::ResizeImageDialog(QWidget* parent) : QDialog(parent), ui(new Ui::ResizeImageDialog) {
    ui->setupUi(this); // 绑定 UI 组件
    init();            // 执行自定义初始化
}

// 析构函数：释放 UI 对象资源
ResizeImageDialog::~ResizeImageDialog() {
    delete ui;
}

// 初始化函数：设置界面控件属性
void ResizeImageDialog::init() {
    // 设置旧尺寸输入框为只读，不允许用户修改
    ui->lineEditOldSize->setReadOnly(true);
    ui->lineEditOldSize->setStyleSheet("background-color: lightgray;");

    // 设置新的宽度和高度输入范围，防止用户输入非法值
    ui->spinBoxWidthNew->setRange(1, 10000);
    ui->spinBoxHeightNew->setRange(1, 10000);

    // 设置窗口标题
    setWindowTitle(tr("缩放图片尺寸"));
}

// 接收来自主窗口的旧图片尺寸并显示，同时设置默认新尺寸
void ResizeImageDialog::recvOldSize(int nOldWidth, int nOldHeight) {
    // 构造旧尺寸字符串，如 "800 X 600"
    QString strOldSize = tr("%1 X %2").arg(nOldWidth).arg(nOldHeight);
    ui->lineEditOldSize->setText(strOldSize); // 显示旧尺寸

    // 将新尺寸的 spinBox 默认值设置为当前尺寸
    ui->spinBoxWidthNew->setValue(nOldWidth);
    ui->spinBoxHeightNew->setValue(nOldHeight);
}

// 点击“确定设置新尺寸”按钮时的槽函数
void ResizeImageDialog::on_pushButtonSetNewSize_clicked() {
    // 获取用户输入的新宽度和高度
    int nNewWidth = ui->spinBoxWidthNew->value();
    int nNewHeight = ui->spinBoxHeightNew->value();

    // 发射信号，将新尺寸传回主窗口进行图片缩放
    emit sendNewSize(nNewWidth, nNewHeight);

    // 更新旧尺寸框显示为新的尺寸值，供用户参考
    QString strSize = tr("%1 X %2").arg(nNewWidth).arg(nNewHeight);
    ui->lineEditOldSize->setText(strSize);
}
```

#### rotateimagedialog.ui

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>RotateImageDialog</class>
 <widget class="QDialog" name="RotateImageDialog">
  <property name="geometry">
   <rect>
    <x>0</x>
    <y>0</y>
    <width>320</width>
    <height>100</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Dialog</string>
  </property>
  <layout class="QHBoxLayout" name="horizontalLayout">
   <item>
    <widget class="QLabel" name="label">
     <property name="text">
      <string>顺时针旋转角度</string>
     </property>
    </widget>
   </item>
   <item>
    <widget class="QSpinBox" name="spinBoxAngle">
     <property name="sizePolicy">
      <sizepolicy hsizetype="Expanding" vsizetype="Fixed">
       <horstretch>0</horstretch>
       <verstretch>0</verstretch>
      </sizepolicy>
     </property>
    </widget>
   </item>
   <item>
    <widget class="QPushButton" name="pushButtonRotating">
     <property name="text">
      <string>执行旋转</string>
     </property>
    </widget>
   </item>
  </layout>
 </widget>
 <resources/>
 <connections/>
</ui>
```

#### rotateimagedialog.h

```cpp
#ifndef ROTATEIMAGEDIALOG_H
#define ROTATEIMAGEDIALOG_H

#include <QDialog> // Qt 提供的对话框基类

// Qt Designer 自动生成的命名空间，前向声明 UI 类
namespace Ui {
class RotateImageDialog;
}

// 旋转图片的对话框类，继承自 QDialog
class RotateImageDialog : public QDialog {
    Q_OBJECT // 启用 Qt 的信号与槽功能

  public :
    // 构造函数，parent 默认为空指针（无父窗口）
    explicit RotateImageDialog(QWidget* parent = nullptr);

    // 析构函数，自动释放资源
    ~RotateImageDialog();

  private slots:
    // 当点击“确认旋转”按钮时触发的槽函数
    void on_pushButtonRotating_clicked();

  private:
    Ui::RotateImageDialog* ui; // UI 界面指针，用于访问 Designer 中定义的控件
    void init();               // 初始化函数，用于设置控件状态、连接信号槽等
};

#endif // ROTATEIMAGEDIALOG_H
```

#### rotateimagedialog.cpp

```cpp
#include "rotateimagedialog.h"
#include "ui_rotateimagedialog.h"

// 构造函数：初始化 UI 并进行控件设置
RotateImageDialog::RotateImageDialog(QWidget* parent) : QDialog(parent), ui(new Ui::RotateImageDialog) {
    ui->setupUi(this); // 加载 UI 布局
    init();            // 自定义初始化
}

// 析构函数：释放 UI 对象资源
RotateImageDialog::~RotateImageDialog() {
    delete ui;
}

// 初始化函数：设置角度选择框和窗口标题
void RotateImageDialog::init() {
    // 设置旋转角度选择框的数值范围为 0~360 度
    ui->spinBoxAngle->setRange(0, 360);

    // 设置 spinBox 的后缀为“°”，表示单位为度
    ui->spinBoxAngle->setSuffix(tr("°"));

    // 设置窗口标题
    setWindowTitle(tr("旋转图片"));
}

// “确定旋转”按钮点击事件处理函数
void RotateImageDialog::on_pushButtonRotating_clicked() {
    // 获取用户设置的角度值
    int nAngle = ui->spinBoxAngle->value();
    // 调用 done() 结束对话框并返回角度值，供主窗口通过 exec() 获取
    done(nAngle);
}
```

#### imagetransformwidget.ui

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>ImageTransformWidget</class>
 <widget class="QWidget" name="ImageTransformWidget">
  <property name="geometry">
   <rect>
    <x>0</x>
    <y>0</y>
    <width>400</width>
    <height>300</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>ImageTransformWidget</string>
  </property>
  <layout class="QHBoxLayout" name="horizontalLayout">
   <item>
    <widget class="QScrollArea" name="scrollArea">
     <property name="widgetResizable">
      <bool>true</bool>
     </property>
     <widget class="QWidget" name="scrollAreaWidgetContents">
      <property name="geometry">
       <rect>
        <x>0</x>
        <y>0</y>
        <width>297</width>
        <height>280</height>
       </rect>
      </property>
     </widget>
    </widget>
   </item>
   <item>
    <layout class="QVBoxLayout" name="verticalLayout">
     <item>
      <widget class="QPushButton" name="pushButtonOpen">
       <property name="text">
        <string>打开图片</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="pushButtonResize">
       <property name="text">
        <string>缩放图片</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="pushButtonRotate">
       <property name="text">
        <string>旋转图片</string>
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

#### imagetransformwidget.h

```cpp
#ifndef IMAGETRANSFORMWIDGET_H
#define IMAGETRANSFORMWIDGET_H

// 引入自定义对话框头文件：缩放尺寸对话框和旋转对话框
#include "resizeimagedialog.h"
#include "rotateimagedialog.h"

// 引入 Qt 的标准组件
#include <QFileDialog> // 用于文件选择对话框
#include <QLabel>      // 图片显示控件
#include <QPixmap>     // 用于加载和操作图片
#include <QTransform>  // 用于图片的矩阵变换（缩放、旋转等）
#include <QWidget>     // 基类 QWidget

QT_BEGIN_NAMESPACE
namespace Ui {
class ImageTransformWidget; // 前向声明 UI 类
}
QT_END_NAMESPACE

// ImageTransformWidget 继承自 QWidget，是图片缩放与旋转的主界面类
class ImageTransformWidget : public QWidget {
    Q_OBJECT // Qt 元对象宏，支持信号槽机制

  public :
    // 构造函数与析构函数
    ImageTransformWidget(QWidget* parent = nullptr);
    ~ImageTransformWidget();

  signals:
    // 向 resizeImageDialog 发出旧的图片尺寸（宽、高）
    void sendOldSize(int nOldWidth, int nOldHeight);

  public slots:
    // 接收 resizeImageDialog 返回的新尺寸，并执行缩放操作
    void recvNewSizeAndResize(int nNewWidth, int nNewHeight);

  private slots:
    // “打开图片”按钮的槽函数
    void on_pushButtonOpen_clicked();

    // “缩放图片”按钮的槽函数
    void on_pushButtonResize_clicked();

    // “旋转图片”按钮的槽函数
    void on_pushButtonRotate_clicked();

  private:
    Ui::ImageTransformWidget* ui; // UI 指针，界面布局对象

    QLabel* m_pLabelImage; // 用于显示图片的 QLabel
    QPixmap m_image;       // 当前加载的图片对象
    QString m_strFileName; // 当前图片的文件路径

    ResizeImageDialog* m_pResizeDlg; // 缩放尺寸对话框指针
    RotateImageDialog* m_pRotateDlg; // 旋转图片对话框指针

    void init(); // 初始化函数，设置界面控件、信号槽等
};

#endif // IMAGETRANSFORMWIDGET_H
```

#### imagetransformwidget.cpp

```cpp
#include "imagetransformwidget.h"
#include "./ui_imagetransformwidget.h"
#include <QDebug>
#include <QMessageBox>

// 构造函数，初始化 UI 和控件
ImageTransformWidget::ImageTransformWidget(QWidget* parent) : QWidget(parent), ui(new Ui::ImageTransformWidget) {
    ui->setupUi(this); // 加载 UI 组件
    init();            // 初始化界面元素和逻辑
}

// 析构函数，释放资源
ImageTransformWidget::~ImageTransformWidget() {
    delete m_pResizeDlg;
    m_pResizeDlg = nullptr;

    delete m_pRotateDlg;
    m_pRotateDlg = nullptr;

    delete ui;
}

// 初始化函数，设置标签、滚动区、对话框及信号槽
void ImageTransformWidget::init() {
    // 创建用于显示图片的标签
    m_pLabelImage = new QLabel();
    m_pLabelImage->setAlignment(Qt::AlignLeft | Qt::AlignTop);    // 左上对齐
    m_pLabelImage->setStyleSheet("background-color: lightgray;"); // 设置背景色

    // 将标签设置为滚动区域内容
    ui->scrollArea->setWidget(m_pLabelImage);

    // 创建缩放尺寸对话框，并设置为当前窗口的子窗口
    m_pResizeDlg = new ResizeImageDialog(this);

    // 连接信号槽：主窗口发送旧尺寸 → 子对话框接收
    connect(this, &ImageTransformWidget::sendOldSize, m_pResizeDlg, &ResizeImageDialog::recvOldSize);

    // 连接信号槽：子对话框发送新尺寸 → 主窗口执行缩放
    connect(m_pResizeDlg, &ResizeImageDialog::sendNewSize, this, &ImageTransformWidget::recvNewSizeAndResize);

    // 创建旋转图片对话框
    m_pRotateDlg = new RotateImageDialog(this);
    // 旋转使用模态对话框 + exec() 获取角度，不需额外信号槽
}

// 点击“打开图片”按钮的槽函数
void ImageTransformWidget::on_pushButtonOpen_clicked() {
    // 弹出文件选择对话框，选择图片文件
    QString strFile = QFileDialog::getOpenFileName(this, tr("打开图片文件"), tr(""), tr("Image files(*.png *.jpg *.bmp)"));

    if (strFile.isEmpty()) return; // 没选文件

    // 尝试加载图片
    bool bLoadOK = m_image.load(strFile);
    if (!bLoadOK) {
        QMessageBox::warning(this, tr("加载图片文件"), tr("加载图片文件失败，请检查文件格式。"));
        return;
    }

    // 保存文件路径
    m_strFileName = strFile;

    // 显示图片到标签
    m_pLabelImage->setPixmap(m_image);

    // 设置窗口标题为文件名
    setWindowTitle(tr("预览文件为 %1").arg(m_strFileName));
}

// 点击“缩放图片”按钮的槽函数
void ImageTransformWidget::on_pushButtonResize_clicked() {
    if (m_image.isNull()) return; // 图片未加载

    // 将当前图片的宽高发送给缩放对话框
    emit sendOldSize(m_image.width(), m_image.height());

    // 显示对话框
    m_pResizeDlg->show();
    m_pResizeDlg->raise(); // 置顶显示
}

// 点击“旋转图片”按钮的槽函数
void ImageTransformWidget::on_pushButtonRotate_clicked() {
    if (m_image.isNull()) return; // 图片未加载

    // 显示模态旋转对话框，等待用户输入角度
    int nAngle = m_pRotateDlg->exec();
    if (nAngle == 0) return; // 用户没有输入有效角度

    // 构造旋转变换矩阵
    QTransform mxRotate;
    mxRotate.rotate(nAngle);

    // 执行旋转操作，得到新图片
    QPixmap imgNew = m_image.transformed(mxRotate);

    // 更新成员变量并刷新显示
    m_image = imgNew;
    m_pLabelImage->setPixmap(m_image);
}

// 接收新尺寸并执行缩放的槽函数
void ImageTransformWidget::recvNewSizeAndResize(int nNewWidth, int nNewHeight) {
    // 如果尺寸没变化，直接返回
    if ((m_image.width() == nNewWidth) && (m_image.height() == nNewHeight)) return;

    // 缩放图片
    QPixmap imgNew = m_image.scaled(nNewWidth, nNewHeight);

    // 更新成员变量并刷新显示
    m_image = imgNew;
    m_pLabelImage->setPixmap(m_image);
}
```

