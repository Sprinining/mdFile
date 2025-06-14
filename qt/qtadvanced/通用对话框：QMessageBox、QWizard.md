## 通用对话框：QMessageBox、QWizard

### QMessageBox

`QMessageBox` 是 Qt 框架中用于显示标准对话框（提示信息、警告、错误、询问等）的类，属于 Qt Widgets 模块。它是一个简单但强大的 UI 元素，常用于向用户展示信息或要求用户做出选择。

#### 基本用法

`QMessageBox` 的常用静态方法包括：

```cpp
QMessageBox::information(parent, title, message);
QMessageBox::warning(parent, title, message);
QMessageBox::critical(parent, title, message);
QMessageBox::question(parent, title, message);
```

示例：

```cpp
QMessageBox::information(this, "提示", "操作成功！");
QMessageBox::warning(this, "警告", "操作可能导致数据丢失！");
QMessageBox::critical(this, "错误", "无法连接服务器！");
QMessageBox::question(this, "确认", "确定要退出吗？");
```

#### 获取用户选择

`QMessageBox::question` 可以用于获取用户是否确认操作：

```cpp
QMessageBox::StandardButton reply;
reply = QMessageBox::question(this, "退出", "确定要退出吗？",
                               QMessageBox::Yes | QMessageBox::No);
if (reply == QMessageBox::Yes) {
    QApplication::quit();
}
```

#### 自定义按钮和图标

可以使用 `QMessageBox` 类构造函数来自定义：

```cpp
QMessageBox msgBox;
msgBox.setWindowTitle("自定义对话框");
msgBox.setText("是否保存更改？");
msgBox.setIcon(QMessageBox::Question);
msgBox.setStandardButtons(QMessageBox::Yes | QMessageBox::No | QMessageBox::Cancel);
msgBox.setDefaultButton(QMessageBox::Yes);
int ret = msgBox.exec();

switch (ret) {
    case QMessageBox::Yes:
        // 处理保存
        break;
    case QMessageBox::No:
        // 不保存
        break;
    case QMessageBox::Cancel:
        // 取消操作
        break;
}
```

#### QMessageBox 的常用方法

| 方法                   | 功能                                                       |
| ---------------------- | ---------------------------------------------------------- |
| `setText()`            | 设置主信息文本                                             |
| `setInformativeText()` | 设置附加信息（副标题）                                     |
| `setDetailedText()`    | 设置详细信息（点击展开）                                   |
| `setIcon()`            | 设置图标：Information、Warning、Critical、Question、NoIcon |
| `setStandardButtons()` | 设置标准按钮（Yes, No, Cancel, Ok 等）                     |
| `setDefaultButton()`   | 设置默认按钮                                               |
| `exec()`               | 模态运行对话框，等待用户响应                               |
| `show()`               | 非模态显示（不常用于 QMessageBox）                         |

#### 图标枚举

| 图标枚举值                 | 说明     | UI 表现               |
| -------------------------- | -------- | --------------------- |
| `QMessageBox::NoIcon`      | 无图标   | 无特殊图标            |
| `QMessageBox::Information` | 信息提示 | 蓝色圆形带 “i” 的图标 |
| `QMessageBox::Warning`     | 警告     | 黄色三角形带感叹号    |
| `QMessageBox::Critical`    | 错误     | 红色圆圈带叉号        |
| `QMessageBox::Question`    | 询问     | 蓝色问号              |

#### 按钮枚举

| 按钮枚举值             | 按钮文本（默认）     | 用途                     |
| ---------------------- | -------------------- | ------------------------ |
| `QMessageBox::Ok`      | 确定（OK）           | 一般确认操作             |
| `QMessageBox::Cancel`  | 取消（Cancel）       | 取消当前操作             |
| `QMessageBox::Yes`     | 是（Yes）            | 表示确认                 |
| `QMessageBox::No`      | 否（No）             | 表示拒绝                 |
| `QMessageBox::Abort`   | 放弃（Abort）        | 表示放弃操作（较少使用） |
| `QMessageBox::Retry`   | 重试（Retry）        | 表示重试操作             |
| `QMessageBox::Ignore`  | 忽略（Ignore）       | 表示忽略错误             |
| `QMessageBox::Close`   | 关闭（Close）        | 关闭窗口或对话框         |
| `QMessageBox::Help`    | 帮助（Help）         | 提供帮助信息             |
| `QMessageBox::Apply`   | 应用（Apply）        | 应用更改但不关闭窗口     |
| `QMessageBox::Reset`   | 重置（Reset）        | 恢复默认设置             |
| `QMessageBox::YesAll`  | 全部是（Yes to All） | 批量确认                 |
| `QMessageBox::NoAll`   | 全部否（No to All）  | 批量拒绝                 |
| `QMessageBox::Save`    | 保存（Save）         | 保存文件或数据           |
| `QMessageBox::Discard` | 放弃（Discard）      | 放弃未保存的更改         |

