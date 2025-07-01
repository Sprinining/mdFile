## QWidget 多窗口使用

在 Qt 中，`QWidget` 是所有界面组件的基类，可以作为一个子组件嵌入到其他组件中，也可以**作为独立窗口使用**。当 `QWidget` 不设置父窗口（即 `parent == nullptr`），它就会成为一个顶级窗口，也就是说它会拥有自己的窗口句柄和标题栏。

### QWidget 作为独立窗口的基本用法

```cpp
#include <QApplication>
#include <QWidget>

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    QWidget window;
    window.resize(400, 300);       // 设置窗口大小
    window.setWindowTitle("独立QWidget窗口");  // 设置窗口标题
    window.show();                 // 显示窗口

    return app.exec();
}
```

如果不设置 `window.setParent(...)`，它就会是一个独立窗口。

### 常见设置

#### 设置窗口标志（Window Flags）

可以通过 `setWindowFlags` 设置窗口类型：

```cpp
window.setWindowFlags(Qt::Window);  // 明确设置为一个窗口
```

其他常见的 flag 包括：

- `Qt::Dialog`：对话框样式
- `Qt::Tool`：工具窗口（在主窗口最前，但最小化时跟随主窗口）
- `Qt::FramelessWindowHint`：无边框窗口
- `Qt::WindowStaysOnTopHint`：置顶窗口

组合使用：

```cpp
window.setWindowFlags(Qt::Window | Qt::FramelessWindowHint);
```

### 设置窗口位置和大小

```cpp
window.resize(800, 600);         // 设置大小
window.move(100, 100);           // 设置初始显示位置
```

### 窗口控制相关函数

- `show()`：显示窗口
- `hide()`：隐藏窗口
- `close()`：关闭窗口
- `raise()`：将窗口置于顶层
- `activateWindow()`：激活窗口（获取焦点）

### 自定义子类作为窗口

可以继承 `QWidget` 来创建自己的窗口类：

```cpp
#include <QWidget>
#include <QPushButton>

class MyWindow : public QWidget {
public:
    MyWindow() {
        setWindowTitle("我的窗口");
        resize(400, 300);

        QPushButton *btn = new QPushButton("点击关闭", this);
        btn->move(150, 130);
        connect(btn, &QPushButton::clicked, this, &QWidget::close);
    }
};
```

然后在 `main.cpp` 中：

```cpp
int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    MyWindow window;
    window.show();

    return app.exec();
}
```

### 注意事项

1. **必须调用 `show()` 才能显示窗口**。
2. 如果在没有父窗口的情况下创建 `QWidget`，它会自动成为顶级窗口。
3. 可以通过 `isWindow()` 来判断是否为窗口。
4. 如果设置了父窗口，那么这个 QWidget 将不会作为独立窗口出现。

### 示例：用户名密码管理

#### formchangepassword.ui

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>FormChangePassword</class>
 <widget class="QWidget" name="FormChangePassword">
  <property name="geometry">
   <rect>
    <x>0</x>
    <y>0</y>
    <width>280</width>
    <height>240</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Form</string>
  </property>
  <layout class="QGridLayout" name="gridLayout">
   <item row="0" column="0">
    <widget class="QLabel" name="label">
     <property name="text">
      <string>用户名</string>
     </property>
    </widget>
   </item>
   <item row="0" column="1">
    <widget class="QLineEdit" name="lineEditUser"/>
   </item>
   <item row="1" column="0">
    <widget class="QLabel" name="label_2">
     <property name="text">
      <string>旧密码</string>
     </property>
    </widget>
   </item>
   <item row="1" column="1">
    <widget class="QLineEdit" name="lineEditOldPassword"/>
   </item>
   <item row="2" column="0">
    <widget class="QLabel" name="label_3">
     <property name="text">
      <string>新密码</string>
     </property>
    </widget>
   </item>
   <item row="2" column="1">
    <widget class="QLineEdit" name="lineEditNewPassword"/>
   </item>
   <item row="3" column="0">
    <widget class="QLabel" name="label_4">
     <property name="text">
      <string>新密码确认</string>
     </property>
    </widget>
   </item>
   <item row="3" column="1">
    <widget class="QLineEdit" name="lineEditNewPassword2"/>
   </item>
   <item row="4" column="0" colspan="2">
    <widget class="QPushButton" name="pushButtonChange">
     <property name="text">
      <string>修改密码</string>
     </property>
    </widget>
   </item>
  </layout>
 </widget>
 <resources/>
 <connections/>
</ui>
```

#### formchangepassword.h

```cpp
#ifndef FORMCHANGEPASSWORD_H
#define FORMCHANGEPASSWORD_H

#include <QCryptographicHash> // 用于计算密码的哈希值
#include <QWidget>            // QWidget 是所有窗口部件的基类

