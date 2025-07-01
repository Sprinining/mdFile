## QTimer

`QTimer` 是 Qt 框架中提供的一个用于事件驱动定时操作的类，属于 `QObject` 派生类。它常用于定时更新 UI、实现延时处理、周期性任务执行等功能。

### 基本用法

#### 周期性定时器（循环触发）

```cpp
QTimer *timer = new QTimer(this);
connect(timer, &QTimer::timeout, this, &MyClass::onTimeout);
timer->start(1000); // 每隔 1000 毫秒触发一次
```

#### 单次定时器（只触发一次）

```cpp
QTimer::singleShot(3000, this, SLOT(onSingleShotTimeout()));
// 或者使用 lambda（推荐）
QTimer::singleShot(3000, this, []() {
    qDebug() << "3 秒后只执行一次";
});
```

### 常用成员函数

| 方法                    | 说明                 |
| ----------------------- | -------------------- |
| `start(int msec)`       | 启动定时器，单位毫秒 |
| `stop()`                | 停止定时器           |
| `setInterval(int msec)` | 设置时间间隔         |
| `setSingleShot(bool)`   | 设置是否只触发一次   |
| `isActive()`            | 判断是否正在运行     |
| `interval()`            | 返回当前设置的间隔   |
| `isSingleShot()`        | 是否是单次定时器     |

### 工作机制（基于事件循环）

- `QTimer` 是基于 **事件循环** (`QEventLoop`) 的，定时器超时时会生成一个 `QTimerEvent` 放入事件队列。
- Qt 会通过主线程的事件循环检测这些事件，并在时间到了后发送 `timeout()` 信号。
- 所以 **必须在有事件循环的线程中使用**，通常是主线程或 `QThread` 的 `run()` 中手动启动事件循环。

### 示例

#### 每秒更新时间到 QLabel

```cpp
auto *label = new QLabel(this);
auto *timer = new QTimer(this);
connect(timer, &QTimer::timeout, this, [=]() {
    label->setText(QTime::currentTime().toString());
});
timer->start(1000);
```

#### 使用 QTimer 控制动画帧刷新

```cpp
auto *timer = new QTimer(this);
connect(timer, &QTimer::timeout, this, &MyWidget::update); // 调用重绘
timer->start(16); // 约等于 60 FPS
```

### 与多线程配合使用

- 如果在子线程中使用 `QTimer`，需要保证该线程有运行事件循环。
- 不能将一个 `QTimer` 用在它不属于的线程。

正确方式（在线程内创建 QTimer）:

```cpp
class WorkerThread : public QThread {
    void run() override {
        QTimer timer;
        connect(&timer, &QTimer::timeout, []() {
            qDebug() << "子线程定时任务";
        });
        timer.start(1000);
        exec(); // 启动事件循环
    }
};
```

### QTimer 与 QObject 生命周期绑定

- `QTimer` 会跟随 `QObject` 的生命周期自动清理，无需手动 delete。
- `QTimer::singleShot` 不需要手动管理 timer 对象。

### 实战建议

- UI 控制更新建议在主线程中使用 `QTimer`。
- 耗时任务不要放在 `timeout()` 槽中执行，容易阻塞事件循环。
- 多个任务可用多个 `QTimer` 管理，或用一个定时器统一调度。

### 替代方案

| 方案                                                   | 说明                           |
| ------------------------------------------------------ | ------------------------------ |
| `QThread::msleep()`                                    | 阻塞式等待，适用于后台线程     |
| `QElapsedTimer`                                        | 精确计时，测量耗时             |
| `QTimer::singleShot()`                                 | 延时执行一次任务，代替 `sleep` |
| `QMetaObject::invokeMethod()` + `Qt::QueuedConnection` | 实现延时调用                   |

### 动画刷新示例

创建一个小球在窗口中左右移动的动画。

#### MovingBallWidget.h

```cpp
#pragma once

#include <QWidget>
#include <QTimer>

class MovingBallWidget : public QWidget {
    Q_OBJECT

public:
    explicit MovingBallWidget(QWidget *parent = nullptr);

protected:
    void paintEvent(QPaintEvent *event) override;

private:
    QTimer timer_;     // 用于刷新动画的定时器
    int ballX_ = 0;    // 小球的横坐标
    int direction_ = 1; // 移动方向（1：右，-1：左）

private slots:
    void onTimeout(); // 每帧更新
};
```

#### MovingBallWidget.cpp

```cpp
#include "MovingBallWidget.h"
#include <QPainter>

MovingBallWidget::MovingBallWidget(QWidget *parent)
    : QWidget(parent) {
    setFixedSize(400, 200);       // 设置固定窗口大小
    timer_.setInterval(16);       // 约 60FPS
    connect(&timer_, &QTimer::timeout, this, &MovingBallWidget::onTimeout);
    timer_.start();               // 启动定时器
}

void MovingBallWidget::paintEvent(QPaintEvent *) {
    QPainter painter(this);
    painter.setRenderHint(QPainter::Antialiasing);
    painter.setBrush(Qt::blue);
    painter.drawEllipse(ballX_, height() / 2 - 10, 20, 20); // 画小球
}

void MovingBallWidget::onTimeout() {
    // 更新小球位置
    ballX_ += direction_ * 2;
    if (ballX_ < 0 || ballX_ > width() - 20) {
        direction_ *= -1; // 碰到边界换方向
    }
    update(); // 请求重绘
}
```

#### main.cpp

```cpp
#include <QApplication>
#include "MovingBallWidget.h"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    MovingBallWidget w;
    w.show();
    return app.exec();
}
```

### 按钮冷却示例

发送验证码按钮冷却 60 秒。

```cpp
#include <QPushButton>
#include <QTimer>

class CooldownButton : public QPushButton {
    Q_OBJECT

public:
    explicit CooldownButton(QWidget *parent = nullptr)
        : QPushButton("发送验证码", parent) {
        connect(this, &QPushButton::clicked, this, &CooldownButton::startCooldown);

        timer_ = new QTimer(this);
        timer_->setInterval(1000); // 每秒更新一次
        connect(timer_, &QTimer::timeout, this, &CooldownButton::updateCooldown);
    }

private slots:
    void startCooldown() {
        setEnabled(false); // 禁用按钮
        cooldown_ = 60;
        setText(QString("请等待 %1 秒").arg(cooldown_));
        timer_->start();
    }

    void updateCooldown() {
        cooldown_--;
        if (cooldown_ > 0) {
            setText(QString("请等待 %1 秒").arg(cooldown_));
        } else {
            timer_->stop();
            setText("发送验证码");
            setEnabled(true); // 恢复可点击
        }
    }

private:
    QTimer *timer_;
    int cooldown_ = 0;
};
```

```cpp
#include <QApplication>
#include <QWidget>
#include "CooldownButton.h"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    QWidget window;

    auto *btn = new CooldownButton(&window);
    btn->move(50, 50);
    window.resize(200, 150);
    window.show();

    return app.exec();
}
```