多个按钮可以使用 `|` 运算符组合，例如：

```cpp
QMessageBox::Yes | QMessageBox::No | QMessageBox::Cancel
```

#### 高级用法（示例）

```cpp
QMessageBox box;
box.setWindowTitle("文件冲突");
box.setText("文件已存在");
box.setInformativeText("是否覆盖已有文件？");
box.setDetailedText("文件路径：/home/user/file.txt");
box.setStandardButtons(QMessageBox::Yes | QMessageBox::No);
box.setDefaultButton(QMessageBox::No);
box.setIcon(QMessageBox::Warning);
int ret = box.exec();
```

### QWizard

`QWizard` 是 Qt 提供的一个 **向导式对话框**组件，适合用来引导用户完成多步操作，例如安装程序、配置引导等。它内部是多个页面（`QWizardPage`）的集合，按步骤导航，自动处理“下一步”“上一步”“完成”等按钮逻辑。

#### 基本结构

一个 `QWizard` 由多个 `QWizardPage` 组成：

```cpp
QWizard wizard;
wizard.addPage(new IntroPage());
wizard.addPage(new SettingsPage());
wizard.addPage(new ConclusionPage());
wizard.setWindowTitle("向导示例");
wizard.exec();
```

#### QWizardPage 简单继承

```cpp
class IntroPage : public QWizardPage {
public:
    IntroPage(QWidget *parent = nullptr) : QWizardPage(parent) {
        setTitle("欢迎");
        QLabel *label = new QLabel("欢迎使用设置向导！");
        QVBoxLayout *layout = new QVBoxLayout;
        layout->addWidget(label);
        setLayout(layout);
    }
};
```

#### QWizard 常用方法

| 方法                            | 说明                              |
| ------------------------------- | --------------------------------- |
| `addPage(QWizardPage*)`         | 添加页面                          |
| `setPage(int id, QWizardPage*)` | 设置指定 ID 页                    |
| `setStartId(int id)`            | 设置起始页面 ID                   |
| `setWindowTitle(QString)`       | 设置窗口标题                      |
| `exec()` / `show()`             | 运行向导                          |
| `next()` / `back()`             | 手动跳转下一页/上一页             |
| `currentId()` / `currentPage()` | 当前页信息                        |
| `button(QWizard::Button)`       | 获取某个按钮（比如 Finish、Next） |

#### QWizardPage 常用方法

| 方法                   | 说明                                        |
| ---------------------- | ------------------------------------------- |
| `setTitle(QString)`    | 设置页面标题                                |
| `setSubTitle(QString)` | 设置副标题                                  |
| `isComplete()`         | 页面是否已完成（会影响“下一步”按钮）        |
| `registerField()`      | 注册字段，用于数据传递                      |
| `initializePage()`     | 页面初始化时调用                            |
| `validatePage()`       | 点击“下一步”时触发，返回 `false` 可阻止切换 |

#### 页面间传值：`registerField()`

页面字段可以共享，便于数据流动：

```cpp
QLineEdit *nameLineEdit = new QLineEdit;
registerField("name*", nameLineEdit); // * 表示该字段必须填写
```

在别的页面中访问：

```cpp
QString name = field("name").toString();
```

#### 向导按钮（`QWizard::WizardButton` 枚举）

| 枚举值                     | 描述       |
| -------------------------- | ---------- |
| `QWizard::BackButton`      | 返回按钮   |
| `QWizard::NextButton`      | 下一步按钮 |
| `QWizard::FinishButton`    | 完成按钮   |
| `QWizard::CancelButton`    | 取消按钮   |
| `QWizard::HelpButton`      | 帮助按钮   |
| `QWizard::CustomButton1~3` | 自定义按钮 |

获取或设置按钮文本：