// 前向声明 UI 命名空间中的 FormChangePassword 类（由 Qt Designer 生成）
namespace Ui {
class FormChangePassword;
}

/**
 * @brief FormChangePassword 是一个用于修改密码的独立窗口类
 *
 * 该窗口接收旧密码的哈希值，用户输入新密码后进行验证并发送新密码哈希值。
 */
class FormChangePassword : public QWidget {
    Q_OBJECT // 启用 Qt 的元对象系统（支持信号和槽）

  public :
    /**
     * @brief 构造函数
     * @param parent 父窗口指针，默认为 nullptr（独立窗口）
     */
    explicit FormChangePassword(QWidget* parent = nullptr);

    /// 析构函数，自动释放 UI 指针
    ~FormChangePassword();

  signals:
    /**
     * @brief 向主窗口发送新的密码哈希
     * @param strUser 用户名
     * @param baNewHash 新密码的哈希值（使用 QByteArray 存储）
     */
    void sendNewUserPassword(QString strUser, QByteArray baNewHash);

  private slots:
    /**
     * @brief 当“修改密码”按钮被点击时执行的槽函数
     * 用于检查旧密码是否正确，并发送新密码哈希。
     */
    void on_pushButtonChange_clicked();

  public slots:
    /**
     * @brief 接收旧密码哈希值的槽函数（由主窗口调用）
     * @param strUser 用户名
     * @param baOldHash 旧密码的哈希值
     */
    void recvOldUserPassword(QString strUser, QByteArray baOldHash);

  private:
    /// 指向 UI 界面对象的指针
    Ui::FormChangePassword* ui;

    /// 初始化窗口的一些默认设置（如标题、提示等）
    void init();

    /// 保存当前用户名
    QString m_strUser;

    /// 保存旧密码的哈希值，用于验证用户输入的旧密码是否正确
    QByteArray m_baOldHash;
};

#endif // FORMCHANGEPASSWORD_H
```

#### formchangepassword.cpp

```cpp
#include "formchangepassword.h"
#include "ui_formchangepassword.h"
#include <QDebug>
#include <QMessageBox>

// 构造函数：初始化 UI 并调用自定义初始化函数
FormChangePassword::FormChangePassword(QWidget* parent) : QWidget(parent), ui(new Ui::FormChangePassword) {
    ui->setupUi(this); // 设置 UI 元素（由 Qt Designer 生成）
    init();            // 自定义初始化函数
}

// 析构函数：释放 UI 指针
FormChangePassword::~FormChangePassword() {
    delete ui;
}

// 自定义初始化函数：设置界面样式和控件属性
void FormChangePassword::init() {
    // 设置窗口标题
    setWindowTitle(tr("修改用户密码"));

    // 设置三个密码框为“密码模式”，隐藏输入内容
    ui->lineEditOldPassword->setEchoMode(QLineEdit::Password);
    ui->lineEditNewPassword->setEchoMode(QLineEdit::Password);
    ui->lineEditNewPassword2->setEchoMode(QLineEdit::Password);

    // 用户名只读，防止篡改，并设置背景颜色
    ui->lineEditUser->setReadOnly(true);
    ui->lineEditUser->setStyleSheet("background-color: rgb(200,200,255);");

    // 为旧密码框设置提示信息
    ui->lineEditOldPassword->setToolTip(tr("旧密码验证成功才能修改为新密码。"));
}

// 接收主窗口传来的用户名和旧密码哈希，并显示用户名
void FormChangePassword::recvOldUserPassword(QString strUser, QByteArray baOldHash) {
    // 保存到成员变量中备用
    m_strUser = strUser;
    m_baOldHash = baOldHash;

    // 显示用户名到只读框
    ui->lineEditUser->setText(m_strUser);

    // 清空输入框内容，准备新输入
    ui->lineEditOldPassword->clear();
    ui->lineEditNewPassword->clear();
    ui->lineEditNewPassword2->clear();
}

