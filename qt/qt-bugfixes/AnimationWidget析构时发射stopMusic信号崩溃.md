## AnimationWidget 析构时发射 stopMusic 信号崩溃

`AnimationWidget` 类负责播放图片动画，同时通过信号控制背景音乐的播放、暂停和停止。
在项目中，`AnimationWidget` 的析构函数中直接调用了 `emit stopMusic()`，用于通知音乐停止。

### 问题描述

- **崩溃现象**
   程序退出或销毁 `AnimationWidget` 时，出现断言失败或崩溃，提示信息如下：

  ```css
  ASSERT failure in SlideshowDialog: "Called object is not of the correct type (class destructor may have already run)"
  ```

- **断点提示**

  ```css
  The inferior stopped because it received a signal from the operating system. Signal name: ?, Signal meaning: Unknown signal
  ```

- **导致原因**
  该错误通常由于析构函数中发出的信号连接的槽对象已经被销毁或处于不稳定状态，导致调用非法的内存地址或已销毁对象方法，引发程序崩溃。

### 问题分析

- Qt 信号槽机制依赖于对象的生命周期管理。
- 如果一个对象的析构函数中发信号，而连接该信号的槽对象已提前销毁，则信号发射时会访问非法对象，出现崩溃。
- 析构函数中应避免调用虚函数或发射信号，防止调用链上的其他对象状态不确定。

### 解决方案

#### 1. 禁止在 `AnimationWidget` 析构函数发射信号

将析构函数改为**不发信号**，只做必要清理操作：

```cpp
AnimationWidget::~AnimationWidget() {
    // 不发信号，避免崩溃
}
```

#### 2. 在窗口类（如 `SlideshowDialog`）的关闭事件中统一管理动画停止和音乐停止信号发射

在 `SlideshowDialog` 的 `closeEvent` 中调用 `stopAnimation()` 停止动画，同时发出 `stopMusic()` 信号：

```cpp
void SlideshowDialog::closeEvent(QCloseEvent *event) {
    ui->widgetAnimation->stopAnimation(); // 停止动画，动画内部可发暂停等信号
    emit stopMusic();                      // 由窗口统一控制，明确发出停止音乐信号
    QDialog::closeEvent(event);            // 调用基类默认行为
}
```

`SlideshowDialog::closeEvent` 是在窗口关闭过程中调用的，所有相关的子控件和槽对象都还活着，生命周期完整，信号发出时能保证所有槽对象都正常可用。这样发信号就安全，不会访问已销毁对象。

这样可以保证：

- 发送信号时槽对象仍有效，避免调用已析构对象。
- 统一管理动画与音乐的停止逻辑，清晰且安全。

### 总结

- 避免在析构函数中直接发信号，防止调用已析构的槽对象导致崩溃。
- 由拥有控件的窗口类统一管理动画与音乐资源的停止和信号发射，保证程序稳定。