```cpp
wizard.setButtonText(QWizard::FinishButton, "完成");
```

#### 向导样式（`QWizard::WizardStyle` 枚举）

| 样式枚举                | 描述                         |
| ----------------------- | ---------------------------- |
| `QWizard::ClassicStyle` | 经典风格                     |
| `QWizard::ModernStyle`  | 现代风格（默认）             |
| `QWizard::MacStyle`     | macOS 风格                   |
| `QWizard::AeroStyle`    | Windows Vista 风格（需支持） |

```cpp
wizard.setWizardStyle(QWizard::ModernStyle);
```

#### 页面跳转控制

可以通过重载 `QWizardPage::nextId()` 决定下一页逻辑跳转：

```cpp
int IntroPage::nextId() const override {
    if (someCondition)
        return Page_Advanced;
    else
        return Page_Simple;
}
```

#### 示例小程序

```cpp
class IntroPage : public QWizardPage {
public:
    IntroPage() {
        setTitle("欢迎");
        setSubTitle("本向导将引导你完成设置过程");
        QLabel *label = new QLabel("请输入你的姓名：");
        QLineEdit *lineEdit = new QLineEdit;
        registerField("username*", lineEdit);
        QVBoxLayout *layout = new QVBoxLayout;
        layout->addWidget(label);
        layout->addWidget(lineEdit);
        setLayout(layout);
    }
};

class FinalPage : public QWizardPage {
public:
    FinalPage() {
        setTitle("完成");
        QLabel *label = new QLabel("设置完成，点击完成退出。");
        QVBoxLayout *layout = new QVBoxLayout;
        layout->addWidget(label);
        setLayout(layout);
    }

    void initializePage() override {
        QString name = field("username").toString();
        qDebug() << "用户输入的名字是：" << name;
    }
};

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    QWizard wizard;
    wizard.setWindowTitle("设置向导");

    wizard.addPage(new IntroPage);
    wizard.addPage(new FinalPage);

    wizard.setWizardStyle(QWizard::ModernStyle);
    return wizard.exec();
}
```

### 示例：引导页

#### widget.ui

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>Widget</class>
 <widget class="QWidget" name="Widget">
  <layout class="QVBoxLayout" name="verticalLayout">
   <item>
    <widget class="QPushButton" name="btnMessageBox">
     <property name="text">
      <string>显示 QMessageBox</string>
     </property>
    </widget>
   </item>
   <item>
    <widget class="QPushButton" name="btnWizard">
     <property name="text">
      <string>启动 QWizard</string>
     </property>
    </widget>
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
namespace Ui { class Widget; }
QT_END_NAMESPACE

class Widget : public QWidget {
    Q_OBJECT

public:
    Widget(QWidget *parent = nullptr);
    ~Widget();

private slots:
    void showMessageBox();
    void showWizard();

private:
    Ui::Widget *ui;
};

#endif // WIDGET_H
```

#### widget.cpp

```cpp
#include "widget.h"
#include "finalpage.h" // 自定义 QWizardPage 子类：完成页
#include "ui_widget.h"
#include "userinfopage.h" // 自定义 QWizardPage 子类：用户信息页

#include <QLabel>
#include <QLineEdit>
#include <QMessageBox>
#include <QVBoxLayout>
#include <QWizard>
#include <QWizardPage>

Widget::Widget(QWidget* parent) : QWidget(parent), ui(new Ui::Widget) {
    ui->setupUi(this); // 加载 UI 文件中的控件和布局

    // 绑定按钮点击信号到对应槽函数
    connect(ui->btnMessageBox, &QPushButton::clicked, this, &Widget::showMessageBox);
    connect(ui->btnWizard, &QPushButton::clicked, this, &Widget::showWizard);
}

Widget::~Widget() {
    delete ui; // 释放 UI 指针，防止内存泄漏
}

// 演示 QMessageBox 的用法
void Widget::showMessageBox() {
    QMessageBox msgBox;

    msgBox.setWindowTitle("QMessageBox 示例");     // 设置对话框标题
    msgBox.setText("是否确认继续操作？");          // 主文本
    msgBox.setInformativeText("此操作不可撤销！"); // 补充信息文本
    msgBox.setIcon(QMessageBox::Warning);          // 设置警告图标

    // 设置标准按钮：Yes 和 No
    msgBox.setStandardButtons(QMessageBox::Yes | QMessageBox::No);

    msgBox.setDefaultButton(QMessageBox::No); // 默认选中 No 按钮

    int ret = msgBox.exec(); // 以模态方式显示消息框，阻塞直到用户选择

    // 根据用户选择显示不同的信息提示
    if (ret == QMessageBox::Yes) {
        QMessageBox::information(this, "结果", "你选择了是");
    } else {
        QMessageBox::information(this, "结果", "你选择了否");
    }
}