// 点击“修改密码”按钮后的处理逻辑
void FormChangePassword::on_pushButtonChange_clicked() {
    // 获取三个密码框的输入内容（去除前后空格）
    QString strOldPassword = ui->lineEditOldPassword->text().trimmed();
    QString strNewPassword = ui->lineEditNewPassword->text().trimmed();
    QString strNewPassword2 = ui->lineEditNewPassword2->text().trimmed();

    // 检查密码框是否为空
    if (strOldPassword.isEmpty() || strNewPassword.isEmpty() || strNewPassword2.isEmpty()) {
        QMessageBox::information(this, tr("密码框检查"), tr("三个密码都不能为空。"));
        return;
    }

    // 检查两个新密码是否一致
    if (strNewPassword != strNewPassword2) {
        QMessageBox::information(this, tr("新密码检查"), tr("两个新密码不一致。"));
        return;
    }

    // 使用 SHA256 对旧密码计算哈希值
    QByteArray baOldHashCheck = QCryptographicHash::hash(strOldPassword.toUtf8(), QCryptographicHash::Sha256);
    baOldHashCheck = baOldHashCheck.toHex(); // 转成十六进制字符串方便比较

    // 验证旧密码是否正确
    if (baOldHashCheck != m_baOldHash) {
        QMessageBox::information(this, tr("旧密码检查"), tr("输入的旧密码不正确，不能修改密码。"));
        return;
    }

    // 若旧密码验证通过，则计算新密码的哈希值
    QByteArray baNewHash = QCryptographicHash::hash(strNewPassword.toUtf8(), QCryptographicHash::Sha256);
    baNewHash = baNewHash.toHex(); // 统一格式为 Hex 字符串

    // 发出信号，将新密码哈希和用户名传递回主窗口处理
    emit sendNewUserPassword(m_strUser, baNewHash);
}
```

#### mainwidget.ui

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>MainWidget</class>
 <widget class="QWidget" name="MainWidget">
  <property name="geometry">
   <rect>
    <x>0</x>
    <y>0</y>
    <width>518</width>
    <height>300</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>MainWidget</string>
  </property>
  <layout class="QVBoxLayout" name="verticalLayout_2">
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout">
     <item>
      <widget class="QLabel" name="label">
       <property name="text">
        <string>用户名</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditUser"/>
     </item>
     <item>
      <widget class="QLabel" name="label_2">
       <property name="text">
        <string>密码</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QLineEdit" name="lineEditPassword"/>
     </item>
     <item>
      <widget class="QPushButton" name="pushButtonAddUser">
       <property name="text">
        <string>添加用户</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <layout class="QHBoxLayout" name="horizontalLayout_2">
     <item>
      <widget class="QListWidget" name="listWidgetShow"/>
     </item>
     <item>
      <layout class="QVBoxLayout" name="verticalLayout">
       <item>
        <widget class="QPushButton" name="pushButtonChangePassword">
         <property name="text">
          <string>修改用户密码</string>
         </property>
        </widget>
       </item>
       <item>
        <widget class="QPushButton" name="pushButtonDelUser">
         <property name="text">
          <string>删除选定用户</string>
         </property>
        </widget>
       </item>
      </layout>
     </item>
    </layout>
   </item>
  </layout>
 </widget>
 <resources/>
 <connections/>
</ui>
```

#### mainwidget.h

```cpp
#ifndef MAINWIDGET_H
#define MAINWIDGET_H

#include "formchangepassword.h" // 子窗口类，用于修改用户密码
#include <QCryptographicHash>   // 用于生成密码的哈希值
#include <QListWidget>          // UI 中的列表控件
#include <QListWidgetItem>      // 列表中的每一项
#include <QMap>                 // 用于保存用户名与密码哈希值的映射
#include <QWidget>              // QWidget 是所有窗口部件的基类

QT_BEGIN_NAMESPACE
namespace Ui {
class MainWidget;
}
QT_END_NAMESPACE

/**
 * @brief MainWidget 是应用的主窗口类，提供用户管理界面
 *
 * 功能包括添加用户、删除用户、修改用户密码，并将用户信息存储在 QMap 中。
 */
class MainWidget : public QWidget {
    Q_OBJECT // 启用 Qt 的元对象系统（支持信号和槽）

  public :
    /**
     * @brief 构造函数
     * @param parent 父窗口指针，默认为 nullptr
     */
    MainWidget(QWidget* parent = nullptr);

    /// 析构函数，自动释放资源
    ~MainWidget();

    /**
     * @brief 刷新用户列表显示
     * 将当前 m_mapUserAndHash 中的用户显示到 QListWidget 中
     */
    void updateListShow();

  signals:
    /**
     * @brief 向子窗口发送当前用户名及旧密码哈希
     * 用于修改密码时子窗口进行旧密码验证
     */
    void sendOldUserPassword(QString strUser, QByteArray baOldHash);

  private slots:
    /**
     * @brief 添加用户按钮点击处理函数
     * 获取用户名和密码，生成哈希并存入映射表
     */
    void on_pushButtonAddUser_clicked();

    /**
     * @brief 修改密码按钮点击处理函数
     * 弹出子窗口并发送当前用户信息
     */
    void on_pushButtonChangePassword_clicked();

    /**
     * @brief 删除用户按钮点击处理函数
     * 从映射表中移除选中的用户
     */
    void on_pushButtonDelUser_clicked();

  public slots:
    /**
     * @brief 接收来自子窗口的新密码哈希
     * @param strUser 用户名
     * @param baNewHash 新的密码哈希值
     * 替换 m_mapUserAndHash 中该用户的密码
     */
    void recvNewUserPassword(QString strUser, QByteArray baNewHash);

  private:
    /// UI 指针，管理由 Qt Designer 创建的界面元素
    Ui::MainWidget* ui;

    /// 保存所有用户名和其对应密码哈希的映射表
    QMap<QString, QByteArray> m_mapUserAndHash;

    /// 指向修改密码子窗口的指针
    FormChangePassword* m_pFormChild;

    /**
     * @brief 初始化主窗口设置
     * 包括界面初始化、信号槽连接等
     */
    void init();
};

#endif // MAINWIDGET_H
```

#### mainwidget.cpp

```cpp
#include "mainwidget.h"
#include "./ui_mainwidget.h"
#include <QDebug>
#include <QMessageBox>

// 构造函数：初始化 UI 并调用 init 函数设置界面和子窗口
MainWidget::MainWidget(QWidget* parent) : QWidget(parent), ui(new Ui::MainWidget) {
    ui->setupUi(this); // 加载 UI 界面
    init();            // 初始化窗口、子窗口、信号槽等
}

// 析构函数：释放资源
MainWidget::~MainWidget() {
    delete m_pFormChild; // 释放子窗口对象
    m_pFormChild = nullptr;
    delete ui; // 释放 UI 对象
}

// 初始化函数：设置窗口标题、控件属性并建立信号槽连接
void MainWidget::init() {
    // 设置主窗口标题
    setWindowTitle(tr("用户名密码管理工具"));

    // 设置密码输入框为密码模式，输入内容以 * 显示
    ui->lineEditPassword->setEchoMode(QLineEdit::Password);

    // 初始化子窗口指针
    m_pFormChild = nullptr;
    // 创建子窗口，parent 设为 nullptr 防止父窗口控制其生命周期
    m_pFormChild = new FormChangePassword(nullptr);

    // 连接主窗口 -> 子窗口的信号槽：传递用户名和旧密码哈希
    connect(this, &MainWidget::sendOldUserPassword, m_pFormChild, &FormChangePassword::recvOldUserPassword);

    // 连接子窗口 -> 主窗口的信号槽：接收修改后的新密码哈希
    connect(m_pFormChild, &FormChangePassword::sendNewUserPassword, this, &MainWidget::recvNewUserPassword);
}

// 刷新用户列表显示：根据当前的用户哈希表刷新列表控件
void MainWidget::updateListShow() {
    ui->listWidgetShow->clear(); // 清空原有列表项

    // 获取所有用户名（即 QMap 的 key 列表）
    QList<QString> listKeys = m_mapUserAndHash.keys();
    int nCount = listKeys.count();

    // 遍历每个用户，将用户名和哈希拼接显示到列表中
    for (int i = 0; i < nCount; i++) {
        QString curKey = listKeys[i];
        QString strTemp = curKey + QString("\t") + m_mapUserAndHash[curKey];
        ui->listWidgetShow->addItem(strTemp);
    }
}

// 添加用户按钮点击处理函数
void MainWidget::on_pushButtonAddUser_clicked() {
    // 获取用户输入的用户名和密码
    QString strNewUser = ui->lineEditUser->text().trimmed();
    QString strPassword = ui->lineEditPassword->text().trimmed();

    // 检查用户名或密码是否为空
    if (strNewUser.isEmpty() || strPassword.isEmpty()) {
        QMessageBox::information(this, tr("用户名密码检查"), tr("用户名或密码为空，不能添加。"));
        return;
    }

    // 检查用户名是否已存在
    if (m_mapUserAndHash.contains(strNewUser)) {
        QMessageBox::information(this, tr("用户名检查"), tr("已存在该用户名，不能再新增同名。"));
        return;
    }

    // 生成密码哈希（使用 SHA256）
    QByteArray baNewHash = QCryptographicHash::hash(strPassword.toUtf8(), QCryptographicHash::Sha256);
    baNewHash = baNewHash.toHex(); // 转换为十六进制字符串方便显示与存储

    // 添加到用户-哈希映射表中
    m_mapUserAndHash.insert(strNewUser, baNewHash);

    // 刷新用户列表显示
    updateListShow();
}

// 修改密码按钮点击处理函数
void MainWidget::on_pushButtonChangePassword_clicked() {
    int curIndex = ui->listWidgetShow->currentRow(); // 获取当前选中行
    if (curIndex < 0) return;                        // 没有选中任何行

    // 获取当前条目
    QListWidgetItem* curItem = ui->listWidgetShow->item(curIndex);

    // 如果被选中，提取用户名并发送旧密码哈希到子窗口
    if (curItem->isSelected()) {
        QString curLine = curItem->text();             // 获取文本："用户名\t密码哈希"
        QStringList curKeyValue = curLine.split('\t'); // 拆分成用户名和哈希
        QString strUser = curKeyValue[0];
        QByteArray baOldHash = m_mapUserAndHash[strUser];

        // 发出信号，发送用户名和旧密码哈希给子窗口
        emit sendOldUserPassword(strUser, baOldHash);

        // 显示修改密码的子窗口
        m_pFormChild->show();

        // 若子窗口被最小化，恢复原尺寸显示
        if (m_pFormChild->isMinimized()) m_pFormChild->showNormal();

        // 子窗口置顶
        m_pFormChild->raise();
    }
}

// 删除用户按钮点击处理函数
void MainWidget::on_pushButtonDelUser_clicked() {
    int curIndex = ui->listWidgetShow->currentRow(); // 获取当前行索引
    if (curIndex < 0) return;

    QListWidgetItem* curItem = ui->listWidgetShow->item(curIndex);

    if (curItem->isSelected()) {
        QString curLine = curItem->text(); // "用户名\t哈希"
        QStringList curKeyValue = curLine.split('\t');
        QString strUser = curKeyValue[0];

        // 从 map 中删除该用户
        m_mapUserAndHash.remove(strUser);

        // 从 UI 列表中删除条目
        ui->listWidgetShow->takeItem(curIndex); // 先从列表中拿出来
        delete curItem;                         // 然后释放内存
        curItem = nullptr;
    }
}

// 接收子窗口返回的新密码哈希，并更新用户哈希表
void MainWidget::recvNewUserPassword(QString strUser, QByteArray baNewHash) {
    m_mapUserAndHash[strUser] = baNewHash; // 更新哈希值
    updateListShow();                      // 刷新列表显示

    m_pFormChild->hide();                                                 // 隐藏子窗口
    QMessageBox::information(this, tr("修改密码"), tr("修改密码成功。")); // 弹窗提示
}
```