// 演示 QWizard 的用法
void Widget::showWizard() {
    QWizard wizard;
    wizard.setWindowTitle("QWizard 示例");       // 设置向导窗口标题
    wizard.setWizardStyle(QWizard::ModernStyle); // 设置向导风格（现代）

    // 添加页面：必须是 QWizardPage 的子类实例
    wizard.addPage(new UserInfoPage); // 用户信息输入页
    wizard.addPage(new FinalPage);    // 完成提示页

    wizard.exec(); // 以模态方式启动向导，用户完成或取消时返回
}
```

#### userinfopage.h

```cpp
#ifndef USERINFO_PAGE_H
#define USERINFO_PAGE_H

#include <QLineEdit>
#include <QWizardPage>

// UserInfoPage 继承自 QWizardPage，表示向导中的“用户信息”页面
class UserInfoPage : public QWizardPage {
    Q_OBJECT
  public:
    // 构造函数，允许传入父窗口指针，默认 nullptr
    explicit UserInfoPage(QWidget* parent = nullptr);

  private:
    QLineEdit* nameEdit; // 用于输入用户名的文本编辑控件
};

#endif // USERINFO_PAGE_H
```

#### userinfopage.cpp

```cpp
#include "userinfopage.h"
#include <QLabel>
#include <QVBoxLayout>

UserInfoPage::UserInfoPage(QWidget *parent) : QWizardPage(parent) {
    setTitle("用户信息");                      // 设置该向导页的标题，显示在向导窗口顶部

    QLabel *label = new QLabel("请输入你的名字：");  // 提示用户输入的文本标签
    nameEdit = new QLineEdit;                 // 创建文本编辑框供用户输入名字

    // 注册字段，允许通过 QWizard 的 field() 方法访问输入内容
    // 字段名为 "username*"，'*' 表示该字段是必填项，向导会强制要求用户填写
    registerField("username*", nameEdit);

    // 创建垂直布局，将标签和文本框垂直排列
    QVBoxLayout *layout = new QVBoxLayout;
    layout->addWidget(label);
    layout->addWidget(nameEdit);

    // 设置页面布局，使控件显示在窗口中
    setLayout(layout);
}
```

#### finalpage.h

```cpp
#ifndef FINAL_PAGE_H
#define FINAL_PAGE_H

#include <QLabel>
#include <QWizardPage>

// FinalPage 继承自 QWizardPage，表示向导中的“完成”页面
class FinalPage : public QWizardPage {
    Q_OBJECT
  public:
    // 构造函数，允许传入父窗口指针，默认 nullptr
    explicit FinalPage(QWidget* parent = nullptr);

    // 重写 QWizardPage 的 initializePage() 方法
    // 每次页面显示时会调用，用于初始化页面内容
    void initializePage() override;

  private:
    QLabel* infoLabel; // 用于显示欢迎信息的标签控件
};

#endif // FINAL_PAGE_H
```

#### finalpage.cpp

```cpp
#include "finalpage.h"
#include <QVBoxLayout>

FinalPage::FinalPage(QWidget* parent) : QWizardPage(parent) {
    setTitle("完成"); // 设置该向导页的标题，显示在向导窗口顶部

    infoLabel = new QLabel; // 创建一个 QLabel 用于显示欢迎信息

    QVBoxLayout* layout = new QVBoxLayout; // 垂直布局管理器，用于安排控件位置
    layout->addWidget(infoLabel);          // 将 QLabel 添加到布局中

    setLayout(layout); // 将布局设置给该页面，使其生效
}

// 重写 QWizardPage 的 initializePage()，每次该页面显示时调用
void FinalPage::initializePage() {
    // 从向导的字段中获取用户输入的用户名，字段名为 "username"
    QString name = field("username").toString();

    // 根据用户名动态设置标签文本，显示欢迎信息
    infoLabel->setText("你好，" + name + "，欢迎使用 QWizard！");
}
```