### 集成已有窗口类方式

把文件属性的例子里面的三个文件 tabpreview.cpp、tabpreview.h、tabpreview.ui 复制粘贴到本示例 fileattrshow 项目文件夹中。

#### tabpreview.ui

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>TabPreview</class>
 <widget class="QWidget" name="TabPreview">
  <property name="geometry">
   <rect>
    <x>0</x>
    <y>0</y>
    <width>578</width>
    <height>415</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>Form</string>
  </property>
  <layout class="QHBoxLayout" name="horizontalLayout">
   <item>
    <layout class="QVBoxLayout" name="verticalLayout_4">
     <item>
      <widget class="QPushButton" name="pushButtonTextPreview">
       <property name="sizePolicy">
        <sizepolicy hsizetype="Minimum" vsizetype="Expanding">
         <horstretch>0</horstretch>
         <verstretch>0</verstretch>
        </sizepolicy>
       </property>
       <property name="maximumSize">
        <size>
         <width>52</width>
         <height>16777215</height>
        </size>
       </property>
       <property name="text">
        <string>文
本
预
览</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="pushButtonImagePreview">
       <property name="sizePolicy">
        <sizepolicy hsizetype="Minimum" vsizetype="Expanding">
         <horstretch>0</horstretch>
         <verstretch>0</verstretch>
        </sizepolicy>
       </property>
       <property name="maximumSize">
        <size>
         <width>52</width>
         <height>16777215</height>
        </size>
       </property>
       <property name="text">
        <string>图
像
预
览</string>
       </property>
      </widget>
     </item>
     <item>
      <widget class="QPushButton" name="pushButtonBytePreview">
       <property name="sizePolicy">
        <sizepolicy hsizetype="Minimum" vsizetype="Expanding">
         <horstretch>0</horstretch>
         <verstretch>0</verstretch>
        </sizepolicy>
       </property>
       <property name="maximumSize">
        <size>
         <width>52</width>
         <height>16777215</height>
        </size>
       </property>
       <property name="text">
        <string>字
节
预
览</string>
       </property>
      </widget>
     </item>
    </layout>
   </item>
   <item>
    <widget class="QStackedWidget" name="stackedWidget">
     <property name="currentIndex">
      <number>0</number>
     </property>
     <widget class="QWidget" name="pageTextPreview">
      <layout class="QVBoxLayout" name="verticalLayout">
       <property name="leftMargin">
        <number>0</number>
       </property>
       <property name="topMargin">
        <number>0</number>
       </property>
       <property name="rightMargin">
        <number>0</number>
       </property>
       <property name="bottomMargin">
        <number>0</number>
       </property>
       <item>
        <widget class="QTextBrowser" name="textBrowserText"/>
       </item>
      </layout>
     </widget>
     <widget class="QWidget" name="pageImagePreview">
      <layout class="QVBoxLayout" name="verticalLayout_2">
       <property name="leftMargin">
        <number>0</number>
       </property>
       <property name="topMargin">
        <number>0</number>
       </property>
       <property name="rightMargin">
        <number>0</number>
       </property>
       <property name="bottomMargin">
        <number>0</number>
       </property>
       <item>
        <widget class="QLabel" name="labelImagePreview">
         <property name="text">
          <string>图像预览区域</string>
         </property>
         <property name="alignment">
          <set>Qt::AlignmentFlag::AlignCenter</set>
         </property>
        </widget>
       </item>
      </layout>
     </widget>
     <widget class="QWidget" name="pageBytePreview">
      <layout class="QVBoxLayout" name="verticalLayout_3">
       <property name="leftMargin">
        <number>0</number>
       </property>
       <property name="topMargin">
        <number>0</number>
       </property>
       <property name="rightMargin">
        <number>0</number>
       </property>
       <property name="bottomMargin">
        <number>0</number>
       </property>
       <item>
        <widget class="QTextBrowser" name="textBrowserByte"/>
       </item>
      </layout>
     </widget>
    </widget>
   </item>
  </layout>
 </widget>
 <resources/>
 <connections/>
</ui>
```

#### tabpreview.h

```cpp
#ifndef TABPREVIEW_H
#define TABPREVIEW_H

#include <QButtonGroup>
#include <QFile>
#include <QPixmap>
#include <QWidget>

namespace Ui {
class TabPreview;
}

class TabPreview : public QWidget {
    Q_OBJECT

  public:
    explicit TabPreview(QWidget* parent = nullptr); // 构造函数，支持传入父窗口指针，默认空指针
    ~TabPreview();                                  // 析构函数，释放资源
    void initControls();                            // 初始化控件及界面设置

  public slots:
    // 槽函数，响应文件名改变信号，更新预览内容
    void onFileNameChanged(const QString& fileName);

  private:
    Ui::TabPreview* ui;         // 指向 UI 界面对象的指针，由 Qt Designer 生成的类
    QString m_strFileName;      // 用于保存当前预览的文件名
    QButtonGroup m_buttonGroup; // 按钮分组，管理多个互斥的按钮
    QPixmap m_image;            // 用于保存当前加载的预览图像
};

#endif // TABPREVIEW_H
```

#### tabpreview.cpp

```cpp
#include "tabpreview.h"
#include "ui_tabpreview.h"

TabPreview::TabPreview(QWidget* parent) : QWidget(parent), ui(new Ui::TabPreview) {
    ui->setupUi(this);
    initControls(); // 初始化控件，设置按钮组、样式等
}

TabPreview::~TabPreview() {
    delete ui; // 释放 UI 指针资源
}

void TabPreview::initControls() {
    // 设置三个按钮为可切换状态（类似复选框的选中与未选中状态）
    ui->pushButtonTextPreview->setCheckable(true);
    ui->pushButtonImagePreview->setCheckable(true);
    ui->pushButtonBytePreview->setCheckable(true);

    // 按钮分组，分组内按钮互斥（只能选中一个）
    // 为每个按钮分配唯一 ID（0, 1, 2）
    m_buttonGroup.addButton(ui->pushButtonTextPreview, 0);
    m_buttonGroup.addButton(ui->pushButtonImagePreview, 1);
    m_buttonGroup.addButton(ui->pushButtonBytePreview, 2);

    // 绑定按钮分组的点击信号到堆栈控件，切换不同的页面
    connect(&m_buttonGroup, &QButtonGroup::idClicked, ui->stackedWidget, &QStackedWidget::setCurrentIndex);
    // 设置所有被选中按钮的样式，背景色为黄色
    this->setStyleSheet("QPushButton:checked { background-color: yellow }");

    // 设置字节浏览区背景颜色为浅蓝色
    ui->textBrowserByte->setStyleSheet("background-color: #AAEEFF");

    // 设置图片预览标签背景颜色为浅灰色
    ui->labelImagePreview->setStyleSheet("background-color: #E0E0E0");
}

void TabPreview::onFileNameChanged(const QString& fileName) {
    m_strFileName = fileName;
    // 尝试将文件作为图片加载
    bool isImage = m_image.load(m_strFileName);

    if (isImage) {
        // 是图片时，清空文字提示，显示图片
        ui->labelImagePreview->setText("");
        ui->labelImagePreview->setPixmap(m_image);
    } else {
        // 不是图片时，清空显示的图片，显示提示文字
        m_image = QPixmap(); // 清空图片
        ui->labelImagePreview->setPixmap(m_image);
        ui->labelImagePreview->setText(tr("不是支持的图片，无法以图片预览。"));
    }

    // 打开文件，读取前200字节做文本和十六进制预览
    QFile fileIn(m_strFileName);
    if (!fileIn.open(QIODevice::ReadOnly)) {
        // 无法打开文件，打印调试信息
        qDebug() << tr("文件无法打开：") << m_strFileName;
    } else {
        QByteArray baData = fileIn.read(200); // 读取前200字节
        // 转为本地编码的文本显示
        QString strText = QString::fromLocal8Bit(baData);
        ui->textBrowserText->setText(strText);

        // 转为大写十六进制字符串显示
        QString strHex = baData.toHex().toUpper();
        ui->textBrowserByte->setText(strHex);
    }

    // 根据文件类型，默认切换到对应预览页
    if (isImage) {
        // 图片文件，切换到图片预览按钮（触发 clicked 信号）
        ui->pushButtonImagePreview->click();
    } else {
        // 非图片文件
        if (m_strFileName.endsWith(".txt", Qt::CaseInsensitive) || m_strFileName.endsWith(".h", Qt::CaseInsensitive) || m_strFileName.endsWith(".cpp", Qt::CaseInsensitive) ||
            m_strFileName.endsWith(".c", Qt::CaseInsensitive)) {
            // 纯文本相关文件，切换到文本预览页
            ui->pushButtonTextPreview->click();
        } else {
            // 其他文件，切换到字节预览页
            ui->pushButtonBytePreview->click();
        }
    }
}
```

#### fileattrwidget.ui

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>FileAttrWidget</class>
 <widget class="QWidget" name="FileAttrWidget">
  <property name="geometry">
   <rect>
    <x>0</x>
    <y>0</y>
    <width>450</width>
    <height>276</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>FileAttrWidget</string>
  </property>
  <layout class="QGridLayout" name="gridLayout">
   <item row="0" column="0">
    <widget class="QLabel" name="label">
     <property name="text">
      <string>文件全名</string>
     </property>
    </widget>
   </item>
   <item row="0" column="1" colspan="2">
    <widget class="QLineEdit" name="lineEditFullName"/>
   </item>
   <item row="0" column="3">
    <widget class="QPushButton" name="pushButtonSelectFile">
     <property name="text">
      <string>选择文件</string>
     </property>
    </widget>
   </item>
   <item row="1" column="0">
    <widget class="QLabel" name="label_2">
     <property name="text">
      <string>文件短名</string>
     </property>
    </widget>
   </item>
   <item row="1" column="1" colspan="2">
    <widget class="QLineEdit" name="lineEditShortName"/>
   </item>
   <item row="1" column="3">
    <widget class="QPushButton" name="pushButtonPreview">
     <property name="text">
      <string>预览文件</string>
     </property>
    </widget>
   </item>
   <item row="2" column="0">
    <widget class="QLabel" name="label_3">
     <property name="text">
      <string>文件大小</string>
     </property>
    </widget>
   </item>
   <item row="2" column="2">
    <widget class="QLineEdit" name="lineEditFileSize"/>
   </item>
   <item row="3" column="0">
    <widget class="QLabel" name="label_6">
     <property name="text">
      <string>创建时间</string>
     </property>
    </widget>
   </item>
   <item row="3" column="2">
    <widget class="QLineEdit" name="lineEditTimeCreated"/>
   </item>
   <item row="4" column="0">
    <widget class="QLabel" name="label_4">
     <property name="text">
      <string>访问时间</string>
     </property>
    </widget>
   </item>
   <item row="4" column="2">
    <widget class="QLineEdit" name="lineEditTimeRead"/>
   </item>
   <item row="5" column="0" colspan="2">
    <widget class="QLabel" name="label_5">
     <property name="text">
      <string>修改时间</string>
     </property>
    </widget>
   </item>
   <item row="5" column="2">
    <widget class="QLineEdit" name="lineEditTimeModified"/>
   </item>
  </layout>
 </widget>
 <resources/>
 <connections/>
</ui>
```

#### fileattrwidget.h

```cpp
#ifndef FILEATTRWIDGET_H
#define FILEATTRWIDGET_H

#include "tabpreview.h" // 自定义的预览窗口类
#include <QFile>        // 用于文件操作
#include <QFileDialog>  // 用于打开文件对话框
#include <QFileInfo>    // 提供文件信息类
#include <QWidget>      // QWidget 基类

QT_BEGIN_NAMESPACE
namespace Ui {
class FileAttrWidget; // 前向声明 UI 类（由 Qt Designer 自动生成）
}
QT_END_NAMESPACE

// 文件属性展示与操作的主窗口类，继承自 QWidget
class FileAttrWidget : public QWidget {
    Q_OBJECT

  public:
    // 构造函数，支持父窗口传入
    FileAttrWidget(QWidget* parent = nullptr);

    // 析构函数，负责资源释放
    ~FileAttrWidget();

  signals:
    // 当用户选择了新文件，文件名发生变化时发出该信号
    void fileNameChanged(const QString& fileName);

  private slots:
    // 点击“选择文件”按钮的槽函数，弹出文件选择对话框
    void on_pushButtonSelectFile_clicked();

    // 点击“预览”按钮的槽函数，打开预览窗口
    void on_pushButtonPreview_clicked();

  private:
    Ui::FileAttrWidget* ui; // UI 指针，管理界面控件（由 Qt Designer 自动生成）

    TabPreview* m_pPreviewWnd; // 文件预览子窗口指针

    QString m_strFileName; // 当前选择的文件全路径名

    QFileInfo m_fileInfo; // 文件信息对象，获取如大小、时间等属性

    void init(); // 初始化函数，负责界面设置、信号连接等
};

#endif // FILEATTRWIDGET_H
```

#### fileattrwidget.cpp

```cpp
#include "fileattrwidget.h"
#include "./ui_fileattrwidget.h"
#include <QDateTime>
#include <QDebug>
#include <QMessageBox>

// 构造函数，初始化 UI 和界面状态
FileAttrWidget::FileAttrWidget(QWidget* parent) : QWidget(parent), ui(new Ui::FileAttrWidget) {
    ui->setupUi(this); // 初始化 UI 界面控件（Qt Designer 生成的界面）
    init();            // 执行初始化操作
}

// 析构函数，释放资源
FileAttrWidget::~FileAttrWidget() {
    delete m_pPreviewWnd; // 释放预览窗口对象
    m_pPreviewWnd = nullptr;
    delete ui; // 释放 UI 界面对象
}

// 初始化函数，设置控件属性、创建子窗口、连接信号槽
void FileAttrWidget::init() {
    // 将所有信息展示框设置为只读，防止用户修改
    ui->lineEditFullName->setReadOnly(true);
    ui->lineEditShortName->setReadOnly(true);
    ui->lineEditFileSize->setReadOnly(true);
    ui->lineEditTimeCreated->setReadOnly(true);
    ui->lineEditTimeRead->setReadOnly(true);
    ui->lineEditTimeModified->setReadOnly(true);

    // 初始化预览窗口指针
    m_pPreviewWnd = nullptr;
    m_pPreviewWnd = new TabPreview(nullptr); // 创建预览窗口实例

    // 设置预览窗口标题
    m_pPreviewWnd->setWindowTitle(tr("预览文件"));

    // 当文件名发生变化时，将信号连接到预览窗口的槽函数以更新内容
    connect(this, &FileAttrWidget::fileNameChanged, m_pPreviewWnd, &TabPreview::onFileNameChanged);
}

// “选择文件”按钮的槽函数
void FileAttrWidget::on_pushButtonSelectFile_clicked() {
    // 打开文件选择对话框，允许选择任意文件
    QString strName = QFileDialog::getOpenFileName(this, tr("选择文件"), tr(""), tr("All files(*)"));

    strName = strName.trimmed();   // 去掉前后空格
    if (strName.isEmpty()) return; // 用户未选择文件直接返回

    // 记录选中的文件路径
    m_strFileName = strName;

    // 使用 QFileInfo 提取文件属性
    m_fileInfo.setFile(m_strFileName);

    // 获取文件大小（字节）
    qint64 nFileSize = m_fileInfo.size();

    // 设置全路径、短文件名、文件大小信息
    ui->lineEditFullName->setText(m_strFileName);
    ui->lineEditShortName->setText(m_fileInfo.fileName());
    ui->lineEditFileSize->setText(tr("%1 字节").arg(nFileSize));

    // 获取文件创建、读取、修改时间，并格式化为字符串
    QString strTimeCreated = m_fileInfo.birthTime().toString("yyyy-MM-dd  HH:mm:ss");
    QString strTimeRead = m_fileInfo.lastRead().toString("yyyy-MM-dd  HH:mm:ss");
    QString strTimeModified = m_fileInfo.lastModified().toString("yyyy-MM-dd  HH:mm:ss");

    // 将时间信息设置到对应控件中
    ui->lineEditTimeCreated->setText(strTimeCreated);
    ui->lineEditTimeRead->setText(strTimeRead);
    ui->lineEditTimeModified->setText(strTimeModified);

    // 发送文件名变化信号，通知预览窗口更新
    emit fileNameChanged(m_strFileName);
}

// “预览”按钮的槽函数
void FileAttrWidget::on_pushButtonPreview_clicked() {
    if (m_strFileName.isEmpty()) return; // 如果未选择文件则不操作

    // 如果预览窗口已显示，先隐藏
    if (m_pPreviewWnd->isVisible()) {
        m_pPreviewWnd->hide();
    }

    // 设置预览窗口为应用程序级模态（阻塞其他窗口操作）
    m_pPreviewWnd->setWindowModality(Qt::ApplicationModal);

    // 显示预览窗口
    m_pPreviewWnd->show();
}
```

